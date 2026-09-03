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
const CARPETA := {
	"elastica": "elasticas",
	"azulejo": "fondos",
	"rigida": "telones",
}
const LOTE_POR_DEFECTO := "entregas/2026-09-02-ajuste-contrato"


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
				ProjectSettings.globalize_path("res://arte/%s/" % c))

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
		var destino := "res://arte/%s/%s.png" % [CARPETA[partes[1]], partes[0]]
		img.save_png(destino)
		print("  %-20s %-10s %d x %d" % [
				partes[0], partes[1], img.get_width(), img.get_height()])
		hechos += 1

	print("")
	print("%d capas escritas%s" % [
			hechos, "" if desconocidos == 0 else ", %d con sufijo desconocido" % desconocidos])
