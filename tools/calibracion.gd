extends SceneTree

## Banco de calibración. No forma parte del juego.
##
## Corre tandas de detonaciones sin dibujar nada y reporta cuántos puntos
## atrapa un tap al azar frente a uno bien colocado. Sirve para ver de un
## vistazo si un cambio de parámetros deja partidas muertas o si borra la
## brecha de habilidad. Lo que NO puede medir es si se siente bien: eso solo
## se sabe con el pulgar.
##
## Uso:
##   godot --headless --path . --script res://tools/calibracion.gd
##
## Ojo con dos cosas al leer los resultados:
##  - headless corre en TIEMPO REAL, no acelerado. Subir TRIALS cuesta minutos.
##  - headless ignora el tamaño de ventana y da un viewport cuadrado de
##    1280x1280, por eso dot_count se sube a 44: es lo que iguala la densidad
##    del campo real de 720x1280.

const TRIALS := 25
const TAP_R := 150.0

func _initialize() -> void:
	var main = load("res://main.tscn").instantiate()
	# Headless ignora el resize de ventana y da 1280x1280. En vez de pelearse
	# con eso, se iguala la DENSIDAD del campo real de 720x1280:
	#   25 / (720*1280) * (1280*1280) = 44.4
	main.target_dots = 44
	root.add_child(main)
	await process_frame
	await process_frame
	print("viewport: ", root.get_visible_rect().size, "  puntos: ", main._dots.size())

	var rnd := await _run(main, false)
	var skl := await _run(main, true)
	_report("tap AL AZAR   ", rnd)
	_report("tap AL CLUSTER", skl)
	quit()

func _run(main, smart: bool) -> Array:
	var out := []
	for t in TRIALS:
		main._poblar_campo()
		main._state = 0  # State.START: el campo vive pero la partida no corre
		await process_frame
		main._spawn_explosion(_pick(main, smart), TAP_R)
		var guard := 0
		while not main._explosions.is_empty() and guard < 5000:
			await process_frame
			guard += 1
		out.append(main._chain)
	return out

func _pick(main, smart: bool) -> Vector2:
	if not smart:
		# Un círculo cualquiera: desde v2 el jugador ya no puede detonar en un
		# vacío, así que medir un punto aleatorio de la pantalla no diría nada.
		return main._dots[randi() % main._dots.size()].position
	var best := Vector2.ZERO
	var best_n := -1
	for d in main._dots:
		var n := 0
		for o in main._dots:
			if d.position.distance_to(o.position) <= TAP_R:
				n += 1
		if n > best_n:
			best_n = n
			best = d.position
	return best

func _report(label: String, a: Array) -> void:
	a.sort()
	var sum := 0
	var zeros := 0
	var big := 0
	for v in a:
		sum += v
		if v == 0: zeros += 1
		if v >= 10: big += 1
	print("%s  media %.1f | mediana %d | min %d | max %d | ceros %d | >=10 %d  (de %d)" % [
		label, float(sum) / a.size(), a[a.size() / 2], a[0], a[-1], zeros, big, a.size()])
