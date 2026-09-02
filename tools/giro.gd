extends SceneTree

## Comprueba que ninguna forma DE PERFIL acaba boca abajo al ir a la izquierda.
##
##   godot --path . --headless --script tools/giro.gd
##
## Es la guarda del contrato de orientación: dibujar de perfil y girar hacia el
## rumbo deja a la abeja volando boca arriba y al pez nadando panza arriba. Se
## comprueba aquí porque no se ve en una hoja de contactos, donde están quietos.
##
## Solo cuenta como fallo en ESPEJO y CABECEO. Las cenitales -dron, misil,
## meteoro, hormiga- dan la vuelta entera A PROPOSITO, y marcarlas seria una
## falsa alarma; una comprobación que grita sin motivo enseña a ignorarla.
func _initialize() -> void:
	print("%-10s %-9s %-12s %s" % ["forma", "politica", "yendo a izq", "veredicto"])
	var nombres := ["FIJO", "RUMBO", "ESPEJO", "CABECEO", "NORIA"]
	var malos := 0
	for forma in Arte.NOMBRE_FORMA.size():
		var d := Dot.new()
		d.forma = forma
		d.base_speed = 100.0
		d.velocity = Vector2(-100.0, 20.0)
		root.add_child(d)
		d.mover(0.016, Rect2(0, 0, 500, 500))
		var pol: int = Dot.GIRO_DE_FORMA[forma]
		# Boca abajo = el eje vertical del dibujo acaba apuntando hacia arriba.
		var arriba := Vector2.UP.rotated(d.rotation) * signf(d.scale.y)
		var de_perfil := pol == Dot.Giro.ESPEJO or pol == Dot.Giro.CABECEO
		var invertida := arriba.y > 0.0 and de_perfil
		if invertida:
			malos += 1
		print("%-10s %-9s rot %+5.0f  esc %+.0f   %s" % [
				Arte.NOMBRE_FORMA[forma], nombres[pol],
				rad_to_deg(d.rotation), d.scale.x,
				"BOCA ABAJO" if invertida else ("cenital, gira entera" if pol == Dot.Giro.RUMBO else "ok")])
		d.queue_free()
	print("")
	print("formas de perfil invertidas: %d%s" % [malos, "" if malos == 0 else "   <-- FALLO"])
	quit()
