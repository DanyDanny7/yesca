extends SceneTree

## Captura una pantalla de juego por bioma, a proporción de teléfono.
##
##   godot --path . --script tools/capturar.gd                 (540x960)
##   godot --path . --script tools/capturar.gd -- 1080 2400     (otra pantalla)
##
## CON ventana, no headless: headless no dibuja nada.
##
## Existe porque el arte no se puede revisar leyendo código ni mirando los PNG
## sueltos: hay que ver el objetivo sobre su fondo, al tamaño real, para saber
## si se distingue. Sale en user://captura/.
##
## Encontró dos fallos que ninguna otra comprobación habría visto: la línea de
## derrota de Asedio cortaba por la mitad de los edificios, y el disco del
## planeta no coincidía con la Tierra dibujada.
const ANCHO := 540
const ALTO := 960
const SALIDA := "user://captura/"

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SALIDA))
	var args := OS.get_cmdline_user_args()
	var ancho: int = int(args[0]) if args.size() > 1 else ANCHO
	var alto: int = int(args[1]) if args.size() > 1 else ALTO
	var sufijo: String = "_%dx%d" % [ancho, alto] if args.size() > 1 else ""
	var vp := SubViewport.new()
	vp.size = Vector2i(ancho, alto)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var main = load("res://main.tscn").instantiate()
	vp.add_child(main)
	await process_frame
	await process_frame

	var vistos := {}
	for i in Niveles.total():
		var bioma := str(Niveles.nivel(i)["bioma"])
		if vistos.has(bioma):
			continue
		vistos[bioma] = true
		main._mode = 0
		main._nivel = i
		main._empezar_partida()
		main._ir_a(3)  # State.PLAYING, por la puerta buena: oculta la interfaz
		for k in 40:
			await process_frame
		var img := vp.get_texture().get_image()
		img.save_png(SALIDA + Arte.slug(bioma) + sufijo + ".png")
		print("  ", bioma)
	print(ProjectSettings.globalize_path(SALIDA))
	quit()
