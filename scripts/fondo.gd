class_name Fondo
extends Node2D

## El telón de cada bioma, como mosaico.
##
## El patrón se genera UNA vez en una imagen pequeña que encaja consigo misma, y
## en pantalla se dibuja repetida con una única llamada. Antes se redibujaba
## entero cada frame y costaba un tercio del rendimiento en escritorio —bajar de
## 60 en un teléfono— y bajar el número de hexágonos de 170 a 45 apenas movió la
## aguja: el problema no era la cantidad de figuras sino reemitirlas todas cada
## frame. Con mosaico son cientos de comandos de dibujo menos, siempre.
##
## La animación sale gratis desplazando el mosaico: cuesta lo mismo que tenerlo
## quieto, porque sigue siendo una sola llamada.
##
## Regla que manda sobre cualquier capricho estético: **el fondo no puede
## competir con los círculos**. Alfas muy bajas, escala grande y movimiento
## lento. Lo único que el jugador tiene que localizar a toda velocidad es un
## círculo de nueve píxeles.
##
## Se dibuja detrás de todo y NO se sacude con el campo: un telón que tiembla
## con cada eslabón convierte la pantalla en un mareo.

enum Tipo {
	LISO,       ## nada
	ESTRELLAS,  ## puntos lejanos
	COPOS,      ## nieve cayendo
	CORRIENTE,  ## líneas de agua desplazándose
	CELULAS,    ## manchas orgánicas
	TAPETE,     ## trama diagonal de paño
	PANAL,      ## rejilla hexagonal
	REJILLA,    ## cuadrícula técnica
	HOJAS,      ## siluetas cayendo
	PAVESAS,    ## chispas subiendo
	TRAZAS,     ## pistas de circuito
}

## Lado del mosaico. Potencia de dos y divisible por los pasos de todos los
## patrones, que es lo que hace que encajen consigo mismos sin costura.
const LADO := 128

## Los mosaicos se guardan por tipo: generar uno cuesta unos milisegundos y no
## hay motivo para repetirlo cada vez que se entra al mismo bioma.
static var _cache: Dictionary = {}

var tipo: Tipo = Tipo.LISO
var color: Color = Color("ffffff")

var _tex: ImageTexture
var _scroll: Vector2 = Vector2.ZERO
var _deriva: Vector2 = Vector2.ZERO


func configurar(nuevo_tipo: Tipo, nuevo_color: Color) -> void:
	tipo = nuevo_tipo
	color = nuevo_color
	_scroll = Vector2.ZERO
	_deriva = _deriva_de(tipo)
	_tex = _mosaico(tipo)
	set_process(_deriva != Vector2.ZERO)
	queue_redraw()


## Hacia dónde y a qué velocidad se desplaza el mosaico, en píxeles por segundo.
## La dirección cuenta la historia del bioma sin decir una palabra: la nieve
## cae, las pavesas suben, el río va de lado.
func _deriva_de(t: Tipo) -> Vector2:
	match t:
		Tipo.COPOS: return Vector2(4.0, 16.0)
		Tipo.HOJAS: return Vector2(7.0, 20.0)
		Tipo.PAVESAS: return Vector2(-3.0, -22.0)
		Tipo.CORRIENTE: return Vector2(26.0, 0.0)
		Tipo.CELULAS: return Vector2(3.0, -2.0)
		Tipo.REJILLA: return Vector2(0.0, 9.0)
		_: return Vector2.ZERO


func _process(delta: float) -> void:
	_scroll += _deriva * delta
	# Se envuelve dentro de un mosaico para que el desplazamiento no crezca sin
	# límite y acabe perdiendo precisión tras un rato largo de partida.
	_scroll.x = fposmod(_scroll.x, float(LADO))
	_scroll.y = fposmod(_scroll.y, float(LADO))
	queue_redraw()


func _draw() -> void:
	if _tex == null or tipo == Tipo.LISO:
		return
	var r := get_viewport_rect().size
	# Una sola llamada para todo el telón. Se dibuja un mosaico de más en cada
	# lado para que el desplazamiento no descubra el borde.
	draw_texture_rect(
		_tex,
		Rect2(_scroll - Vector2(LADO, LADO), r + Vector2(LADO, LADO) * 2.0),
		true,
		color)


# --- generación del mosaico ------------------------------------------------

func _mosaico(t: Tipo) -> ImageTexture:
	if t == Tipo.LISO:
		return null
	if _cache.has(t):
		return _cache[t]

	var img := Image.create(LADO, LADO, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 0))
	# Semilla fija: el mosaico de un bioma tiene que ser siempre el mismo, o el
	# fondo cambiaría de dibujo cada vez que se entra al nivel.
	var rnd := RandomNumberGenerator.new()
	rnd.seed = 20260830 + int(t)

	match t:
		Tipo.ESTRELLAS: _gen_puntos(img, rnd, 14, 1.0, 2.2, 0.10)
		Tipo.COPOS: _gen_puntos(img, rnd, 10, 1.2, 1.8, 0.11)
		Tipo.PAVESAS: _gen_puntos(img, rnd, 12, 1.0, 2.0, 0.10)
		Tipo.HOJAS: _gen_hojas(img, rnd)
		Tipo.CELULAS: _gen_celulas(img, rnd)
		Tipo.CORRIENTE: _gen_corriente(img)
		Tipo.TAPETE: _gen_tapete(img)
		Tipo.REJILLA: _gen_rejilla(img)
		Tipo.PANAL: _gen_panal(img)
		Tipo.TRAZAS: _gen_trazas(img, rnd)

	var tex := ImageTexture.create_from_image(img)
	_cache[t] = tex
	return tex


## Pinta un píxel con envoltura y quedándose con el alfa más alto.
##
## La envoltura es lo que hace que el mosaico encaje: una figura que se sale por
## un borde entra por el opuesto, así que nunca hay costura.
func _px(img: Image, x: int, y: int, a: float) -> void:
	var px := posmod(x, LADO)
	var py := posmod(y, LADO)
	var previo := img.get_pixel(px, py).a
	img.set_pixel(px, py, Color(1, 1, 1, maxf(previo, a)))


func _disco(img: Image, c: Vector2, r: float, a: float) -> void:
	var ri := int(ceil(r))
	for dy in range(-ri, ri + 1):
		for dx in range(-ri, ri + 1):
			var d := sqrt(float(dx * dx + dy * dy))
			if d > r:
				continue
			# Borde suavizado: sin esto los puntos pequeños se ven dentados.
			_px(img, int(c.x) + dx, int(c.y) + dy, a * clampf(r - d, 0.0, 1.0))


func _linea(img: Image, a: Vector2, b: Vector2, alfa: float, grosor: float = 1.0) -> void:
	var largo := a.distance_to(b)
	var pasos := int(largo * 2.0) + 1
	for i in pasos + 1:
		var p := a.lerp(b, float(i) / float(pasos))
		if grosor <= 1.0:
			_px(img, int(round(p.x)), int(round(p.y)), alfa)
		else:
			_disco(img, p, grosor * 0.5, alfa)


func _gen_puntos(img: Image, rnd: RandomNumberGenerator, n: int,
		rmin: float, rmax: float, alfa: float) -> void:
	for i in n:
		_disco(img,
			Vector2(rnd.randf() * LADO, rnd.randf() * LADO),
			rnd.randf_range(rmin, rmax),
			alfa * rnd.randf_range(0.6, 1.0))


func _gen_hojas(img: Image, rnd: RandomNumberGenerator) -> void:
	for i in 8:
		var c := Vector2(rnd.randf() * LADO, rnd.randf() * LADO)
		var d := Vector2.from_angle(rnd.randf() * TAU) * 5.0
		_linea(img, c - d, c + d, 0.10, 2.5)


func _gen_celulas(img: Image, rnd: RandomNumberGenerator) -> void:
	# Manchas grandes y muy tenues. Se dibujan como anillos difusos en vez de
	# discos llenos: un disco de este tamaño taparía el fondo.
	for i in 3:
		var c := Vector2(rnd.randf() * LADO, rnd.randf() * LADO)
		var r := rnd.randf_range(26.0, 40.0)
		var pasos := 90
		for k in pasos:
			var p := c + Vector2.from_angle(TAU * float(k) / float(pasos)) * r
			_disco(img, p, 3.0, 0.05)


func _gen_corriente(img: Image) -> void:
	# Ondas horizontales cuyo periodo es exactamente el lado del mosaico, así
	# que la onda continúa sin salto al repetirse.
	for fila in 3:
		var base := 20.0 + 42.0 * float(fila)
		var pts := PackedVector2Array()
		for x in LADO + 1:
			pts.append(Vector2(float(x), base + sin(TAU * float(x) / float(LADO)) * 6.0))
		for i in pts.size() - 1:
			_linea(img, pts[i], pts[i + 1], 0.08, 1.6)


func _gen_tapete(img: Image) -> void:
	# Diagonales de paso 32: divide a 128, así que casan al repetir.
	var paso := 32
	for k in range(-LADO, LADO * 2, paso):
		_linea(img, Vector2(k, 0), Vector2(k + LADO, LADO), 0.05)


func _gen_rejilla(img: Image) -> void:
	var paso := 32
	for k in range(0, LADO, paso):
		_linea(img, Vector2(k, 0), Vector2(k, LADO), 0.055)
		_linea(img, Vector2(0, k), Vector2(LADO, k), 0.055)


func _gen_panal(img: Image) -> void:
	# Celdas centradas en una retícula que se repite cada 128 en los dos ejes:
	# dos columnas y dos filas por mosaico, con las impares desplazadas media
	# celda. Es lo que permite que el panal continúe de un mosaico al siguiente.
	var paso := 64.0
	var lado := 34.0
	for fy in range(-1, 3):
		for fx in range(-1, 3):
			var c := Vector2(
				float(fx) * paso + (paso * 0.5 if posmod(fy, 2) == 1 else 0.0),
				float(fy) * paso)
			for i in 6:
				var a := c + Vector2.from_angle(deg_to_rad(60.0 * float(i) - 30.0)) * lado
				var b := c + Vector2.from_angle(deg_to_rad(60.0 * float(i + 1) - 30.0)) * lado
				_linea(img, a, b, 0.07)


func _gen_trazas(img: Image, rnd: RandomNumberGenerator) -> void:
	# Tramos en ángulo recto con un nodo al final, como una placa.
	for i in 5:
		var p := Vector2(
			float(rnd.randi_range(0, 3)) * 32.0,
			float(rnd.randi_range(0, 3)) * 32.0)
		var horizontal := rnd.randf() < 0.5
		var largo := float(rnd.randi_range(1, 3)) * 32.0
		var medio := p + (Vector2.RIGHT if horizontal else Vector2.DOWN) * largo
		var fin := medio + (Vector2.DOWN if horizontal else Vector2.RIGHT) * 32.0
		_linea(img, p, medio, 0.075)
		_linea(img, medio, fin, 0.075)
		_disco(img, fin, 2.4, 0.13)
