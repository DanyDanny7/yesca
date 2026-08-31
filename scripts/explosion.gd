class_name Explosion
extends Node2D

## Una detonación: crece, se sostiene y se apaga.
##
## La fase de "sostiene" es la que hace posible la cadena — es la ventana en la
## que un punto puede entrar y contagiarse. Acortarla vuelve el juego mucho más
## exigente; es de los primeros parámetros a tocar al calibrar.
##
## También se usa, con otro color y sin registrarse en la lista de detonaciones
## activas, como marca de tap fallado: se ve igual pero no contagia nada.

const COLOR_ACTIVA := Color("ff5470")
const COLOR_FALLO := Color("6a6a7a")
## Esquirlas que salen despedidas. Se dibujan dentro de la propia detonación en
## vez de como nodos aparte: son siete círculos, no merecen un sistema de
## partículas ni la basura de nodos que traería en cada eslabón de una cascada.
const ESQUIRLAS := 7

@export var max_radius: float = 90.0
@export var grow_time: float = 0.3
@export var hold_time: float = 0.6
@export var decay_time: float = 0.3
@export var color: Color = COLOR_ACTIVA

## A qué cadena pertenece esta detonación.
##
## Varias cadenas pueden estar vivas a la vez: cada tap arranca la suya y se
## propaga por su cuenta, con su propio multiplicador. Sin este identificador
## todas compartirían contador y encadenar en dos sitios a la vez daría lo
## mismo que hacerlo en uno.
var chain_id: int = 0
## Radio actual. Main lo lee para detectar contagios.
var radius: float = 0.0
## Main es el dueño del ciclo de vida y la libera cuando esto se pone en true.
var finished: bool = false

var _t: float = 0.0
## Desfase propio: sin esto todas las detonaciones lanzarían las esquirlas en
## los mismos ángulos y la pantalla se vería como un patrón repetido.
var _semilla: float = 0.0


func _ready() -> void:
	_semilla = randf() * TAU


func _process(delta: float) -> void:
	_t += delta

	if _t >= grow_time + hold_time + decay_time:
		finished = true
		radius = 0.0
		return

	if _t < grow_time:
		# Ease-out cúbico: sale disparada y frena al final. Ese frenazo es lo
		# que se lee como impacto. Con crecimiento lineal se siente muerta.
		var k := _t / grow_time
		radius = max_radius * (1.0 - pow(1.0 - k, 3.0))
	else:
		radius = max_radius

	queue_redraw()


func _draw() -> void:
	var fade := 1.0
	if _t > grow_time + hold_time:
		fade = 1.0 - (_t - grow_time - hold_time) / decay_time
	fade = clampf(fade, 0.0, 1.0)

	draw_circle(Vector2.ZERO, radius, Color(color, 0.16 * fade))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, Color(color, fade), 3.0, true)

	# Las esquirlas adelantan al anillo y se encogen: dan la lectura de que algo
	# ha salido despedido, no solo de que un círculo ha crecido.
	var avance := radius * (1.0 + 0.28 * (_t / (grow_time + hold_time + decay_time)))
	for i in ESQUIRLAS:
		var ang := _semilla + TAU * float(i) / float(ESQUIRLAS)
		draw_circle(Vector2.from_angle(ang) * avance, 3.5 * fade, Color(color, fade * 0.9))
