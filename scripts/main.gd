extends Node2D

## Cadena — v3.
##
## Se toca un CÍRCULO, no la pantalla. El círculo tocado explota y su onda
## expansiva contagia a los vecinos, que explotan a su vez. Una barra de tiempo
## baja sola; tocar cuesta tiempo y atrapar lo devuelve.
## Ver contexto/03-concepto-cadena.md
##
## Historial de las correcciones que trajeron el juego hasta aquí:
##
## v0 estaba estructurado por rondas (detonar, resolver, borrar todo, repetir).
## Se sentía un bucle cerrado sin avance, que era justo el defecto que el
## concepto endless existía para evitar.
##
## v1 dejaba detonar en cualquier punto de la pantalla. Eso es una acción
## arbitraria: apuntas a un vacío y esperas. Tocar un círculo concreto es una
## acción con puntería, y hace que el fallo sea legible.
##
## v1 tampoco comunicaba nada: morir no se veía porque cada punto mueve su
## propia posición en su _process y aquí solo se detenía la lógica de partida.
##
## v2 subía la dificultad con una rampa lineal, continua y atada al reloj. Una
## pendiente suave es una pendiente que no se nota: la intensidad se percibe por
## contraste, no por nivel absoluto. Ahora son escalones, y van por PUNTUACIÓN.

# Los parámetros de calibración van como @export para poder moverlos desde el
# inspector con el juego corriendo. Calibrar recompilando es insufrible, y en
# esta fase calibrar ES el trabajo.

@export_group("Campo")
@export var target_dots: int = 25
@export var dot_speed_min: float = 60.0
@export var dot_speed_max: float = 140.0

@export_group("Detonación")
## Radio de la detonación del círculo que tocas, mayor que el de las
## detonaciones en cadena: es el valor de haber apuntado bien.
@export var tap_radius: float = 150.0
## Cuánto se perdona la puntería. Un círculo mide 9 px y se mueve; un dedo tapa
## más de 50. Sin esta tolerancia el juego sería un test de precisión, que no es
## la habilidad que queremos premiar — la que queremos es elegir QUÉ círculo.
@export var tap_tolerance: float = 60.0

## La única economía del juego. De estos números sale toda la tensión: el tap
## descuidado tiene que ser pérdida neta y el tap paciente ganancia neta.
##
## reward_base es deliberadamente bajo y reward_step alto. Al pasar a "tocar un
## círculo" el tap descuidado dejó de poder fallar del todo — siempre revienta
## al menos el círculo que tocas — y con una recompensa plana eso bastaba para
## sobrevivir sin mirar. Cargando el premio en la LONGITUD de la cadena en vez
## de en el número de puntos, la cascada corta se vuelve pérdida neta y solo la
## paciencia paga.
@export_group("Economía de tiempo")
@export var time_start: float = 10.0
@export var time_max: float = 15.0
## Deliberadamente caro. Es la palanca que separa jugar bien de jugar mucho.
##
## Con un tap barato la FRECUENCIA compensa la CALIDAD: como tocar un círculo
## siempre revienta al menos ese círculo, tocar mal muchas veces rinde tanto
## como tocar bien pocas, y la brecha entre ambos perfiles se hunde. Encareciendo
## el tap, la cascada corta deja de pagarse sola y solo la paciencia sobrevive.
@export var tap_cost: float = 2.0
## Lo que cuesta de reloj un tap fallado, aparte de sumar al contador de fallos.
##
## Es la mitad del tap acertado a propósito. Con el coste completo el margen de
## fallos era código muerto: cinco fallos vaciaban la barra de 10 s y siempre
## morías por tiempo antes de que el contador llegara a su límite. Para que el
## medidor de fallos exista de verdad, el castigo principal tiene que ser el
## contador y no el reloj.
@export var miss_cost: float = 1.0
@export var reward_base: float = 0.4
## Extra por cada punto adicional de la MISMA cascada.
@export var reward_step: float = 0.18
## Premio por vaciar la pantalla entera. En un endless no existe "ganar", así
## que esto es lo más parecido que hay y merece celebrarse.
@export var clear_bonus: float = 3.0

## La dificultad sube por ESCALONES, no por rampa, y va atada a la PUNTUACIÓN.
##
## Escalones y no pendiente porque el tramo plano es lo que te deja acomodarte,
## y es esa comodidad la que hace que el siguiente salto se sienta. Sin meseta
## no hay escalón, solo una rampa con ruido.
##
## Por puntuación y no por reloj porque así el que juega bien llega rápido a lo
## difícil, que es lo que quiere, y el que juega mal se queda más tiempo en lo
## fácil, que es lo que necesita. Es ajuste dinámico de dificultad gratis. Y no
## se puede explotar quedándose quieto: sobrevivir exige puntuar.
##
## Se mueven cuatro palancas a la vez en vez de una mucho, porque cada una
## ataca una habilidad distinta: presión (desagüe), escasez (reposición),
## generosidad (radio de cadena) y legibilidad (velocidad).
## Manda el RELOJ; la puntuación es solo un acelerador con umbral alto.
##
## Al principio se hizo al revés y fue un error medido: con los escalones atados
## a la puntuación, la dificultad se vuelve una goma elástica que persigue al
## buen jugador y le tapa el techo, mientras el descuidado granjea el escalón
## más generoso. La separación entre ambos se hundió de 4.8x a 1.4x. En un juego
## que va del marcador, comprimir el rango de puntuaciones es lo peor que puede
## pasar — es buena idea en Tetris porque allí la puntuación SON las líneas,
## aquí no.
@export_group("Escalones")
@export var stage_size: int = 400
## Segundos que también hacen subir de escalón, aunque no puntúes.
##
## Sin esto la dificultad por puntuación es una goma elástica: el que juega bien
## puntúa rápido, sube rápido y se estrella contra el desagüe alto, mientras que
## el descuidado puntúa despacio y se queda granjeando el escalón 1. Medido, la
## separación entre jugar bien y jugar mal se hundió de 4.8x a 1.4x — y para un
## juego que va del marcador, comprimir el rango de puntuaciones es lo peor que
## puede pasar. Con el techo temporal el lento no puede acomodarse, y el bueno
## sigue mandando por puntuación, que es el comportamiento que se buscaba.
@export var stage_seconds: float = 20.0
## Uno de cada tantos escalones no sube la presión: es un respiro. El valle es
## lo que hace que se note el pico.
@export var rest_every: int = 4

@export_subgroup("Presión")
@export var drain_base: float = 0.7
@export var drain_step: float = 0.18

@export_subgroup("Generosidad")
@export var chain_radius_base: float = 105.0
@export var chain_radius_step: float = 3.0
@export var chain_radius_min: float = 75.0

@export_subgroup("Escasez")
@export var respawn_base: float = 0.32
@export var respawn_step: float = 0.03
@export var respawn_max: float = 0.6

@export_subgroup("Legibilidad")
@export var speed_step: float = 8.0

## Fallos SEGUIDOS que se toleran antes de perder, al estilo del medidor de
## Guitar Hero. Un acierto lo pone a cero.
##
## Aviso honesto sobre lo que esto hace y lo que no: como se reinicia al
## acertar, casi nunca se va a disparar con el campo lleno, y por tanto NO es lo
## que frena al que machaca la pantalla — de eso se encargan el coste del tap y
## el multiplicador de cadena. Lo que sí hace es castigar el manotazo a ciegas
## cuando el campo está vacío o los círculos van rápido.
@export_subgroup("Fallos")
@export var fallos_base: int = 5
## Cuántos fallos se pierden de margen por escalón. La cuerda se acorta.
@export var fallos_step: float = 0.4
@export var fallos_min: int = 3

const SPAWN_MARGIN := 40.0
const WARN_TIME := 3.0
const FLASH_TIME := 1.4
const SAVE_PATH := "user://cadena.cfg"
## A qué escalón el color de las detonaciones termina de calentarse.
const STAGE_COLOR_TOPE := 10.0
const COMBO_POP_TIME := 0.45

enum State {
	START,    ## pantalla de inicio, el campo se mueve de fondo
	READY,    ## campo vivo, barra llena, el tiempo aún no corre
	PLAYING,  ## el tiempo baja
	DEAD,     ## pantalla de fin, el mundo congelado
}

@onready var _dots_root: Node2D = $Dots
@onready var _explosions_root: Node2D = $Explosions

@onready var _score_label: Label = $UI/Score
@onready var _best_label: Label = $UI/Best
@onready var _hint_label: Label = $UI/Hint
@onready var _flash_label: Label = $UI/Flash
@onready var _stage_label: Label = $UI/Stage
@onready var _fallos_label: Label = $UI/Fallos
@onready var _combo_label: Label = $UI/Combo
@onready var _bar_bg: ColorRect = $UI/BarBg
@onready var _bar_fill: ColorRect = $UI/BarBg/BarFill

@onready var _start_screen: Control = $UI/StartScreen
@onready var _start_button: CircleButton = $UI/StartScreen/Play
@onready var _start_best: Label = $UI/StartScreen/Best

@onready var _over_screen: Control = $UI/OverScreen
@onready var _over_button: CircleButton = $UI/OverScreen/Retry
@onready var _over_title: Label = $UI/OverScreen/Title
@onready var _over_score: Label = $UI/OverScreen/Score
@onready var _over_detail: Label = $UI/OverScreen/Detail

var _hud: Array[Control] = []
var _dots: Array[Dot] = []
var _explosions: Array[Explosion] = []
## Anillos de tap fallado. Se dibujan igual que una detonación pero no contagian
## nada, y se llevan aparte para que no cuenten como "cascada en curso".
var _effects: Array[Explosion] = []
var _state: State = State.START
var _time_left: float = 0.0
var _score: int = 0
var _best: int = 0
var _elapsed: float = 0.0
## Puntos atrapados por la cascada en curso. Se reinicia cuando no queda
## ninguna detonación viva, y es lo que escala la recompensa.
var _cascade_len: int = 0
var _respawn_timer: float = 0.0
var _field_was_empty: bool = false
var _flash_left: float = 0.0
var _record_nuevo: bool = false
## Último escalón anunciado, para detectar el salto.
var _stage_shown: int = 1
var _fallos: int = 0
var _best_cascade: int = 0
## Va de 1 a 0 y anima el golpe de escala del multiplicador.
var _combo_pop: float = 0.0


func _ready() -> void:
	_hud = [_bar_bg, $UI/BarCaption, _stage_label, _fallos_label, _score_label,
			_best_label, _hint_label, _flash_label, _combo_label]
	_cargar_record()
	_poblar_campo()
	_ir_a_inicio()


func _process(delta: float) -> void:
	_explosions = _prune(_explosions)
	_effects = _prune(_effects)

	if _explosions.is_empty():
		_cascade_len = 0

	if _state == State.PLAYING:
		_elapsed += delta
		_time_left -= delta * _drain_rate()

	if _state != State.DEAD:
		_check_catches()
		_check_cleared()
		_check_stage()
		_refill_field(delta)

	# La muerte solo ocurre con el tablero quieto. Así un último tap desesperado
	# con la barra ya en cero todavía puede salvarte si atrapa algo, y ese
	# rescate es de los momentos que hacen volver a jugar.
	if _state == State.PLAYING and _time_left <= 0.0 and _explosions.is_empty():
		_die()

	_combo_pop = maxf(0.0, _combo_pop - delta / COMBO_POP_TIME)

	if _flash_left > 0.0:
		_flash_left -= delta

	_update_ui()


func _unhandled_input(event: InputEvent) -> void:
	# Solo se escucha táctil: project.godot tiene emulate_touch_from_mouse, así
	# que el clic del editor entra por aquí igual que el dedo en el teléfono.
	if not (event is InputEventScreenTouch and event.pressed):
		return

	match _state:
		State.START:
			if _start_button.contiene(event.position):
				_empezar_partida()
		State.DEAD:
			# Se acepta el botón o cualquier parte de la pantalla: el reinicio
			# instantáneo es lo que sostiene el "una más".
			_empezar_partida()
		State.READY:
			_state = State.PLAYING
			_tap(event.position)
		State.PLAYING:
			_tap(event.position)


# --- Escalones ------------------------------------------------------------

## El escalón actual: manda lo que llegue antes, la puntuación o el reloj.
##
## La puntuación es la vía principal — hace que quien juega bien alcance rápido
## lo difícil, que es lo que quiere, y que quien juega mal se quede más tiempo
## en lo fácil, que es lo que necesita. El reloj es solo el techo que impide
## granjear indefinidamente el escalón más generoso.
func _stage() -> int:
	var por_puntos := floori(float(_score) / float(stage_size)) + 1
	var por_tiempo := floori(_elapsed / stage_seconds) + 1
	return maxi(por_puntos, por_tiempo)


func _es_respiro(s: int) -> bool:
	return rest_every > 0 and s % rest_every == 0


## Cuántas veces ha subido la presión hasta este escalón, descontando respiros.
func _pasos_presion(s: int) -> int:
	if rest_every <= 0:
		return s - 1
	return (s - 1) - floori(float(s) / float(rest_every))


## Segundos de barra que se pierden por segundo real.
func _drain_rate() -> float:
	return drain_base + drain_step * _pasos_presion(_stage())


func _chain_radius() -> float:
	return maxf(chain_radius_min, chain_radius_base - chain_radius_step * (_stage() - 1))


func _respawn_interval() -> float:
	return minf(respawn_max, respawn_base + respawn_step * (_stage() - 1))


func _speed_bonus() -> float:
	return speed_step * (_stage() - 1)


## Las detonaciones se calientan de color con los escalones.
##
## La rampa era invisible: se veía la barra bajar más rápido sin saber por qué.
## El color no cambia nada del balance, solo la percepción — que es la palanca
## más barata que existe para que lo difícil se SIENTA difícil.
## El margen de fallos se acorta con los escalones.
func _fallos_permitidos() -> int:
	return maxi(fallos_min, fallos_base - floori(fallos_step * (_stage() - 1)))


func _stage_color() -> Color:
	var t := clampf(float(_stage() - 1) / STAGE_COLOR_TOPE, 0.0, 1.0)
	return Explosion.COLOR_ACTIVA.lerp(Color("ff2020"), t)


func _check_stage() -> void:
	var s := _stage()
	if s == _stage_shown or _state != State.PLAYING:
		_stage_shown = s
		return
	_stage_shown = s
	if _es_respiro(s):
		_flash("ESCALÓN %d   ·   RESPIRO" % s)
	else:
		_flash("ESCALÓN %d" % s)


# --- Partida --------------------------------------------------------------

## El tap cuesta tiempo ACIERTE O NO. Si no costara al fallar se podría
## machacar la pantalla hasta acertar y la puntería dejaría de ser una decisión.
func _tap(pos: Vector2) -> void:
	var objetivo := _dot_mas_cercano(pos)
	if objetivo == null:
		_time_left -= miss_cost
		_spawn_effect(pos)
		_fallos += 1
		if _fallos >= _fallos_permitidos():
			_die("DEMASIADOS FALLOS")
		else:
			_flash("fallo  %d / %d" % [_fallos, _fallos_permitidos()])
		return

	_time_left -= tap_cost
	_fallos = 0
	var donde := objetivo.position
	_dots.erase(objetivo)
	objetivo.queue_free()
	_cobrar_punto()
	_spawn_explosion(donde, tap_radius)


## El círculo más cercano al dedo dentro de la tolerancia, o null si no hay.
func _dot_mas_cercano(pos: Vector2) -> Dot:
	var mejor: Dot = null
	var mejor_dist := tap_tolerance
	for d in _dots:
		var dist := d.position.distance_to(pos)
		if dist <= mejor_dist:
			mejor_dist = dist
			mejor = d
	return mejor


## El punto N de una cascada vale N, no 1.
##
## Es lo que convierte el objetivo en ENCADENAR en vez de en pulsar. Una cadena
## de 8 da 1+2+..+8 = 36 puntos, contra los 8 que darían ocho taps sueltos: 4.5x
## por la misma cantidad de círculos reventados. Con puntuación plana la
## frecuencia compensaba la calidad y tocar mal mucho rendía como tocar bien
## poco; con el multiplicador, no hay forma de igualar la paciencia a base de
## volumen. De paso frena el ritmo, que era el otro objetivo: compensa pensar
## qué círculo tocar.
func _cobrar_punto() -> void:
	_cascade_len += 1
	_score += _cascade_len
	_best_cascade = maxi(_best_cascade, _cascade_len)
	_time_left = minf(time_max, _time_left + reward_base + reward_step * (_cascade_len - 1))
	if _cascade_len >= 2:
		_combo_pop = 1.0


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
		_cobrar_punto()
		_spawn_explosion(pos, _chain_radius())


## Vaciar la pantalla entera es lo más parecido a ganar que tiene un endless.
## Antes no producía absolutamente nada y el jugador se quedaba mirando un campo
## vacío sin saber si había hecho algo bien.
func _check_cleared() -> void:
	var vacio := _dots.is_empty()
	if vacio and not _field_was_empty and _state == State.PLAYING:
		_time_left = minf(time_max, _time_left + clear_bonus)
		_flash("PANTALLA LIMPIA   +%d s" % int(clear_bonus))
	_field_was_empty = vacio


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
	_respawn_timer = _respawn_interval()

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
	var bonus := _speed_bonus()
	var rapidez := randf_range(dot_speed_min + bonus, dot_speed_max + bonus)
	d.velocity = (objetivo - d.position).normalized() * rapidez

	_dots_root.add_child(d)
	_dots.append(d)


func _spawn_explosion(pos: Vector2, radius: float) -> void:
	var e := Explosion.new()
	e.position = pos
	e.max_radius = radius
	e.color = _stage_color()
	_explosions_root.add_child(e)
	_explosions.append(e)


func _spawn_effect(pos: Vector2) -> void:
	var e := Explosion.new()
	e.position = pos
	e.max_radius = tap_tolerance
	e.color = Explosion.COLOR_FALLO
	e.hold_time = 0.1
	_explosions_root.add_child(e)
	_effects.append(e)


func _prune(lista: Array[Explosion]) -> Array[Explosion]:
	var alive: Array[Explosion] = []
	for e in lista:
		if e.finished:
			e.queue_free()
		else:
			alive.append(e)
	return alive


func _flash(texto: String) -> void:
	_flash_label.text = texto
	_flash_left = FLASH_TIME


## Al morir se congela el mundo entero.
##
## Antes solo se detenía la lógica de partida, pero cada punto mueve su propia
## posición en su _process, así que seguían rebotando y la muerte era
## literalmente invisible: el juego "continuaba".
func _die(motivo: String = "SE ACABÓ EL TIEMPO") -> void:
	_over_title.text = motivo
	_state = State.DEAD
	_dots_root.process_mode = Node.PROCESS_MODE_DISABLED
	_record_nuevo = _score > _best
	if _record_nuevo:
		_best = _score
		_guardar_record()
	_over_screen.visible = true
	_set_hud_visible(false)


func _ir_a_inicio() -> void:
	_state = State.START
	_start_screen.visible = true
	_over_screen.visible = false
	_set_hud_visible(false)


func _empezar_partida() -> void:
	_poblar_campo()
	_start_screen.visible = false
	_over_screen.visible = false
	_set_hud_visible(true)
	_state = State.READY
	_time_left = time_start
	_score = 0
	_elapsed = 0.0
	_cascade_len = 0
	_stage_shown = 1
	_fallos = 0
	_best_cascade = 0
	_combo_pop = 0.0
	_respawn_timer = _respawn_interval()
	_field_was_empty = false
	_flash_left = 0.0


func _poblar_campo() -> void:
	_dots_root.process_mode = Node.PROCESS_MODE_INHERIT

	for d in _dots:
		d.queue_free()
	_dots.clear()
	for e in _explosions:
		e.queue_free()
	_explosions.clear()
	for e in _effects:
		e.queue_free()
	_effects.clear()

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


func _set_hud_visible(v: bool) -> void:
	for nodo in _hud:
		nodo.visible = v


func _cargar_record() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		_best = int(cfg.get_value("progreso", "mejor", 0))


func _guardar_record() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progreso", "mejor", _best)
	cfg.save(SAVE_PATH)


func _update_ui() -> void:
	_score_label.text = str(_score)
	_best_label.text = "mejor  %d" % _best
	_start_best.text = "mejor  %d" % _best
	_hint_label.visible = _state == State.READY

	var s := _stage()
	_stage_label.text = "escalón %d%s" % [s, "  ·  respiro" if _es_respiro(s) else ""]
	_fallos_label.text = "fallos  %d / %d" % [_fallos, _fallos_permitidos()]
	_fallos_label.modulate = Color("ff5470") if _fallos > 0 else Color(0.45, 0.45, 0.55)

	# El multiplicador solo existe mientras la cascada está viva.
	if _cascade_len >= 2:
		_combo_label.text = "×%d" % _cascade_len
		_combo_label.modulate.a = 1.0
	else:
		_combo_label.modulate.a = maxf(0.0, _combo_label.modulate.a - 0.06)
	# El golpe de escala es lo que da la sensación de que algo se acumula.
	_combo_label.pivot_offset = _combo_label.size * 0.5
	var golpe := 1.0 + 0.45 * _combo_pop * _combo_pop
	_combo_label.scale = Vector2(golpe, golpe)

	var frac := clampf(_time_left / time_max, 0.0, 1.0)
	_bar_fill.size = Vector2(_bar_bg.size.x * frac, _bar_bg.size.y)
	# El aviso tiene que llegar mientras todavía hay algo que hacer, no cuando
	# ya está perdido.
	_bar_fill.color = Color("ff5470") if _time_left < WARN_TIME else Color("6de3a0")

	_flash_label.modulate.a = clampf(_flash_left / (FLASH_TIME * 0.5), 0.0, 1.0)

	if _state == State.DEAD:
		_over_score.text = str(_score)
		var m := int(_elapsed) / 60
		var seg := int(_elapsed) % 60
		if _record_nuevo:
			_over_detail.text = "¡NUEVO RÉCORD!\nescalón %d  ·  aguantaste %d:%02d" % [s, m, seg]
		else:
			_over_detail.text = "mejor  %d\nescalón %d  ·  aguantaste %d:%02d" % [_best, s, m, seg]
