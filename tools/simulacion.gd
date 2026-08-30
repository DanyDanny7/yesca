extends SceneTree

## Simulador de partidas. No forma parte del juego.
##
## Juega partidas enteras sin dibujar nada, con dos perfiles de jugador, y
## reporta cuánto sobreviven y cuánto puntúan. Sirve para responder la única
## pregunta que decide si la economía de tiempo funciona:
##
##   ¿el tap descuidado pierde y el tap bueno gana?
##
## Si los dos perfiles sobreviven igual, el juego es trivial. Si los dos mueren
## rápido, es injugable. Lo que buscamos es separación clara entre ambos.
##
## Uso:
##   godot --headless --path . --script res://tools/simulacion.gd
##   godot --headless --path . --script res://tools/simulacion.gd -- 150 2 bueno
##
## Argumentos opcionales tras el "--": cap en segundos, número de partidas y
## el perfil a correr ("bueno", "descuidado" o nada para los dos).
##
## Dos avisos al leer los resultados:
##  - headless ignora el tamaño de ventana y da un viewport cuadrado de
##    1280x1280, por eso target_dots sube a 44: es lo que iguala la densidad
##    del campo real de 720x1280.
##  - se acelera con Engine.time_scale porque headless corre en tiempo real.
##    A x3 los puntos avanzan ~3 px por frame, muy por debajo del radio de
##    detonación, así que la detección de contagios no se degrada.

var runs := 3
var cap_segundos := 45.0
var solo := ""
const ACELERACION := 3.0

## Cuántos puntos tiene que ver juntos el jugador bueno para gastar un tap.
const CLUSTER_MINIMO := 6
## Por debajo de esto ya no se puede elegir: toca detonar lo que haya.
const DESESPERO := 2.5
## Con qué frecuencia se le va el dedo al jugador descuidado.
const PROB_FALLO := 0.25


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		cap_segundos = float(args[0])
	if args.size() > 1:
		runs = int(args[1])
	if args.size() > 2:
		solo = args[2]

	Engine.time_scale = ACELERACION
	var main = load("res://main.tscn").instantiate()
	main.target_dots = 44
	root.add_child(main)
	await process_frame
	await process_frame

	print("viewport: ", root.get_visible_rect().size, "   cap: %.0fs   partidas: %d" % [cap_segundos, runs])
	print("modelo de input: se toca un CÍRCULO, no la pantalla")
	print("")
	if solo != "bueno":
		await _perfil(main, "DESCUIDADO (toca al azar en cuanto le baja la barra)", false)
	if solo != "descuidado":
		await _perfil(main, "BUENO      (espera a ver %d juntos)" % CLUSTER_MINIMO, true)
	quit()


func _perfil(main, etiqueta: String, bueno: bool) -> void:
	var tiempos := []
	var scores := []
	for r in runs:
		var res = await _partida(main, bueno)
		tiempos.append(res[0])
		scores.append(res[1])
	print(etiqueta)
	print("   sobrevivió: %s   (media %.1fs)" % [_fmt(tiempos, "%.1fs"), _media(tiempos)])
	print("   puntuó:     %s   (media %.1f)" % [_fmt(scores, "%d"), _media(scores)])
	print("")


func _partida(main, bueno: bool) -> Array:
	main._empezar_partida()
	# Los índices siguen a enum State { MENU, SELECT, READY, PLAYING, DEAD, ... }
	# Ojo al tocarlo: añadir estados al principio del enum desplaza estos números
	# y el simulador se queda girando en vacío sin que avance el reloj.
	main._state = 3  # State.PLAYING
	await process_frame

	while main._state != 4 and main._elapsed < cap_segundos:  # 4 = State.DEAD
		await process_frame
		# Solo el jugador bueno sabe esperar. El descuidado toca a media cascada
		# y se come el reinicio del multiplicador, que es precisamente la
		# diferencia que el juego quiere premiar. Modelarlo de otra forma
		# escondía el efecto del cambio.
		if bueno and main._explosions.size() > 0:
			continue
		var objetivo = _decidir(main, bueno)
		if objetivo != null:
			main._tap(objetivo)

	return [main._elapsed, main._score]


func _decidir(main, bueno: bool):
	if main._dots.is_empty():
		return null
	var apurado: bool = main._time_left < DESESPERO

	if not bueno:
		# Reactivo y sin criterio: toca en cuanto la barra baja de la mitad,
		# eligiendo un círculo cualquiera. Con PROB_FALLO se le va el dedo, que
		# es lo que le pasa a quien juega sin mirar.
		if main._time_left >= main.time_max * 0.5:
			return null
		var d = main._dots[randi() % main._dots.size()]
		if randf() < PROB_FALLO:
			return d.position + Vector2.from_angle(randf() * TAU) * (main.tap_tolerance * 2.0)
		return d.position

	var mejor = _mejor_cluster(main)
	if mejor == null:
		return null
	if mejor[1] >= CLUSTER_MINIMO or apurado:
		return mejor[0]
	return null


## El círculo con más vecinos dentro de su radio de detonación, que es el que
## un jugador con buen ojo elegiría. Devuelve [posición, cuántos vecinos].
func _mejor_cluster(main):
	var mejor_pos = null
	var mejor_n := -1
	for d in main._dots:
		var n := 0
		for o in main._dots:
			if d.position.distance_to(o.position) <= main.tap_radius:
				n += 1
		if n > mejor_n:
			mejor_n = n
			mejor_pos = d.position
	if mejor_pos == null:
		return null
	return [mejor_pos, mejor_n]


func _media(a: Array) -> float:
	var s := 0.0
	for v in a:
		s += float(v)
	return s / a.size()


func _fmt(a: Array, f: String) -> String:
	var partes := []
	for v in a:
		partes.append(f % v)
	return "  ".join(partes)
