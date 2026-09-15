extends SceneTree

## Rasteriza a PNG los fondos ya troceados, en las carpetas que lee el juego.
##
##   godot --path . --headless --script tools/importar_fondos.gd -- entregas/<lote>
##
## Lee de <lote>/_split/, que produce tools/separar_fondos.py, y escribe en
## arte/elasticas/, arte/fondos/ y arte/telones/.
##
## El sufijo del fichero dice a qué carpeta va, y tiene que coincidir con el que
## escribe el troceador. Coincidir no es un detalle: cuando dejaron de cuadrar,
## esto no fallo con un error, se limito a tratar TODO como capa rigida y a
## fabricar azulejos de color negro. Un desajuste que no rompe nada es peor que
## uno que revienta.
## Cada sufijo del troceador, a su carpeta y a su nombre de fichero.
##
## El dosel va a `telones/` como la rigida porque es lo mismo -una pieza que no
## se deforma- pero con otro nombre, que es lo que le dice al juego que se ancla
## arriba en vez de abajo.
const CARPETA := {
	"elastica": ["elasticas", ""],
	"azulejo": ["fondos", ""],
	"rigida": ["telones", ""],
	"dosel": ["telones", "_dosel"],
}
const LOTE_POR_DEFECTO := "entregas/2026-09-02-ajuste-contrato"


## Le quita al dosel el vacio de abajo, dejando intacto el borde de arriba.
##
## El troceador escribe cada pieza sobre el lienzo entero para no tener que
## recalcular coordenadas. A la pieza anclada abajo le da igual -se ancla por el
## borde que tiene contenido- pero el dosel cuelga de ARRIBA, asi que su borde
## util es el de arriba y todo lo que sobra cuelga por debajo: la guirnalda ocupa
## los primeros 250 px de 1500 y el resto son 1250 px de nada que se cargan en
## memoria de video igual que si dibujaran algo.
##
## Se recorta solo por abajo a proposito. Recortar tambien por arriba moveria la
## guirnalda: la distancia al borde superior es parte del dibujo.
func _recortar_abajo(img: Image) -> Image:
	var ancho := img.get_width()
	var ultima := -1
	for y in img.get_height():
		for x in ancho:
			if img.get_pixel(x, y).a > 0.03:
				ultima = y
				break
	if ultima < 0 or ultima >= img.get_height() - 1:
		return img
	return img.get_region(Rect2i(0, 0, ancho, ultima + 1))


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var lote: String = args[0] if args.size() > 0 else LOTE_POR_DEFECTO
	var entrada := "res://%s/_split/" % lote.trim_suffix("/")
	var d := DirAccess.open(entrada)
	if d == null:
		print("no encuentro ", entrada)
		quit()
		return
	print("lote: ", lote)
	for c in CARPETA.values():
		DirAccess.make_dir_recursive_absolute(
				ProjectSettings.globalize_path("res://arte/%s/" % c[0]))

	var hechos := 0
	var desconocidos := 0
	for f in d.get_files():
		if not f.ends_with(".svg"):
			continue
		var partes := f.replace(".svg", "").split("__")
		if partes.size() != 2 or not CARPETA.has(partes[1]):
			print("  sufijo desconocido, se salta: ", f)
			desconocidos += 1
			continue
		var img := Image.new()
		if img.load_svg_from_string(FileAccess.get_file_as_string(entrada + f), 1.0) != OK:
			print("  FALLO al rasterizar ", f)
			continue
		var capa: Array = CARPETA[partes[1]]
		if partes[1] == "dosel":
			img = _recortar_abajo(img)
		var destino := "res://arte/%s/%s%s.png" % [capa[0], partes[0], capa[1]]
		img.save_png(destino)
		print("  %-20s %-10s %d x %d" % [
				partes[0], partes[1], img.get_width(), img.get_height()])
		hechos += 1

	print("")
	print("%d capas escritas%s" % [
			hechos, "" if desconocidos == 0 else ", %d con sufijo desconocido" % desconocidos])
