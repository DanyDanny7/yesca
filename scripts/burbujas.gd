class_name Burbujas
extends Node2D

## Burbujas que nacen en una detonación y suben.
##
## No van dibujadas en el sprite de la onda, y el motivo es el mismo por el que
## la estela de la fugaz tampoco es dibujo: una burbuja pintada en la imagen se
## escalaría con el radio del anillo y se apagaría con él. O sea, ni subiría ni
## sobreviviría — que son las dos únicas cosas que hacen que una burbuja sea una
## burbuja.
##
## Viven más que la onda. Cuando el anillo ya se apagó, la columna sigue subiendo
## y marca dónde pasó la cadena.
##
## Es un nodo aparte y no código dentro de `Explosion` porque el mismo emisor
## sirve para Ducha cambiando el color y la cantidad, y porque las burbujas
## sobreviven a la detonación que las creó: metidas dentro, morirían con ella.

## Cuántas salen por detonación.
@export var cantidad: Vector2i = Vector2i(10, 14)
## Radio de cada una, en píxeles.
@export var radio: Vector2 = Vector2(3.0, 11.0)
## A qué velocidad suben, de la más pequeña a la más grande.
@export var subida: Vector2 = Vector2(42.0, 92.0)
## Cuánto viven, en segundos. Más que la onda, que dura 1.2.
@export var vida: Vector2 = Vector2(0.9, 1.8)
## Amplitud del bamboleo horizontal, en píxeles.
@export var bamboleo: Vector2 = Vector2(3.0, 9.0)
## Tope de burbujas vivas a la vez.
##
## Una cadena de diez eslabones emite hasta 140 en cinco segundos y medio. Sin
## tope, una cascada larga llena la pantalla justo cuando más hay que ver.
@export var maximo: int = 120

## Cuánto crece una burbuja a lo largo de su vida.
##
## Al subir baja la presión y el gas se expande. Es un detalle que nadie nombra
## y que todo el mundo nota si falta.
const CRECIMIENTO := 1.25
## En qué fracción final de su vida se desvanece.
const DESVANECIDO := 0.3
## Dónde nacen, en fracción del radio de la detonación.
##
## Un tercio y no el círculo entero: salen del estallido, no del anillo.
const REPARTO := 0.34

var color_cuerpo := Color("9df0e4")
var color_borde := Color("0a3b44")
var color_brillo := Color("eafdf9")

var _vivas: Array[Dictionary] = []


## Suelta una tanda en el sitio de una detonación.
##
## Todas de golpe, en el instante cero. Bajo el agua el gas sale en el momento
## del estallido y luego solo sube; emitirlas a lo largo de la onda las
## convertiría en un chorro, que es otra cosa.
func emitir(centro: Vector2, radio_onda: float) -> void:
	var cuantas := randi_range(cantidad.x, cantidad.y)
	for i in cuantas:
		var r := randf_range(radio.x, radio.y)
		# La grande sube más rápido. Es cierto en el agua y además se ve: si
		# todas suben igual, la columna se lee como una cortina.
		var t := (r - radio.x) / maxf(0.001, radio.y - radio.x)
		_vivas.append({
			"pos": centro + Vector2.from_angle(randf() * TAU) * radio_onda * REPARTO * sqrt(randf()),
			"base_x": 0.0,
			"r": r,
			"sube": lerpf(subida.x, subida.y, t),
			"vida": randf_range(vida.x, vida.y),
			"t": 0.0,
			"amp": randf_range(bamboleo.x, bamboleo.y),
			"per": randf_range(0.5, 1.1),
			"fase": randf() * TAU,
		})
	for b in _vivas:
		if not b.has("listo"):
			b["base_x"] = b["pos"].x
			b["listo"] = true
	# Al pasar del tope se descartan las MÁS VIEJAS, no las nuevas: la detonación
	# recién ocurrida es la que el jugador está mirando.
	while _vivas.size() > maximo:
		_vivas.remove_at(0)


func actualizar(delta: float) -> void:
	if _vivas.is_empty():
		return
	var quedan: Array[Dictionary] = []
	for b in _vivas:
		b["t"] += delta
		if b["t"] >= b["vida"]:
			continue
		b["pos"].y -= b["sube"] * delta
		# El bamboleo se calcula sobre la x de origen, no acumulando: acumulando,
		# la burbuja derivaría de lado en vez de oscilar sobre su vertical.
		b["pos"].x = b["base_x"] + b["amp"] * sin(TAU * b["t"] / b["per"] + b["fase"])
		quedan.append(b)
	_vivas = quedan
	queue_redraw()


func limpiar() -> void:
	_vivas.clear()
	queue_redraw()


func _draw() -> void:
	for b in _vivas:
		var t: float = b["t"] / b["vida"]
		var r: float = b["r"] * lerpf(1.0, CRECIMIENTO, t)
		var alfa := 1.0
		if t > 1.0 - DESVANECIDO:
			alfa = (1.0 - t) / DESVANECIDO
		var p: Vector2 = b["pos"]
		draw_circle(p, r, Color(color_cuerpo, 0.34 * alfa))
		draw_arc(p, r, 0.0, TAU, 14, Color(color_borde, 0.9 * alfa), 2.2, true)
		# El brillo siempre en la misma esquina: la luz viene de la superficie.
		draw_circle(p + Vector2(-r * 0.34, -r * 0.34), r * 0.28,
				Color(color_brillo, 0.85 * alfa))
