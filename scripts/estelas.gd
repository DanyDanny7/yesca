class_name Estelas
extends Node2D

## Las estelas de los meteoros, todas juntas y por detrás de todos los targets.
##
## Están aquí y no dentro de cada Dot por una razón de juego, no de orden: si
## cada meteoro pintara la suya, la estela de uno taparía a otro y el jugador
## perdería un objetivo por decoración. Dibujándolas todas en una capa que va
## debajo, ninguna puede esconder una roca.
##
## Por delante sí van de la capa de astros y del azulejo: la estela es del mundo
## de los targets, no del fondo.
##
## La maquinaria es la de la estrella fugaz —anillo muestreado por distancia,
## cinta afilada y degradado por vértice— con los números de este bioma.

## Las tres capas: escala del semiancho, color y opacidad de salida.
##
## Tres capas y no un degradado de verdad por lo mismo que en la fugaz: un
## degradado cuesta un shader y esto son tres polígonos.
##
## La exterior arranca en 0,55 y no en 0,80 como la de la fugaz. Allí es el halo
## de una luz; aquí es humo, y un humo tan opaco como el núcleo tapa a los
## meteoros de detrás.
const CAPAS := [
	{"escala": 1.00, "color": "ff6a2c", "alfa": 0.55},
	{"escala": 0.58, "color": "ffa03c", "alfa": 0.78},
	{"escala": 0.30, "color": "fff1cf", "alfa": 0.92},
]

## Los dots cuyas estelas hay que pintar. Los pone Main.
var dots: Array[Dot] = []


## Main llama a esto cada fotograma, después de mover.
func actualizar(lista: Array[Dot]) -> void:
	dots = lista
	queue_redraw()


func _draw() -> void:
	for d in dots:
		if not is_instance_valid(d) or d.modo != Dot.Movimiento.METEORO:
			continue
		_dibujar_una(d)


func _dibujar_una(d: Dot) -> void:
	var anillo := d.anillo_estela()
	if anillo.size() < 3:
		return
	# Mientras el meteoro está entrando, la cinta entra con él: si naciera a su
	# ancho, una estela completa aparecería de golpe junto a una roca a medio
	# crecer.
	var ancho := d.ancho_estela() * d.entrada()
	if ancho <= 0.0:
		return
	for capa in CAPAS:
		_cinta(anillo, ancho * float(capa["escala"]),
				Color(str(capa["color"])), float(capa["alfa"]), d.paso_estela())


## Una cinta afilada a lo largo del anillo, con degradado por vértice.
##
## El degradado va en draw_polygon con un color POR VÉRTICE, nunca en
## draw_colored_polygon: ese es el atajo que arruina el efecto, porque pinta la
## cinta entera de un solo tono y la estela deja de apagarse hacia atrás.
func _cinta(anillo: PackedVector2Array, ancho_max: float, col: Color,
		alfa0: float, paso: float) -> void:
	var n := anillo.size()
	var izq := PackedVector2Array()
	var der := PackedVector2Array()
	var col_izq := PackedColorArray()
	var col_der := PackedColorArray()
	for i in n:
		# u = 0 en la cabeza y 1 en la cola.
		var u := float(i) / float(n - 1)
		var p := anillo[i]
		# El rumbo local sale de los DOS vecinos. Con solo el de atrás, la cinta
		# tiembla en cuanto la trayectoria se curva.
		var antes := anillo[maxi(i - 1, 0)]
		var luego := anillo[mini(i + 1, n - 1)]
		var rumbo := luego - antes
		if rumbo.length_squared() < 0.0001:
			rumbo = Vector2.RIGHT
		# Afilada con hombro: el segundo factor la abre deprisa en el primer 5%
		# para que la cabeza no nazca en punta, y el primero la afila hacia la
		# cola.
		var w := ancho_max * pow(1.0 - u, 0.55) * minf(1.0, pow(u / 0.05, 0.7))
		w = minf(w, _tope_curva(antes, p, luego, paso))
		var normal := rumbo.orthogonal().normalized()
		var c := Color(col, alfa0 * (1.0 - u))
		izq.append(p + normal * w)
		der.append(p - normal * w)
		col_izq.append(c)
		col_der.append(c)
	der.reverse()
	col_der.reverse()
	draw_polygon(izq + der, col_izq + col_der)


## Cuánto puede ensancharse la cinta en una curva sin doblarse sobre sí misma.
##
## En la fugaz esto era prescindible: va en una media luna casi recta y el borde
## interior nunca se cruza. Aquí no hay esa garantía —un meteoro puede llevar
## vaivén o bucle— y sin el tope aparece un pliegue, que es el único artefacto
## visible de todo el sistema.
func _tope_curva(antes: Vector2, p: Vector2, luego: Vector2, paso: float) -> float:
	var a := p - antes
	var b := luego - p
	if a.length_squared() < 0.0001 or b.length_squared() < 0.0001:
		return 1.0e9
	var ang := absf(a.angle_to(b))
	if ang < 0.0001:
		return 1.0e9
	return (paso / (2.0 * sin(ang * 0.5))) * 0.5
