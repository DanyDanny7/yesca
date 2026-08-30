extends Node2D

## Prototipo v0 — Cadena.
##
## Aquí se evalúa UNA sola cosa: si la reacción en cadena se siente bien al
## tacto. No hay barra de tiempo, ni récord persistente, ni derrota — eso es v1.
## Si esta pantalla no da ganas de volver a tocar, el concepto se cae y no vale
## la pena seguir. Ver contexto/03-concepto-cadena.md

# Los parámetros de calibración van como @export para poder moverlos desde el
# inspector con el juego corriendo. Calibrar recompilando es insufrible, y en
# esta fase calibrar ES el trabajo.

@export var dot_count: int = 25
@export var dot_speed_min: float = 60.0
@export var dot_speed_max: float = 140.0

const RESET_DELAY := 0.9
const SPAWN_MARGIN := 40.0

## Radio de la detonación del JUGADOR, deliberadamente mayor que el de las
## detonaciones en cadena.
##
## Sin esta asimetría el juego se siente muerto: en 720x1280 con 25 puntos, un
## radio de 90 cubre el 2.8% de la pantalla y el tap inicial atrapa ~1.3 puntos
## de media, así que la mayoría de partidas arrancan con 0 o 1 y no encadena
## nada. Subir la densidad en su lugar tendría el efecto contrario — la
## distancia media entre puntos vecinos (~96 px con 25 puntos) quedaría por
## debajo del radio de cadena y todo se propagaría solo, sin mérito.
##
## Con la asimetría, el primer tap casi siempre produce algo y la propagación
## sigue dependiendo de que el jugador haya encontrado densidad real.
@export var tap_radius: float = 150.0
@export var chain_radius: float = 90.0

enum State {
	WAITING,   ## campo lleno, esperando el tap
	CHAINING,  ## hay detonaciones vivas, el input está bloqueado
	ENDED,     ## se apagó todo, esperando a repoblar
}

@onready var _dots_root: Node2D = $Dots
@onready var _explosions_root: Node2D = $Explosions
@onready var _chain_label: Label = $UI/Chain
@onready var _hint_label: Label = $UI/Hint

var _dots: Array[Dot] = []
var _explosions: Array[Explosion] = []
var _state: State = State.WAITING
var _chain: int = 0
var _best: int = 0


func _ready() -> void:
	_reset_field()


func _process(_delta: float) -> void:
	_prune_explosions()
	_check_catches()

	if _state == State.CHAINING and _explosions.is_empty():
		_end_round()


func _unhandled_input(event: InputEvent) -> void:
	if _state != State.WAITING:
		return
	# Solo se escucha táctil: project.godot tiene emulate_touch_from_mouse, así
	# que el clic del editor entra por aquí igual que el dedo en el teléfono.
	if event is InputEventScreenTouch and event.pressed:
		_state = State.CHAINING
		_spawn_explosion(event.position, tap_radius)
		_update_ui()


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
			_chain += 1
		else:
			survivors.append(d)

	_dots = survivors

	# Se difiere el spawn: añadir a _explosions mientras se itera sobre él haría
	# que un punto se contagie de su propia detonación en el mismo frame.
	for pos in caught_at:
		_spawn_explosion(pos, chain_radius)

	if not caught_at.is_empty():
		_update_ui()


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


func _end_round() -> void:
	_state = State.ENDED
	_best = maxi(_best, _chain)
	_update_ui()
	await get_tree().create_timer(RESET_DELAY).timeout
	_reset_field()


func _reset_field() -> void:
	for d in _dots:
		d.queue_free()
	_dots.clear()
	for e in _explosions:
		e.queue_free()
	_explosions.clear()

	var rect := get_viewport_rect()
	for i in dot_count:
		var d := Dot.new()
		d.position = Vector2(
			randf_range(SPAWN_MARGIN, rect.size.x - SPAWN_MARGIN),
			randf_range(SPAWN_MARGIN, rect.size.y - SPAWN_MARGIN))
		d.velocity = Vector2.from_angle(randf() * TAU) * randf_range(dot_speed_min, dot_speed_max)
		_dots_root.add_child(d)
		_dots.append(d)

	_chain = 0
	_state = State.WAITING
	_update_ui()


func _update_ui() -> void:
	_chain_label.text = str(_chain)
	match _state:
		State.WAITING:
			_hint_label.text = "toca para detonar   ·   mejor: %d" % _best
		State.CHAINING:
			_hint_label.text = "%d de %d" % [_chain, dot_count]
		State.ENDED:
			_hint_label.text = "%d de %d   ·   mejor: %d" % [_chain, dot_count, _best]
