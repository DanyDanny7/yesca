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
	var dir_e := SALIDA + "explosiones/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_t))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_f))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_e))

	var n_f := _exportar_fondos(dir_f)
	var n_t := await _exportar_targets(dir_t)
	var n_e := await _exportar_explosiones(dir_e)
	_escribir_referencia(SALIDA)

	print("")
	print("%d targets, %d fondos y %d explosiones en %s" % [n_t, n_f, n_e, SALIDA])
	print("El lienzo de un target mide %.1f radios de ancho (%d px para radio %.1f)." % [
			Arte.LIENZO_EN_RADIOS, LADO_TARGET,
			float(LADO_TARGET) / Arte.LIENZO_EN_RADIOS])
	print("Quien dibuje a mano tiene que respetar esa proporcion o la forma")
	print("saldra de otro tamano que el resto.")
	quit()


## Escribe la hoja de referencia que ve quien va a dibujar.
##
## Va en Markdown y no en un PDF o una imagen de contacto porque GitHub la
## renderiza sola: quien recibe el repo abre la carpeta y ve las 54 piezas con
## su nombre de fichero al lado, sin instalar nada. El nombre de fichero es la
## mitad del encargo —es lo que hace que un dibujo entre en el juego— así que
## tiene que estar pegado a la imagen, no en otro documento.
func _escribir_referencia(dir: String) -> void:
	var t := []
	t.append("# Arte de referencia")
	t.append("")
	t.append("Lo genera `tools/exportar_arte.gd` a partir del dibujo por código.")
	t.append("Esta carpeta **no es** la que lee el juego: es el punto de partida")
	t.append("para redibujar. Lo que sustituye de verdad va en `arte/`.")
	t.append("")
	t.append("## Cómo entregar un dibujo")
	t.append("")
	t.append("1. El **nombre del fichero manda**. `abeja.png` sustituye a la abeja;")
	t.append("   cualquier otro nombre no lo lee nadie.")
	t.append("2. Se deja en la carpeta que le toca, y son cuatro:")
	t.append("")
	t.append("   | carpeta | qué es | ojo con |")
	t.append("   |---|---|---|")
	t.append("   | `arte/targets/` | lo que se revienta | proporción del lienzo |")
	t.append("   | `arte/fondos/` | mosaico que **se repite** | tiene que casar consigo mismo |")
	t.append("   | `arte/telones/` | fondo de **pantalla completa** | pierde el desplazamiento |")
	t.append("   | `arte/explosiones/` | las detonaciones | `cadena`, `fallo`, `impacto` |")
	t.append("")
	t.append("3. PNG con transparencia, SVG, WebP o JPG. Nada más que hacer: el juego")
	t.append("   lo coge al arrancar, y si lo quitas vuelve el dibujo de código.")
	t.append("")
	t.append("### El lienzo de un target")
	t.append("")
	t.append("El lienzo mide **%.1f radios de ancho** y la forma va centrada, ocupando" % Arte.LIENZO_EN_RADIOS)
	t.append("el tercio central. El aire de alrededor no sobra: el cordel del globo")
	t.append("llega a 2.65 radios y las aletas del misil a 1.35, y sin margen se")
	t.append("recortaría justo el detalle que las identifica.")
	t.append("")
	t.append("Estas referencias salen a %d x %d px. Vale cualquier tamaño mientras" % [LADO_TARGET, LADO_TARGET])
	t.append("sea cuadrado y respete esa proporción; si no, la forma saldrá de otro")
	t.append("tamaño que las demás.")
	t.append("")
	t.append("### El color")
	t.append("")
	t.append("Un asset se dibuja **tal cual**. No se tiñe con la paleta del bioma, así")
	t.append("que el color lo eliges tú. Abajo está la paleta de cada bioma por si")
	t.append("quieres seguirla.")
	t.append("")
	t.append("### Lo que se pierde")
	t.append("")
	t.append("Cinco formas se animan por dentro y al sustituirlas quedan **quietas**:")
	t.append("las alas de la abeja, la cola del pez, el titileo de la estrella, el")
	t.append("ondeo de la llama y el cordel del globo. Una imagen no bate alas. No es")
	t.append("un fallo, es lo que cuesta cambiar código por imagen; conviene decidirlo")
	t.append("a conciencia en esas cinco. Lo que **no** se pierde: el giro hacia la")
	t.append("dirección de vuelo y la animación de aparición.")
	t.append("")
	t.append("## Targets")
	t.append("")
	t.append(_tabla(Arte.NOMBRE_FORMA, "targets/", _todas_las_variantes()))
	t.append("")
	t.append("## Explosiones")
	t.append("")
	t.append("Tres, y el nombre del fichero dice cuál es: `cadena` para el tap y cada")
	t.append("eslabón de la cascada, `fallo` para el toque errado, `impacto` para cuando")
	t.append("algo llega a la ciudad o al planeta y se acaba la partida.")
	t.append("")
	t.append("El lienzo mide **%.1f radios**, menos que el de un target porque no hay" % Arte.EXPLOSION_EN_RADIOS)
	t.append("cola, pero más de dos: las esquirlas adelantan al anillo hasta un 28%.")
	t.append("")
	t.append("**Basta una imagen quieta.** El nodo la escala al radio de cada instante")
	t.append("y la desvanece al final, así que el crecimiento y el apagado ya están")
	t.append("puestos; lo que hay que dibujar es el momento de más energía.")
	t.append("")
	t.append(_tabla([], "explosiones/", Arte.NOMBRE_EXPLOSION))
	t.append("")
	t.append("## Fondos en mosaico")
	t.append("")
	t.append("Se repiten, así que **tienen que casar consigo mismos**: una imagen que no")
	t.append("encaje deja una rejilla de costuras por toda la pantalla. Salen aquí ya")
	t.append("compuestos sobre el color de su bioma, que es como se ven.")
	t.append("")
	t.append("Si prefieres pintar el fondo entero en vez de un azulejo, va en")
	t.append("`arte/telones/` con el mismo nombre y manda sobre el mosaico. Se escala")
	t.append("para **cubrir** la pantalla, centrada y sin deformarse, así que conviene")
	t.append("dejar aire en los bordes: en un teléfono más estrecho se recorta por los")
	t.append("lados. Lo que se pierde es el desplazamiento —la nieve cayendo, el río")
	t.append("corriendo, las pavesas subiendo—, porque una imagen que no se repite no")
	t.append("puede moverse sin descubrir su borde.")
	t.append("")
	t.append(_tabla_fondos())
	t.append("")
	t.append("## Paletas por bioma")
	t.append("")
	t.append(_tabla_paletas())
	var f := FileAccess.open(dir + "README.md", FileAccess.WRITE)
	if f != null:
		f.store_string("
".join(t) + "
")
		f.close()
		print("referencia  README.md")


## Los nombres de fichero de todos los targets, variantes incluidas.
func _todas_las_variantes() -> Array:
	var lista: Array = []
	for forma in Arte.NOMBRE_FORMA.size():
		for v in _variantes_de(forma):
			var n: String = Arte.NOMBRE_FORMA[forma]
			if v > 0:
				n += "_" + str(v)
			lista.append(n)
	return lista


## Tabla HTML de cuatro columnas: GitHub la renderiza y las imágenes se ven.
func _tabla(_enum_nombres: Array, sub: String, nombres: Array) -> String:
	var t := "<table>
"
	var col := 0
	for n in nombres:
		if col == 0:
			t += "<tr>"
		t += "<td align=\"center\"><img src=\"%s%s.png\" width=\"96\"><br><code>%s.png</code></td>" % [sub, n, n]
		col += 1
		if col == 4:
			t += "</tr>
"
			col = 0
	if col > 0:
		t += "</tr>
"
	return t + "</table>"


func _tabla_fondos() -> String:
	var nombres: Array = []
	for tipo in Arte.NOMBRE_FONDO.size():
		if tipo == Fondo.Tipo.LISO:
			continue
		nombres.append(Arte.NOMBRE_FONDO[tipo])
	return _tabla([], "fondos/", nombres)


## Qué colores usa cada bioma, para quien quiera respetarlos.
func _tabla_paletas() -> String:
	var t := "| Bioma | Forma | Objetivo | Onda | Fondo |
"
	t += "|---|---|---|---|---|
"
	for nombre in Niveles.PALETAS:
		var pal: Dictionary = Niveles.PALETAS[nombre]
		var forma := int(pal.get("forma", Dot.Forma.CIRCULO))
		t += "| %s | `%s` | `#%s` | `#%s` | `#%s` |
" % [
				nombre, Arte.NOMBRE_FORMA[forma],
				str(pal.get("punto", "")), str(pal.get("onda", "")),
				str(pal.get("fondo", ""))]
	return t


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


## Las tres detonaciones, capturadas en su instante de más energía.
##
## Se dejan crecer de verdad en vez de forzar el radio: el crecimiento tiene un
## frenazo al final —un ease-out cúbico— y las esquirlas van adelantadas a la
## fase, así que un fotograma sintético no se parecería al que se ve jugando.
func _exportar_explosiones(dir: String) -> int:
	var vp := SubViewport.new()
	vp.size = Vector2i(LADO_TARGET, LADO_TARGET)
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)

	var radio := float(LADO_TARGET) / Arte.EXPLOSION_EN_RADIOS

	var hechos := 0
	for tipo in Arte.NOMBRE_EXPLOSION.size():
		var e := Explosion.new()
		e.tipo = tipo
		e.max_radius = radio
		e.color = _color_de_explosion(tipo)
		e.position = Vector2(LADO_TARGET, LADO_TARGET) * 0.5
		vp.add_child(e)

		# Se espera a que termine de crecer, con un tope por si algún día el
		# tiempo de crecimiento cambia y nunca llega.
		var vueltas := 0
		while e.radius < e.max_radius * 0.999 and vueltas < 240:
			await process_frame
			vueltas += 1
		await process_frame

		var img := vp.get_texture().get_image()
		var nombre: String = Arte.NOMBRE_EXPLOSION[tipo]
		img.save_png(dir + nombre + ".png")
		print("explosión  %s" % nombre)
		hechos += 1

		e.queue_free()
		vp.remove_child(e)

	vp.queue_free()
	return hechos


## El color con el que se ve cada detonación jugando.
func _color_de_explosion(tipo: int) -> Color:
	if tipo == Explosion.Tipo.FALLO:
		return Explosion.COLOR_FALLO
	if tipo == Explosion.Tipo.IMPACTO:
		return Color("ff7a3c")
	return Color(str(Niveles.paleta_de("Cielo abierto").get("onda", "8ec5ff")))


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
