class_name Dot
extends Node2D

## Un círculo del campo.
##
## Se dibuja a sí mismo con _draw(): para formas geométricas no hace falta ni
## sprite ni escena propia, se instancia con Dot.new().
##
## No mueve su posición en un _process propio. Lo hace Main llamando a mover(),
## y por dos motivos: hay modos que necesitan ver a los demás círculos o a las
## detonaciones (choque, enjambre, huida), y con Main al mando el orden de
## actualización es determinista en vez de depender del árbol de nodos.

## Cómo se desplaza el círculo. Es la base de los biomas: un bioma no es una
## paleta, es una regla de movimiento y de interacción con las explosiones.
enum Movimiento {
	REBOTE,     ## línea recta, rebota en los bordes
	ABEJA,      ## tirones, pausas y giros bruscos
	NIEVE,      ## cae despacio con vaivén lateral, y reaparece arriba
	CHOQUE,     ## como rebote, pero también chocan entre ellos
	CORRIENTE,  ## arrastrados por un río, salen por un lado y vuelven por el otro
	ENJAMBRE,   ## se buscan entre sí y forman grumos
	HUIDA,      ## se apartan de las detonaciones activas
	BRASA,      ## suben y se renuevan por abajo
	CIRCUITO,   ## solo en horizontal y vertical, con giros de 90 grados
	PLANEO,     ## viran suave y cabecean, como algo que se deja caer en el aire
	MISIL,      ## aceleran en su rumbo hasta un tope
}

## Qué se dibuja. Un bioma con copos de nieve o abejas se explica solo; con
## círculos hay que explicarlo con un texto.
##
## Todas las formas caben en el mismo radio y se dibujan a mano: a nueve píxeles
## no hay sitio para detalle, así que lo que las distingue es la silueta.
enum Forma { CIRCULO, COPO, ABEJA, HOJA, BOLA, DRON, CHISPA, CHIP, AVION, MISIL,
		PEZ, ESTRELLA }

## Color y tamaño los fija el bioma al nacer el círculo, no una constante: es
## lo que permite que la ventisca se vea de nieve y el panal de miel sin tocar
## una línea de la lógica.
var color: Color = Color("e8e8f0")
var forma: Forma = Forma.CIRCULO
## Número de la bola, del 1 al 15. Cero en el resto de biomas.
var numero: int = 0

## Colores de billar. Ninguno es el negro real de la bola 8: sobre un tapete
## oscuro sería invisible, y la legibilidad manda sobre el realismo.
const COLOR_BOLA := [
	Color("ffd23f"), Color("5b9bff"), Color("ff6060"), Color("c184ff"),
	Color("ff9d54"), Color("4fe39a"), Color("dd8259"), Color("b3bacb"),
]

@export var radius: float = 9.0

var modo: Movimiento = Movimiento.REBOTE
var velocity: Vector2 = Vector2.ZERO
## Rapidez de referencia. Los modos que reorientan el vector (enjambre, huida)
## la usan para no acelerar ni frenar sin querer al cambiar de dirección.
var base_speed: float = 100.0

## Entrada en escena, de 0 a 1.
##
## El círculo se dibuja pequeño y crece hasta su tamaño: se lee como que venía
## de lejos y se acerca. Es puro telégrafo — se puede tocar y contagiar desde el
## primer frame, con su radio completo. Un círculo que parece más pequeño de lo
## que se puede tocar es generoso; al revés sería una trampa.
var _entrada: float = 1.0
## Cuánto más grandes se ven los targets de lo que miden para el juego.
const ESCALA_VISUAL := 1.25
const ENTRADA_DUR := 0.55
const ENTRADA_MIN := 0.28

var _fase: float = 0.0
## Desfase propio, para que dos círculos con el mismo modo no se muevan
## sincronizados como un coro.
var _semilla: float = 0.0
var _giro: float = 0.0
## Cuánto vira por segundo el planeo, hasta el próximo cambio de rumbo.
var _vira: float = 0.0


func _ready() -> void:
	_semilla = randf() * TAU
	_giro = randf_range(0.2, 0.6)


func _draw() -> void:
	# Ojo: _draw() dibuja en espacio LOCAL y lo que cambia es la transform del
	# nodo, así que solo hace falta queue_redraw() mientras el círculo crece.
	# El radio de DIBUJO no es el de lógica.
	#
	# `radius` gobierna los contagios, así que agrandarlo cambiaría el balance
	# del juego entero por un motivo puramente estético. La escala se aplica
	# solo aquí: los targets se ven un 25% más grandes y no encadenan ni un
	# píxel más lejos. El radio de toque es aparte y tampoco se toca.
	var r := radius * ESCALA_VISUAL * lerpf(ENTRADA_MIN, 1.0, _entrada)
	match forma:
		Forma.COPO: _copo(r)
		Forma.ABEJA: _abeja(r)
		Forma.HOJA: _hoja(r)
		Forma.BOLA: _bola(r)
		Forma.DRON: _dron(r)
		Forma.CHISPA: _chispa(r)
		Forma.CHIP: _chip(r)
		Forma.AVION: _avion(r)
		Forma.MISIL: _misil(r)
		Forma.PEZ: _pez(r)
		Forma.ESTRELLA: _estrella(r)
		_: draw_circle(Vector2.ZERO, r, color)


## Seis brazos con ramitas. A este tamaño el detalle real es imposible, pero la
## silueta radial se lee como copo al instante.
func _copo(r: float) -> void:
	var grueso := maxf(1.4, r * 0.2)
	var fino := maxf(1.0, r * 0.13)
	for i in 6:
		var dir := Vector2.from_angle(TAU * float(i) / 6.0)
		draw_line(-dir * r * 0.12, dir * r, color, grueso, true)
		var nudo := dir * r * 0.58
		draw_line(nudo, nudo + Vector2.from_angle(dir.angle() + 0.95) * r * 0.36, color, fino, true)
		draw_line(nudo, nudo + Vector2.from_angle(dir.angle() - 0.95) * r * 0.36, color, fino, true)


## Abeja: cuerpo ovalado con franjas, dos alas y aguijón. Mira hacia donde vuela.
##
## Las alas van DETRÁS del cuerpo y translúcidas, batiendo con la fase propia del
## círculo: es lo que la separa de una pelota a rayas. El aguijón asoma por la
## cola y remata la silueta.
func _abeja(r: float) -> void:
	var bat := 0.55 + 0.45 * absf(sin(_fase * 26.0 + _semilla))
	var ala := Color(1.0, 1.0, 1.0, 0.42)
	# Ala trasera y delantera, abiertas hacia arriba y hacia atrás.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-r * 0.1, -r * 0.25),
		Vector2(-r * 1.0, -r * (0.35 + 0.75 * bat)),
		Vector2(-r * 0.15, -r * 0.9)]), ala)
	draw_colored_polygon(PackedVector2Array([
		Vector2(r * 0.15, -r * 0.25),
		Vector2(r * 0.75, -r * (0.3 + 0.7 * bat)),
		Vector2(-r * 0.05, -r * 0.85)]), ala)

	# Aguijón: triangulito en la cola.
	var oscuro := Color(0.09, 0.06, 0.02, 0.95)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-r * 1.45, 0.0),
		Vector2(-r * 0.95, r * 0.16),
		Vector2(-r * 0.95, -r * 0.16)]), oscuro)

	# Cuerpo ovalado apuntando a +x.
	var cuerpo := PackedVector2Array()
	var n := 14
	for i in n:
		var a := TAU * float(i) / float(n)
		cuerpo.append(Vector2(cos(a) * r * 1.05, sin(a) * r * 0.72))
	draw_colored_polygon(cuerpo, color)

	# Franjas perpendiculares al vuelo, más cortas hacia la cola.
	for k in 3:
		var x := -r * 0.55 + float(k) * r * 0.5
		var alto := r * 0.66 * sqrt(maxf(0.0, 1.0 - pow(x / (r * 1.05), 2.0)))
		draw_line(Vector2(x, -alto), Vector2(x, alto), oscuro, maxf(1.2, r * 0.24))

	# Cabeza.
	draw_circle(Vector2(r * 0.85, 0.0), r * 0.34, oscuro)


## Óvalo apuntado con nervadura. La forma sale de un seno, así que es simétrica
## y puntiaguda en los dos extremos sin tener que listar vértices a mano.
func _hoja(r: float) -> void:
	var pts := PackedVector2Array()
	var n := 9
	for i in n + 1:
		var t := float(i) / float(n)
		pts.append(Vector2(r * 0.64 * sin(PI * t), lerpf(-r, r, t)))
	for i in range(n, -1, -1):
		var t := float(i) / float(n)
		pts.append(Vector2(-r * 0.64 * sin(PI * t), lerpf(-r, r, t)))
	draw_colored_polygon(pts, color)
	draw_line(Vector2(0, -r * 0.9), Vector2(0, r * 0.9), Color(0, 0, 0, 0.3), maxf(1.0, r * 0.15), true)


## Bola de billar: lisa o a rayas, con su número y su brillo.
##
## El círculo blanco del centro no es decoración: es lo que garantiza que la
## bola se vea sobre el tapete pase lo que pase con el color del cuerpo. Sin él,
## las oscuras se perderían en el paño verde.
func _bola(r: float) -> void:
	if numero <= 0:
		draw_circle(Vector2.ZERO, r, color)
		draw_circle(Vector2(-r * 0.32, -r * 0.32), r * 0.26, Color(1.0, 1.0, 1.0, 0.5))
		return

	var tinte: Color = COLOR_BOLA[(numero - 1) % COLOR_BOLA.size()]
	var rayada := numero > 8

	if rayada:
		# A rayas: cuerpo claro con una franja de color por el ecuador.
		draw_circle(Vector2.ZERO, r, Color("f2ede0"))
		draw_colored_polygon(_franja(r, r * 0.62), tinte)
	else:
		draw_circle(Vector2.ZERO, r, tinte)

	# Disco blanco y número encima.
	draw_circle(Vector2.ZERO, r * 0.56, Color("fbf7ee"))
	var fuente := ThemeDB.fallback_font
	if fuente != null:
		var tam := int(maxf(8.0, r * 1.05))
		draw_string(fuente, Vector2(-r, r * 0.36), str(numero),
				HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, tam, Color(0.08, 0.08, 0.1))

	draw_circle(Vector2(-r * 0.4, -r * 0.42), r * 0.2, Color(1.0, 1.0, 1.0, 0.45))


## Franja horizontal recortada al círculo, para las bolas a rayas. Se calcula
## con la ecuación del círculo en vez de dibujar un rectángulo, que se saldría
## por los lados.
func _franja(r: float, alto: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var n := 8
	for i in n + 1:
		var y := lerpf(-alto, alto, float(i) / float(n))
		pts.append(Vector2(sqrt(maxf(0.0, r * r - y * y)), y))
	for i in range(n, -1, -1):
		var y := lerpf(-alto, alto, float(i) / float(n))
		pts.append(Vector2(-sqrt(maxf(0.0, r * r - y * y)), y))
	return pts


## Triángulo orientado al rumbo. Mirar hacia donde va delata su trayectoria
## antes de moverse, que es lo que hace legible un bioma que huye.
func _dron(r: float) -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(r * 1.15, 0.0), Vector2(-r * 0.7, r * 0.72), Vector2(-r * 0.7, -r * 0.72)]), color)


## Pavesa: núcleo pequeño y halo. El halo hace que parezca que emite luz sin
## necesidad de ningún efecto.
func _chispa(r: float) -> void:
	draw_circle(Vector2.ZERO, r * 1.4, Color(color, 0.18))
	draw_circle(Vector2.ZERO, r * 0.72, color)


## Rombo con una traza. Geometría dura, que es lo que distingue lo fabricado de
## lo orgánico de un vistazo.
func _chip(r: float) -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, -r), Vector2(r, 0.0), Vector2(0.0, r), Vector2(-r, 0.0)]), color)
	draw_line(Vector2(-r * 0.55, 0.0), Vector2(r * 0.55, 0.0), Color(0, 0, 0, 0.35), maxf(1.0, r * 0.18))


## Arranca la entrada en escena. Los del reparto inicial no la usan: ver el
## campo materializarse al empezar la partida sería una espera muerta.
func entrar_creciendo() -> void:
	_entrada = 0.0
	queue_redraw()


## Todo movimiento va multiplicado por delta. Si no, el juego corre a distinta
## velocidad en cada dispositivo según sus FPS.
func mover(delta: float, rect: Vector2) -> void:
	_fase += delta
	if _entrada < 1.0:
		_entrada = minf(1.0, _entrada + delta / ENTRADA_DUR)
		queue_redraw()
	elif forma in [Forma.ABEJA, Forma.PEZ, Forma.ESTRELLA]:
		# Estas tres se mueven por dentro —alas, cola, titileo— así que hay que
		# redibujarlas aunque el nodo no cambie de sitio.
		queue_redraw()

	# Las formas con orientación la actualizan aquí: el dron mira hacia donde
	# va, la hoja voltea despacio como si cayera.
	if forma in [Forma.DRON, Forma.AVION, Forma.MISIL, Forma.ABEJA, Forma.PEZ] \
			and velocity.length_squared() > 1.0:
		rotation = velocity.angle()
	elif forma == Forma.HOJA:
		rotation += delta * 0.9
	match modo:
		Movimiento.ABEJA:
			_mover_abeja(delta, rect)
		Movimiento.NIEVE:
			_mover_nieve(delta, rect)
		Movimiento.CORRIENTE:
			_mover_corriente(delta, rect)
		Movimiento.BRASA:
			_mover_brasa(delta, rect)
		Movimiento.CIRCUITO:
			_mover_circuito(delta, rect)
		Movimiento.PLANEO:
			_mover_planeo(delta, rect)
		Movimiento.MISIL:
			_mover_misil(delta, rect)
		_:
			# REBOTE, CHOQUE, ENJAMBRE y HUIDA comparten integración recta; lo
			# que los distingue lo aplica Main antes de llamar aquí.
			position += velocity * delta
			_rebotar(rect)


## Tirones y pausas: la abeja mantiene un rumbo un instante, lo cambia de golpe
## y varía mucho de rapidez. Lo que la hace difícil de leer no es la velocidad
## media sino lo poco que dura cada tramo recto.
func _mover_abeja(delta: float, rect: Vector2) -> void:
	_giro -= delta
	if _giro <= 0.0:
		_giro = randf_range(0.15, 0.5)
		var rumbo := velocity.angle() + randf_range(-1.2, 1.2)
		velocity = Vector2.from_angle(rumbo) * base_speed * randf_range(0.35, 1.7)
	position += velocity * delta
	_rebotar(rect)


## Caída lenta con vaivén. No rebota: sale por abajo y vuelve a entrar por
## arriba en otra columna, así el campo se renueva sin saltos.
func _mover_nieve(delta: float, rect: Vector2) -> void:
	var vaiven := sin(_fase * 1.7 + _semilla) * base_speed * 0.75
	position += Vector2(vaiven, base_speed * 0.55) * delta

	if position.y > rect.y + radius:
		position = Vector2(randf() * rect.x, -radius)
	if position.x < -radius:
		position.x = rect.x + radius
	elif position.x > rect.x + radius:
		position.x = -radius


## Río: todos arrastrados en la misma dirección, con una ondulación suave.
## Salen por un lado y reaparecen por el otro.
##
## El sentido lo fija quien crea el círculo, no el rumbo hacia el centro: antes
## los que entraban por la derecha iban hacia la izquierda y los de la izquierda
## hacia la derecha, así que el "río" corría en dos sentidos a la vez y la pista
## del nivel mentía.
func _mover_corriente(delta: float, rect: Vector2) -> void:
	var onda := cos(_fase * 1.1 + _semilla) * base_speed * 0.35
	position += Vector2(velocity.x, onda) * delta

	if position.x < -radius:
		position.x = rect.x + radius
	elif position.x > rect.x + radius:
		position.x = -radius
	position.y = clampf(position.y, radius, rect.y - radius)


## Avión de papel: delta con muesca trasera y pliegue central. La muesca es lo
## que lo separa de un triángulo cualquiera y lo hace leer como papel doblado.
func _avion(r: float) -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(r * 1.25, 0.0),
		Vector2(-r * 0.85, r * 0.8),
		Vector2(-r * 0.3, 0.0),
		Vector2(-r * 0.85, -r * 0.8)]), color)
	draw_line(Vector2(-r * 0.3, 0.0), Vector2(r * 1.2, 0.0),
			Color(0, 0, 0, 0.25), maxf(1.0, r * 0.14), true)


## Misil: cuerpo alargado, punta y aletas. Lo alargado ya dice que va rápido,
## incluso quieto.
func _misil(r: float) -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(r * 1.35, 0.0),
		Vector2(r * 0.45, r * 0.38),
		Vector2(-r * 0.95, r * 0.38),
		Vector2(-r * 0.95, -r * 0.38),
		Vector2(r * 0.45, -r * 0.38)]), color)
	var aleta := Color(color, 0.75)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-r * 0.6, r * 0.35), Vector2(-r * 1.25, r * 0.95),
		Vector2(-r * 0.95, r * 0.35)]), aleta)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-r * 0.6, -r * 0.35), Vector2(-r * 1.25, -r * 0.95),
		Vector2(-r * 0.95, -r * 0.35)]), aleta)


## Pez: cuerpo de almendra y cola en triángulo. Mira hacia donde nada.
##
## La cola es lo que lo hace legible: sin ella, a este tamaño, un cuerpo ovalado
## es indistinguible de un círculo.
func _pez(r: float) -> void:
	var cuerpo := PackedVector2Array()
	var n := 16
	for i in n:
		var a := TAU * float(i) / float(n)
		cuerpo.append(Vector2(cos(a) * r * 1.05, sin(a) * r * 0.6))
	draw_colored_polygon(cuerpo, color)

	# Cola: triangulito detrás, batiendo suave.
	var bat := sin(_fase * 6.0 + _semilla) * 0.3
	draw_colored_polygon(PackedVector2Array([
		Vector2(-r * 0.85, 0.0),
		Vector2(-r * 1.6, r * (0.55 + bat)),
		Vector2(-r * 1.6, -r * (0.55 - bat))]), color)

	# Ojo, del color del fondo del bioma no: negro, que se lee sobre cualquiera.
	draw_circle(Vector2(r * 0.55, -r * 0.12), r * 0.15, Color(0, 0, 0, 0.6))


## Estrella: cuatro puntas y un núcleo. El destello sale de que las puntas sean
## mucho más largas que anchas, no de ningún efecto.
func _estrella(r: float) -> void:
	var brillo := 0.75 + 0.25 * sin(_fase * 2.4 + _semilla)
	var largo := r * 1.5 * brillo
	var ancho := r * 0.3
	draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, -largo), Vector2(ancho, 0.0),
		Vector2(0.0, largo), Vector2(-ancho, 0.0)]), color)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-largo, 0.0), Vector2(0.0, ancho),
		Vector2(largo, 0.0), Vector2(0.0, -ancho)]), color)
	draw_circle(Vector2.ZERO, r * 0.42, color)


## Brasa: sube y se renueva por abajo. Es la nieve del revés, y eso cambia la
## lectura del campo más de lo que parece — se caza hacia arriba.
func _mover_brasa(delta: float, rect: Vector2) -> void:
	var vaiven := sin(_fase * 2.2 + _semilla) * base_speed * 0.45
	position += Vector2(vaiven, -base_speed * 0.5) * delta
	if position.y < -radius:
		position = Vector2(randf() * rect.x, rect.y + radius)
	if position.x < -radius:
		position.x = rect.x + radius
	elif position.x > rect.x + radius:
		position.x = -radius


## Planeo: vira despacio y cabecea. Ningún tramo es recto del todo, así que
## adivinar dónde estará un avión exige mirarlo un segundo entero, no un
## instante. Es lo contrario del circuito.
func _mover_planeo(delta: float, rect: Vector2) -> void:
	_giro -= delta
	if _giro <= 0.0:
		_giro = randf_range(1.1, 2.4)
		_vira = randf_range(-0.8, 0.8)
	velocity = Vector2.from_angle(velocity.angle() + _vira * delta) * base_speed
	var cabeceo := Vector2(0.0, sin(_fase * 2.1 + _semilla) * base_speed * 0.2)
	position += (velocity + cabeceo) * delta
	_rebotar(rect)


## Misil: acelera en su rumbo hasta un tope.
##
## Es el único bioma donde el campo se vuelve más difícil solo con esperar: un
## grupo que ahora se puede cazar, en dos segundos ya no. Castiga la duda, que
## es justo lo que el resto del juego premia.
const MISIL_ACEL := 0.85
const MISIL_TOPE := 2.4

func _mover_misil(delta: float, rect: Vector2) -> void:
	var v := velocity.length()
	if v < base_speed * MISIL_TOPE:
		velocity = velocity.normalized() * (v + base_speed * MISIL_ACEL * delta)
	position += velocity * delta
	_rebotar(rect)


## Circuito: solo horizontal y vertical, con giros de noventa grados. Las
## trayectorias son las más predecibles del juego, así que lo difícil deja de ser
## adivinar y pasa a ser esperar al cruce.
func _mover_circuito(delta: float, rect: Vector2) -> void:
	_giro -= delta
	if _giro <= 0.0:
		_giro = randf_range(0.45, 1.3)
		var d := velocity.normalized()
		velocity = (Vector2(-d.y, d.x) if randf() < 0.5 else Vector2(d.y, -d.x)) * base_speed
	position += velocity * delta
	_rebotar(rect)


## Se comprueba también el signo de la velocidad: sin eso, un círculo que
## aparece fuera del borde queda atrapado invirtiéndose cada frame.
func _rebotar(rect: Vector2) -> void:
	if position.x < radius and velocity.x < 0.0:
		velocity.x = -velocity.x
	elif position.x > rect.x - radius and velocity.x > 0.0:
		velocity.x = -velocity.x
	if position.y < radius and velocity.y < 0.0:
		velocity.y = -velocity.y
	elif position.y > rect.y - radius and velocity.y > 0.0:
		velocity.y = -velocity.y
