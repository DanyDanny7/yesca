extends SceneTree

## Vuelca todo el arte procedural a PNG, para tener de dónde partir al dibujar.
##
##   godot --path . --script tools/exportar_arte.gd
##
## Sale en `arte_exportado/`, que NO es la carpeta que lee el juego. Es a
## propósito: exportar no debe cambiar en nada lo que se ve. Cuando un dibujo
## esté listo se copia a `arte/targets/` o `arte/fondos/` y entonces sí manda.
##
## Lo que se pierde al sustituir una forma por su PNG, y conviene saberlo antes
## de hacerlo: las que se animan por dentro —alas de la abeja, cola del pez,
## titileo de la estrella, ondeo de la llama, cordel del globo— quedan congeladas
## en el instante que capturó el exportador. Una imagen no bate alas.
##
## Tiene que correr CON ventana, no en headless: los targets se capturan
## renderizando de verdad, y sin servidor gráfico no hay nada que capturar. Los
## fondos sí se generan en CPU, así que ésos saldrían igual de las dos formas.

const LADO_TARGET := 512
const SALIDA := "res://arte_exportado/"


func _initialize() -> void:
	_correr()


func _correr() -> void:
	var dir_t := SALIDA + "targets/"
	var dir_f := SALIDA + "fondos/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_t))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_f))

	var n_f := _exportar_fondos(dir_f)
	var n_t := await _exportar_targets(dir_t)

	print("")
	print("%d targets y %d fondos en %s" % [n_t, n_f, SALIDA])
	print("El lienzo de un target mide %.1f radios de ancho (%d px para radio %.1f)." % [
			Arte.LIENZO_EN_RADIOS, LADO_TARGET,
			float(LADO_TARGET) / Arte.LIENZO_EN_RADIOS])
	print("Quien dibuje a mano tiene que respetar esa proporcion o la forma")
	print("saldra de otro tamano que el resto.")
	quit()


# --- targets ---------------------------------------------------------------

## Se renderiza de verdad en un SubViewport en vez de reimplementar las formas
## sobre un Image: así lo exportado es exactamente lo que dibuja el juego, sin
## una segunda versión del código que se desincronice a la primera de cambio.
func _exportar_targets(dir: String) -> int:
	var vp := SubViewport.new()
	vp.size = Vector2i(LADO_TARGET, LADO_TARGET)
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)

	# El radio de dibujo sale del ancho del lienzo, y el de lógica de deshacer
	# la escala visual: así el PNG encaja al volver a entrar por Arte.
	var radio_logico := float(LADO_TARGET) / Arte.LIENZO_EN_RADIOS / Dot.ESCALA_VISUAL

	var hechos := 0
	for forma in Arte.NOMBRE_FORMA.size():
		var variantes := _variantes_de(forma)
		for v in variantes:
			var d := Dot.new()
			d.forma = forma
			d.numero = v
			d.radius = radio_logico
			d.color = _color_de_forma(forma)
			d.position = Vector2(LADO_TARGET, LADO_TARGET) * 0.5
			vp.add_child(d)

			# Dos frames: uno para que el nodo entre y pida dibujarse, otro
			# para que ese dibujo llegue a la textura.
			await process_frame
			await process_frame

			var img := vp.get_texture().get_image()
			var nombre: String = Arte.NOMBRE_FORMA[forma]
			if v > 0:
				nombre += "_" + str(v)
			img.save_png(dir + nombre + ".png")
			print("target  %s" % nombre)
			hechos += 1

			d.queue_free()
			vp.remove_child(d)

	vp.queue_free()
	return hechos


## Las formas que cambian por instancia se exportan una vez por variante.
func _variantes_de(forma: int) -> Array:
	if forma == Dot.Forma.BOLA:
		return range(1, 16)
	if forma == Dot.Forma.GLOBO:
		return range(1, 9)
	return [0]


## El color con el que se ve esa forma en el bioma que la usa.
func _color_de_forma(forma: int) -> Color:
	for nombre in Niveles.PALETAS:
		var pal: Dictionary = Niveles.PALETAS[nombre]
		if int(pal.get("forma", -1)) == forma:
			return Color(str(pal.get("punto", "e8e8f0")))
	return Color("e8e8f0")


# --- fondos ----------------------------------------------------------------

## Los mosaicos se exportan YA TEÑIDOS y sobre su color de fondo.
##
## El generador los produce en blanco con alfa y el tinte se aplica al dibujar,
## pero un PNG blanco sobre transparente se ve vacío en cualquier editor, y peor:
## al copiarlo a `arte/fondos/` saldría blanco, porque a un asset no se le aplica
## tinte. Exportarlo ya compuesto hace que lo que ves sea lo que hay.
func _exportar_fondos(dir: String) -> int:
	var f := Fondo.new()
	var hechos := 0
	for tipo in Arte.NOMBRE_FONDO.size():
		if tipo == Fondo.Tipo.LISO:
			continue
		var tex: ImageTexture = f._mosaico(tipo)
		if tex == null:
			continue
		var patron := tex.get_image()
		var pal := _paleta_de_telon(tipo)
		var img := _componer(patron,
				Color(str(pal.get("fondo", "0a0a12"))),
				Color(str(pal.get("punto", "e8e8f0"))))
		var nombre: String = Arte.NOMBRE_FONDO[tipo]
		img.save_png(dir + nombre + ".png")
		print("fondo   %-16s %d x %d" % [nombre, img.get_width(), img.get_height()])
		hechos += 1
	f.queue_free()
	return hechos


## La primera paleta que use ese telón, sea como fondo o como banda.
func _paleta_de_telon(tipo: int) -> Dictionary:
	for nombre in Niveles.PALETAS:
		var pal: Dictionary = Niveles.PALETAS[nombre]
		if int(pal.get("telon", -1)) == tipo:
			return pal
	for nombre in Niveles.PALETAS:
		var pal: Dictionary = Niveles.PALETAS[nombre]
		if int(pal.get("banda", -1)) == tipo:
			var copia := pal.duplicate()
			copia["punto"] = pal.get("banda_color", "ffffff")
			return copia
	return {}


## Mezcla el patrón (blanco con alfa) teñido, sobre el color de fondo.
func _componer(patron: Image, fondo: Color, tinte: Color) -> Image:
	var ancho := patron.get_width()
	var alto := patron.get_height()
	var img := Image.create(ancho, alto, false, Image.FORMAT_RGBA8)
	img.fill(fondo)
	for y in alto:
		for x in ancho:
			var a := patron.get_pixel(x, y).a * tinte.a
			if a <= 0.0:
				continue
			img.set_pixel(x, y, fondo.lerp(Color(tinte, 1.0), a))
	return img
