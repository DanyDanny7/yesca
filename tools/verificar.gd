extends SceneTree

## Comprueba invariantes de geometría en todos los niveles. No forma parte del
## juego y no mide diversión: mide que nada ocurra donde no se puede ver.
##
##   godot --headless --path . --script tools/verificar.gd
##
## Tres preguntas, y las tres han estado mal alguna vez:
##
## 1. ¿Se queda algún objetivo dentro del borde de guarda? Si pasa, su onda se
##    dibuja medio fuera de la pantalla y el jugador ve desaparecer cosas sin
##    ver por qué.
## 2. En los biomas de defensa, ¿aguanta la barra lo suficiente para que la
##    mecánica llegue a jugarse? En el asedio no aguantaba: la partida moría de
##    tiempo a los 11 s mientras los proyectiles tardaban 21 s en llegar abajo,
##    así que se perdía sin haber visto nunca la amenaza que da nombre al bioma.
## 3. ¿Los meteoros van de verdad al planeta? Todo el bioma se apoya en que
##    convergen; si alguno se va por su cuenta, no es una lluvia.

## Proporción de teléfono, no la ventana cuadrada que da headless.
const ANCHO := 540
const ALTO := 960

const SEGUNDOS_POR_NIVEL := 5.0
const ACELERACION := 4.0
## Cuánto se le perdona a un objetivo por asomar el morro fuera del área.
const TOLERANCIA := 2.0


func _initialize() -> void:
	Engine.time_scale = ACELERACION
	# El juego va dentro de un SubViewport con proporción de teléfono. En
	# headless la ventana es un cuadrado de 1280x1280, y ahí las medidas
	# mienten: el fondo se escala por el ancho, así que la ciudad de Asedio
	# ocupaba el doble de alto que en un móvil y la partida parecía morir en
	# la mitad de tiempo. Se medía una pantalla que no existe.
	var vp := SubViewport.new()
	vp.size = Vector2i(ANCHO, ALTO)
	root.add_child(vp)
	var main = load("res://main.tscn").instantiate()
	vp.add_child(main)
	# Se mide SIEMPRE con las reglas puestas. El modo sin morir es para
	# mirar a mano, no para medir: una vez se coló encendido en el guardado y
	# durante horas todo se midió con inmortalidad sin que nada lo dijera.
	main._sin_morir = false
	await process_frame
	await process_frame

	var pantalla: Vector2 = Vector2(ANCHO, ALTO)
	var area: Rect2 = main._area_juego()
	print("pantalla %d x %d" % [pantalla.x, pantalla.y])
	print("área de juego  x: %d..%d   y: %d..%d" % [
			area.position.x, area.end.x, area.position.y, area.end.y])
	var zc: Rect2 = main._area_cadena()
	print("zona de cadena  x: %d..%d   y: %d..%d" % [
			zc.position.x, zc.end.x, zc.position.y, zc.end.y])
	print("guarda (sin cadena)  arriba %d   lados %d   abajo %d" % [
			zc.position.y, zc.position.x, pantalla.y - zc.end.y])
	print("onda de cadena: hasta %d px de radio" % main.chain_radius_base)
	print("")
	print("biomas: %d   niveles: %d" % [Niveles.biomas().size(), Niveles.total()])
	print("sin fin rota por %d, defensa incluida" % Niveles.biomas_sinfin().size())
	print("")

	await _recorrer_niveles(main, area, pantalla)
	await _defensa(main, pantalla)
	_bolsa(main)
	quit()


## Pasea por todos los niveles midiendo lo que de verdad importa.
##
## La franja de guarda ya NO excluye objetivos: entran, se ven y se tocan. Lo
## que excluye son los CONTAGIOS —una cadena no prende a nadie que esté fuera de
## la zona, por encima que le pase la onda—.
##
## Así que aquí ya no se comprueba una distancia mínima al borde, que ahora es
## legítimo que sea pequeña. Se informa de lo cerca que llegan, que es un dato
## útil para saber si el campo usa la pantalla entera, y de cuántos objetivos
## quedan fuera de la zona de cadena en cada momento.
func _recorrer_niveles(main, area: Rect2, pantalla: Vector2) -> void:
	var malos := 0
	print("%-4s %-20s %-8s %-18s %s" % [
			"niv", "bioma", "targets", "más cerca del borde", "fuera de la cadena"])
	for i in Niveles.total():
		var nivel: Dictionary = Niveles.nivel(i)
		var bioma := str(nivel["bioma"])

		main._mode = 0
		main._nivel = i
		main._empezar_partida()
		main._state = 3
		await process_frame

		var mas_cerca := 99999.0
		var fuera_max := 0
		var zona: Rect2 = main._area_cadena()
		while main._elapsed < SEGUNDOS_POR_NIVEL and main._state == 3:
			await process_frame
			var fuera := 0
			for d in main._dots:
				var p: Vector2 = d.position
				# Solo cuentan los que YA estan en pantalla: los que entran vienen
				# legitimamente de fuera, y contarlos daria una falsa alarma en
				# cada bioma que reponga por los bordes, que son casi todos.
				if _al_borde(p, pantalla) >= 0.0:
					mas_cerca = minf(mas_cerca, _al_borde(p, pantalla))
				if not zona.has_point(p):
					fuera += 1
			fuera_max = maxi(fuera_max, fuera)

		print("%-4d %-20s %-8d %-18s %s" % [i + 1, bioma, main._dots.size(),
				"%d px" % mas_cerca,
				"—" if fuera_max == 0 else "hasta %d a la vez" % fuera_max])

	print("")
	print("El campo llega hasta el borde: los objetivos entran en la franja de")
	print("guarda, se ven y se tocan. Lo que no hacen alli es prender por cadena.")
	print("(La columna de la derecha dice cuantos quedan fuera de la zona a la vez.)")
	print("")


## A cuántos píxeles está del borde de pantalla más cercano.
func _al_borde(p: Vector2, pantalla: Vector2) -> float:
	return minf(minf(p.x, pantalla.x - p.x), minf(p.y, pantalla.y - p.y))


func _fuera_del_area(p: Vector2, area: Rect2) -> float:
	return maxf(maxf(area.position.x - p.x, p.x - area.end.x),
			maxf(area.position.y - p.y, p.y - area.end.y))


## Los dos biomas de defensa, sin tocar nada: ¿de qué se muere?
##
## Es la comprobación que faltó la primera vez que se hizo el asedio. Si la
## partida abandonada muere de tiempo, el bioma no existe: el jugador nunca
## llega a ver la amenaza de la que va el nivel.
func _defensa(main, pantalla: Vector2) -> void:
	print("=== biomas de defensa, sin tocar nada ===")
	for i in Niveles.total():
		var nivel: Dictionary = Niveles.nivel(i)
		var bioma := str(nivel["bioma"])
		var pal := Niveles.paleta_de(bioma)
		if not bool(pal.get("defender", false)):
			continue
		if i > 0 and str(Niveles.nivel(i - 1)["bioma"]) == bioma:
			continue

		main._mode = 0
		main._nivel = i
		main._empezar_partida()
		main._state = 3
		await process_frame

		var rumbo_max := 0.0
		var meteoros := str(pal.get("defensa", "suelo")) == "planeta"
		var centro: Vector2 = main._fondo.planeta_centro(pantalla)
		while main._state == 3 and main._elapsed < 120.0:
			await process_frame
			if meteoros:
				for d in main._dots:
					if d.velocity.length_squared() < 1.0:
						continue
					var hacia: Vector2 = (centro - d.position).normalized()
					rumbo_max = maxf(rumbo_max, absf(float(d.velocity.normalized().angle_to(hacia))))

		var motivo: String = main._over_title.text
		print("  %-20s murió a los %5.1fs por: %s" % [bioma, main._elapsed, motivo])
		if meteoros:
			print("  %-20s desvío máximo respecto al planeta: %.1f grados" % [
					"", rad_to_deg(rumbo_max)])
	print("")


## La bolsa del modo sin fin: ¿reparte de verdad sin repetir?
##
## Se saca la secuencia entera de dos vueltas completas. Lo que tiene que
## cumplirse es que dentro de cada vuelta salgan todos los biomas y ninguno dos
## veces, y que en la costura entre vueltas tampoco se repita: es el único punto
## donde barajar de nuevo podría colar un duplicado seguido.
func _bolsa(main) -> void:
	print("=== bolsa de biomas del modo sin fin ===")
	var total: int = Niveles.biomas_sinfin().size()
	main._rellenar_bolsa()
	var salida: Array = []
	for i in total * 2:
		salida.append(main._bioma_actual_sinfin())
		main._bolsa_i += 1
		if main._bolsa_i >= main._bolsa.size():
			main._rellenar_bolsa(salida[salida.size() - 1])

	for vuelta in 2:
		var trozo: Array = salida.slice(vuelta * total, (vuelta + 1) * total)
		var unicos := {}
		for b in trozo:
			unicos[b] = true
		print("  vuelta %d: %d biomas, %d distintos  %s" % [
				vuelta + 1, trozo.size(), unicos.size(),
				"ok" if unicos.size() == total else "REPITE"])
		print("    " + ", ".join(PackedStringArray(trozo)))

	var seguidos := 0
	for i in range(1, salida.size()):
		if salida[i] == salida[i - 1]:
			seguidos += 1
	print("  repeticiones seguidas en toda la secuencia: %d %s" % [
			seguidos, "" if seguidos == 0 else "  <-- FALLO"])
	print("")
