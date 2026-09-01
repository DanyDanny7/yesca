extends SceneTree

## Convierte los fondos entregados en las dos capas que usa el juego.
##
##   godot --path . --headless --script tools/importar_fondos.gd
##
## Lee de arte/assets-yesca/_split/, que produce el troceado en Python, y
## escribe en arte/fondos/ (el azulejo, que se repite y se desplaza) y en
## arte/telones/ (la composición, que se ancla abajo y no se estira).
##
## La separación no es un capricho de implementación: una capa se puede repetir
## y la otra no. Una bañera repetida en baldosas no es una bañera, y una bañera
## estirada al doble de ancho tampoco.
##
## Rasteriza los SVG a PNG, en las carpetas que lee el juego.
##
## Los fondos que no traen patrón repetible no se quedan sin azulejo: se les
## sintetiza uno con el color de la PRIMERA FILA de su propia composición. Ese
## color es exactamente el que toca el hueco que queda por encima cuando la
## pantalla es más alta que la imagen, así que la unión no se ve. Sacarlo del
## SVG no valía: varios fondos tienen degradado, no color plano.
const ENTRADA := "res://arte/assets-yesca/_split/"

func _initialize() -> void:
	var d := DirAccess.open(ENTRADA)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://arte/fondos/"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://arte/telones/"))

	var con_patron := {}
	var capas := {}
	for f in d.get_files():
		if not f.ends_with(".svg"):
			continue
		var img := Image.new()
		if img.load_svg_from_string(FileAccess.get_file_as_string(ENTRADA + f), 1.0) != OK:
			print("FALLO al rasterizar ", f)
			continue
		var partes := f.replace(".svg", "").split("__")
		var bioma: String = partes[0]
		if partes[1] == "tile":
			img.save_png("res://arte/fondos/%s.png" % bioma)
			con_patron[bioma] = true
			print("  %-20s azulejo   %d x %d" % [bioma, img.get_width(), img.get_height()])
		else:
			img.save_png("res://arte/telones/%s.png" % bioma)
			capas[bioma] = img
			print("  %-20s capa      %d x %d" % [bioma, img.get_width(), img.get_height()])

	for bioma in capas:
		if con_patron.has(bioma):
			continue
		var capa: Image = capas[bioma]
		# Media de la fila superior: un solo píxel podría caer en una estrella.
		var r := 0.0
		var g := 0.0
		var b := 0.0
		for x in capa.get_width():
			var c := capa.get_pixel(x, 0)
			r += c.r
			g += c.g
			b += c.b
		var n := float(capa.get_width())
		var tinte := Color(r / n, g / n, b / n)
		var tile := Image.create(8, 8, false, Image.FORMAT_RGBA8)
		tile.fill(tinte)
		tile.save_png("res://arte/fondos/%s.png" % bioma)
		print("  %-20s azulejo   plano %s (de su fila superior)" % [bioma, tinte.to_html(false)])
	quit()
