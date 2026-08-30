extends Node2D

## Cadena — v1.
##
## Campo continuo: los puntos entran desde los bordes sin parar y el tablero
## nunca se borra. Una barra de tiempo baja sola; tocar cuesta tiempo y atrapar
## lo devuelve. Ver contexto/03-concepto-cadena.md
##
## v0 estaba estructurado por rondas (detonar, resolver, borrar todo, repetir).
## Se sentía un bucle cerrado sin avance, que era exactamente el defecto que el
## concepto endless existía para evitar.

# Los parámetros de calibración van como @export para poder moverlos desde el
# inspector con el juego corriendo. Calibrar recompilando es insufrible, y en
# esta fase calibrar ES el trabajo.

@export_group("Campo")
@export var target_dots: int = 25
@export var dot_speed_min: float = 60.0
@export var dot_speed_max: float = 140.0
@export var respawn_interval: float = 0.4

## Radio de la detonación del JUGADOR, deliberadamente mayor que el de las
## detonaciones en cadena.
##
## Sin esta asimetría el juego se siente muerto: con radio único de 90 el tap
## inicial atrapa ~1.3 puntos de media y la mayoría de taps no encadenan nada.
## Subir la densidad lo invierte — la distancia media entre vecinos cae por
## debajo del radio de cadena y todo se propaga solo, sin mérito.
## Medido en contexto/04-calibracion-v0.md.
@export_group("Detonación")
@export var tap_radius: float = 150.0
@export var chain_radius: float = 90.0

## La única economía del juego. De estos cinco números sale toda la tensión: el
## tap descuidado tiene que ser pérdida neta y el tap bueno ganancia neta. Con
## las medias medidas (4.4 al azar, 7.6 jugando bien) estos valores dejan el
## juego descuidado apenas por debajo del equilibrio y el bueno claramente por
## encima.
@export_group("Economía de tiempo")
@export var time_start: float = 10.0
@export var time_max: float = 15.0
@export var tap_cost: float = 1.5
@export var reward_base: float = 0.6
## Extra por cada punto adicional de la MISMA cascada. Es lo que hace que
## esperar a que se junten más valga la pena en vez de tocar a cada rato.
@export var reward_step: float = 0.12

@export_group("Dificultad")
## Velocidad que ganan los puntos nuevos por cada minuto de partida.
@export var speed_ramp_per_min: float = 40.0
## Cuánto se acelera el desagüe de la barra por cada minuto de partida.
##
## Es la rampa que de verdad importa. Subir solo la velocidad de los puntos no
## amenaza a nadie: no toca la economía, y un jugador competente que espera
## clusters saca ~7.5 s por cada 1.5 s que gasta. Con ese 4x de retorno la
## barra nunca lo alcanza y la partida no termina jamás — medido, 4 minutos sin
## una sola muerte. La dificultad tiene que atacar la economía.
@export var drain_ramp_per_min: float = 0.5

const SPAWN_MARGIN := 40.0
const WARN_TIME := 3.0

enum State {
	READY,    ## campo vivo, barra llena, el tiempo aún no corre
	PLAYING,  ## el tiempo baja
	DEAD,     ## esperando el tap que reinicia
}

@onready var _dots_root: Node2D = $Dots
@onready var _explosions_root: Node2D = $Explosions
@onready var _score_label: Label = $UI/Score
@onready var _best_label: Label = $UI/Best
@onready var _message_label: Label = $UI/Message
@onready var _bar_bg: ColorRect = $UI/BarBg
@onready var _bar_fill: ColorRect = $UI/BarBg/BarFill

var _dots: Array[Dot] = []
var _explosions: Array[Explosion] = []
var _state: State = State.READY
var _time_left: float = 0.0
var _score: int = 0
var _best: int = 0
var _elapsed: float = 0.0
## Puntos atrapados por la cascada en curso. Se reinicia cuando no queda
## ninguna detonación viva, y es lo que escala la recompensa.
var _cascade_len: int = 0
var _respawn_timer: float = 0.0


func _ready() -> void:
	_start_run()


func _process(delta: float) -> void:
	_prune_explosions()

	if _explosions.is_empty():
		_cascade_len = 0

	if _state == State.PLAYING:
		_elapsed += delta
		_time_left -= delta * _drain_rate()

	if _state != State.DEAD:
		_check_catches()
		_refill_field(delta)

	# La muerte solo ocurre con el tablero quieto. Así un último tap desesperado
	# con la barra ya en cero todavía puede salvarte si atrapa algo, y ese
	# rescate es de los momentos que hacen volver a jugar.
	if _state == State.PLAYING and _time_left <= 0.0 and _explosions.is_empty():
		_die()

	_update_ui()


func _unhandled_input(event: InputEvent) -> void:
	# Solo se escucha táctil: project.godot tiene emulate_touch_from_mouse, así
	# que el clic del editor entra por aquí igual que el dedo en el teléfono.
	if not (event is InputEventScreenTouch and event.pressed):
		return

	match _state:
		State.DEAD:
			_start_run()
		State.READY:
			_state = State.PLAYING
			_tap(event.position)
		State.PLAYING:
			_tap(event.position)


## Segundos de barra que se pierden por segundo real. Empieza en 1.0 y sube.
func _drain_rate() -> float:
	return 1.0 + drain_ramp_per_min * (_elapsed / 60.0)


func _tap(pos: Vector2) -> void:
	_time_left -= tap_cost
	_spawn_explosion(pos, tap_radius)


## Detección de contagios por distancia, no con Area2D.
##
## Con ~25 puntos esto es trivial en coste y, sobre todo, es determinista y se
## lee de un vistazo. La física traería capas, máscaras y un frame de retraso
## sin aportar nada a esta escala.
func _check_catches() -> void:
	var caught_at: Array[Vector2] = []
	var survivors: Array[Dot] = []

	for d in _dots:
		var hit := false
		for e in _explosions:
			if d.position.distance_to(e.position) <= e.radius + d.radius:
				hit = true
				break
		if hit:
			caught_at.append(d.position)
			d.queue_free()
		else:
			survivors.append(d)

	_dots = survivors

	# Se difiere el spawn respecto al bucle de arriba: añadir a _explosions
	# mientras se itera sobre él haría que un punto se contagie de su propia
	# detonación en el mismo frame.
	for pos in caught_at:
		_cascade_len += 1
		_score += 1
		_time_left = minf(time_max, _time_left + reward_base + reward_step * (_cascade_len - 1))
		_spawn_explosion(pos, chain_radius)


## Los puntos entran desde fuera de la pantalla, nunca aparecen en medio.
##
## Un punto que se materializa dentro del campo es injusto de dos maneras: se
## pierde la lectura de trayectorias, que es toda la habilidad del juego, y
## puede nacer dentro de una detonación activa y regalar un contagio.
func _refill_field(delta: float) -> void:
	if _dots.size() >= target_dots:
		return

	_respawn_timer -= delta
	if _respawn_timer > 0.0:
		return
	_respawn_timer = respawn_interval

	var rect := get_viewport_rect().size
	var d := Dot.new()
	var fuera := d.radius * 2.0

	match randi() % 4:
		0: d.position = Vector2(randf() * rect.x, -fuera)
		1: d.position = Vector2(randf() * rect.x, rect.y + fuera)
		2: d.position = Vector2(-fuera, randf() * rect.y)
		_: d.position = Vector2(rect.x + fuera, randf() * rect.y)

	# Apunta al tercio central para que cruce el campo, en vez de rozar el
	# borde y volver a salir sin haber estado nunca en juego.
	var objetivo := Vector2(
		randf_range(rect.x * 0.33, rect.x * 0.67),
		randf_range(rect.y * 0.33, rect.y * 0.67))
	var bonus := speed_ramp_per_min * (_elapsed / 60.0)
	var rapidez := randf_range(dot_speed_min + bonus, dot_speed_max + bonus)
	d.velocity = (objetivo - d.position).normalized() * rapidez

	_dots_root.add_child(d)
	_dots.append(d)


func _spawn_explosion(pos: Vector2, radius: float) -> void:
	var e := Explosion.new()
	e.position = pos
	e.max_radius = radius
	_explosions_root.add_child(e)
	_explosions.append(e)


func _prune_explosions() -> void:
	var alive: Array[Explosion] = []
	for e in _explosions:
		if e.finished:
			e.queue_free()
		else:
			alive.append(e)
	_explosions = alive


func _die() -> void:
	_state = State.DEAD
	_best = maxi(_best, _score)


func _start_run() -> void:
	for d in _dots:
		d.queue_free()
	_dots.clear()
	for e in _explosions:
		e.queue_free()
	_explosions.clear()

	# El campo arranca lleno y repartido; solo las reposiciones entran por los
	# bordes. Verlo llenarse punto a punto sería una espera muerta al empezar.
	var rect := get_viewport_rect().size
	for i in target_dots:
		var d := Dot.new()
		d.position = Vector2(
			randf_range(SPAWN_MARGIN, rect.x - SPAWN_MARGIN),
			randf_range(SPAWN_MARGIN, rect.y - SPAWN_MARGIN))
		d.velocity = Vector2.from_angle(randf() * TAU) * randf_range(dot_speed_min, dot_speed_max)
		_dots_root.add_child(d)
		_dots.append(d)

	_state = State.READY
	_time_left = time_start
	_score = 0
	_elapsed = 0.0
	_cascade_len = 0
	_respawn_timer = respawn_interval


func _update_ui() -> void:
	_score_label.text = str(_score)
	_best_label.text = "mejor  %d" % _best

	var frac := clampf(_time_left / time_max, 0.0, 1.0)
	_bar_fill.size = Vector2(_bar_bg.size.x * frac, _bar_bg.size.y)
	# El aviso tiene que llegar mientras todavía hay algo que hacer, no cuando
	# ya está perdido.
	_bar_fill.color = Color("ff5470") if _time_left < WARN_TIME else Color("6de3a0")

	match _state:
		State.READY:
			_message_label.text = "toca para detonar"
		State.PLAYING:
			_message_label.text = ""
		State.DEAD:
			_message_label.text = "%d puntos\ntoca para reintentar" % _score
