class_name Fondo
extends Node2D

## El telón de cada bioma, como mosaico.
##
## El patrón se genera UNA vez en una imagen pequeña que encaja consigo misma, y
## en pantalla se dibuja repetida con una única llamada. Antes se redibujaba
## entero cada frame y costaba un tercio del rendimiento en escritorio —bajar de
## 60 en un teléfono— y bajar el número de hexágonos de 170 a 45 apenas movió la
## aguja: el problema no era la cantidad de figuras sino reemitirlas todas cada
## frame. Con mosaico son cientos de comandos de dibujo menos, siempre.
##
## La animación sale gratis desplazando el mosaico: cuesta lo mismo que tenerlo
## quieto, porque sigue siendo una sola llamada.
##
## Regla que manda sobre cualquier capricho estético: **el fondo no puede
## competir con los círculos**. Alfas muy bajas, escala grande y movimiento
## lento. Lo único que el jugador tiene que localizar a toda velocidad es un
## círculo de nueve píxeles.
##
## Se dibuja detrás de todo y NO se sacude con el campo: un telón que tiembla
## con cada eslabón convierte la pantalla en un mareo.

enum Tipo {
	LISO,       ## nada
	ESTRELLAS,  ## puntos lejanos
	COPOS,      ## nieve cayendo
	CORRIENTE,  ## líneas de agua desplazándose
	CELULAS,    ## manchas orgánicas
	TAPETE,     ## trama diagonal de paño
	PANAL,      ## rejilla hexagonal
	REJILLA,    ## cuadrícula técnica
	HOJAS,      ## siluetas cayendo
	PAVESAS,    ## chispas subiendo
	TRAZAS,     ## pistas de circuito
	ESTELAS,    ## rastros diagonales cayendo
	HORIZONTE,      ## perfil de ciudad con ventanas encendidas
	HORIZONTE_ROTO, ## el mismo perfil, roto y ardiendo
	AURORA,         ## cortinas de luz polar, para la banda de arriba
	AZULEJOS,       ## alicatado de baño
	CONFETI,        ## papelillos de colores
	BANDERINES,     ## guirnalda de fiesta, para la banda de arriba
	PLACAS,         ## chapa remachada
	TIERRA,         ## granos y raíces, vista desde arriba
}

## Adornos que NO se repiten: se dibujan una vez sobre el telón porque su sitio
## en pantalla importa. Una mesa de billar con las troneras repetidas en mosaico
## no sería una mesa.
enum Marco { NADA, MESA, TINA, PLANETA }

## Alto de cada banda, en píxeles.
##
## La ciudad ocupa el tercio inferior de una pantalla de móvil: con bandas bajas
## los edificios salían enanos y se leían como textura, no como ciudad. La
## aurora es mucho más corta porque va arriba y solo tiene que insinuarse.
const ALTO_CIUDAD := 420
const ALTO_AURORA := 190

## En cuántas columnas se ve el azulejo entregado, sea cual sea la pantalla.
##
## Es propiedad del BIOMA, no del fichero. Dibujarlo a su tamaño en píxeles del
## dispositivo hacía que la célula cambiara de tamaño con cada móvil: en 720 de
## ancho entraban cuatro columnas y en 1080 seis, y el mismo fondo pasaba de
## tener células grandes a leerse como un estampado de tela. Cuatro es lo que se
## dibujó y lo que se revisó.
const COLUMNAS_AZULEJO := 4
## Ancho del viewport para el que están medidas las velocidades de deriva.
const ANCHO_BASE := 720.0

## Lado del mosaico. Potencia de dos y divisible por los pasos de todos los
## patrones, que es lo que hace que encajen consigo mismos sin costura.
const LADO := 128

## Los mosaicos se guardan por tipo: generar uno cuesta unos milisegundos y no
## hay motivo para repetirlo cada vez que se entra al mismo bioma.
static var _cache: Dictionary = {}
## Qué telones vienen de un fichero y no del generador.
##
## Importa porque los dos se dibujan con reglas distintas: el patrón generado se
## pinta en blanco y se tiñe con el color del bioma, mientras que un asset se
## respeta tal como lo dibujó quien lo hizo. Es la misma regla que en los
## targets: un asset manda, incluido su color.
static var _es_asset: Dictionary = {}

var tipo: Tipo = Tipo.LISO
var color: Color = Color("ffffff")

var _tex: ImageTexture
var _scroll: Vector2 = Vector2.ZERO
var _deriva: Vector2 = Vector2.ZERO

## Banda inferior, opcional.
##
## Existe porque el mosaico se repite en los DOS ejes, y un horizonte urbano no
## puede repetirse hacia arriba. La banda se repite solo en horizontal y se ancla
## abajo, que es donde tiene sentido una ciudad.
var _tex_banda: ImageTexture
var _tipo_banda: Tipo = Tipo.LISO
## Desplazamiento acumulado de cada banda de bioma.
var _scroll_bandas: Array[float] = [0.0, 0.0]
## Reloj propio del fondo, para lo que se anima solo.
var _reloj: float = 0.0
var _color_banda: Color = Color("ffffff")
## Si los píxeles se envuelven también en vertical. En el mosaico sí; en la
## banda no, o los tejados aparecerían asomando por abajo.
var _wrap_y: bool = true
## Si la banda va arriba (aurora) o abajo (ciudad).
var _banda_arriba: bool = false
var _scroll_banda: float = 0.0

var marco: Marco = Marco.NADA
## Bioma en curso. Es la clave con la que se buscan los assets de fondo.
var bioma: String = ""

## Estrella fugaz: cruza de vez en cuando dejando estela.
var _fugaces: bool = false
var _fugaz_espera: float = 0.0
var _fugaz_avance: float = 1.0
var _fugaz_ini: Vector2 = Vector2.ZERO
var _fugaz_fin: Vector2 = Vector2.ZERO


func configurar(nuevo_tipo: Tipo, nuevo_color: Color,
		banda: Tipo = Tipo.LISO, color_banda: Color = Color("ffffff"),
		nuevo_marco: Marco = Marco.NADA, fugaces: bool = false,
		nuevo_bioma: String = "") -> void:
	bioma = nuevo_bioma
	tipo = nuevo_tipo
	color = nuevo_color
	_color_banda = color_banda
	marco = nuevo_marco
	_fugaces = fugaces
	_fugaz_avance = 1.0
	_fugaz_espera = randf_range(3.0, 7.0)
	_scroll = Vector2.ZERO
	_scroll_banda = 0.0
	_cargar_astros()
	_deriva = _deriva_del_bioma(bioma, tipo)
	_tex = _mosaico(tipo)
	_tipo_banda = banda
	_tex_banda = _mosaico(banda) if banda != Tipo.LISO else null
	_banda_arriba = banda == Tipo.AURORA
	# Con bandas de bioma hay que seguir procesando aunque el telón no derive:
	# el desplazamiento de las bandas es lo único que se mueve en ese caso.
	var con_bandas := Arte.banda_bioma(bioma, 1) != null
	var con_algas := Arte.algas_bioma(bioma)["tex"] != null
	set_process(_deriva != Vector2.ZERO or _fugaces or _banda_arriba
			or con_bandas or con_algas)
	queue_redraw()


## Hacia dónde y a qué velocidad se desplaza el mosaico, en píxeles por segundo.
## La dirección cuenta la historia del bioma sin decir una palabra: la nieve
## cae, las pavesas suben, el río va de lado.
## A qué velocidad corre el azulejo de cada bioma, en píxeles del viewport base
## por segundo. De la tabla de REGLA-FONDOS.md §4.
##
## Va por BIOMA y no por tipo de azulejo. El tipo dice qué se dibuja —células,
## copos, rejilla— y eso no decide a qué ritmo se mueve: dos biomas pueden
## compartir motivo y querer velocidades distintas. Básico corría a (3, −2), o
## sea casi quieto y hacia ARRIBA, cuando su ficha pide bajar a 34.
##
## Los biomas que no están aquí siguen sacando su deriva del tipo, que es lo que
## hacían antes.
const DERIVA_BIOMA := {
	# Básico va en DIAGONAL. Mismo módulo que tenía en vertical -34- repartido
	# entre los dos ejes, así que la velocidad que se percibe no cambia: solo
	# cambia hacia dónde.
	#
	# Y no a 45 grados: un reparto exacto se lee como una diagonal dibujada, y
	# además haría que las dos envolturas coincidieran y el mosaico volviera a
	# su sitio cada pocas baldosas, que se ve como un latido. Con 17 y 29 los dos
	# periodos no cuadran y el fondo no se repite a ojo.
	"basico": Vector2(17.0, 29.0),
	"cielo_abierto": Vector2(0.0, 52.0),
	"invierno": Vector2(0.0, 40.0),
	"rio": Vector2(64.0, 0.0),
}


## La deriva del bioma si la tiene declarada; si no, la de su tipo de azulejo.
func _deriva_del_bioma(nombre: String, t: Tipo) -> Vector2:
	var clave := Arte.slug(nombre)
	if DERIVA_BIOMA.has(clave):
		return DERIVA_BIOMA[clave]
	return _deriva_de(t)


func _deriva_de(t: Tipo) -> Vector2:
	match t:
		Tipo.COPOS: return Vector2(4.0, 16.0)
		Tipo.HOJAS: return Vector2(7.0, 20.0)
		Tipo.PAVESAS: return Vector2(-3.0, -22.0)
		Tipo.CORRIENTE: return Vector2(26.0, 0.0)
		Tipo.CELULAS: return Vector2(3.0, -2.0)
		Tipo.REJILLA: return Vector2(0.0, 9.0)
		_: return Vector2.ZERO


func _process(delta: float) -> void:
	if _banda_arriba:
		# La aurora se desplaza muy despacio: si se moviera al ritmo del telón
		# parecería una cortina corriéndose en vez de luz que ondula.
		_scroll_banda = fposmod(_scroll_banda + delta * 5.0, float(LADO))
	if _fugaces:
		_tick_fugaz(delta)
	# Bandas de bioma: cada una a su velocidad y su sentido. Se envuelve por
	# el ancho de la propia textura, que es su periodo, y no por LADO: las
	# bandas no tienen por qué medir lo mismo que un azulejo.
	for i in BANDAS_MAX:
		var banda := Arte.banda_bioma(bioma, i + 1)
		if banda == null:
			continue
		_scroll_bandas[i] = fposmod(_scroll_bandas[i] + delta * BANDA_VELOCIDAD[i],
			float(banda.get_width()))
	_reloj += delta
	# La deriva va en píxeles del viewport base por segundo, así que se escala
	# con el ancho. Sin esto, en tableta el fondo se arrastra más despacio de lo
	# previsto en relación a lo que se ve.
	_scroll += _deriva * (get_viewport_rect().size.x / ANCHO_BASE) * delta
	# Se envuelve por el PERIODO DEL AZULEJO, no por LADO.
	#
	# Envolver a 128 valía mientras todos los mosaicos los generaba el juego a
	# 128x128. Con azulejos entregados de cualquier tamaño —8, 21, 180, 504—
	# volver a cero cada 128 px salta a un punto distinto del dibujo, y ese salto
	# se ve como un corte cada pocos segundos. Sale una sola vez por vuelta, así
	# que es de los fallos que se notan sin poder señalarlos.
	var per := _periodo_azulejo()
	_scroll.x = fposmod(_scroll.x, per.x)
	_scroll.y = fposmod(_scroll.y, per.y)
	queue_redraw()


## Con qué color se modula un telón: el del bioma si lo generamos nosotros,
## blanco si viene de un fichero.
func _tinte(t: Tipo) -> Color:
	return Color.WHITE if _es_asset.get(t, false) else color


## Dibuja una imagen cubriendo la pantalla entera, centrada y sin deformarla.
##
## Se escala por el lado que más falta haga y se recorta lo que sobre, como el
## `cover` de la web. Estirarla a la fuerza deformaría el dibujo, y encajarla
## entera dejaría franjas vacías a los lados en cuanto la pantalla no tuviera
## exactamente su proporción, que es lo normal entre teléfonos.
## El lecho que se mece, si el bioma lo trae.
##
## Se ancla abajo y se escala por el ancho, igual que el telón, y NUNCA se
## estira: es una pieza con sitio, solo que animada.
##
## Sin desfase por instancia, al revés que los targets: aquí la tira ya trae el
## desfase dentro, hoja por hoja.
func _dibujar_algas(r: Vector2) -> void:
	# Una sola alga repetida manda sobre el lecho horneado: se controla cuántas
	# hay y cuánto se retrasa cada una.
	var suelta := Arte.alga_bioma(bioma)
	if suelta["tex"] != null:
		_dibujar_algas_sueltas(r, suelta)
		return

	var a := Arte.algas_bioma(bioma)
	var tex: Texture2D = a["tex"]
	if tex == null:
		return
	var n: int = a["fotogramas"]
	var ancho := tex.get_width() / maxi(1, n)
	var i := 0
	if n > 1:
		var t := fposmod(_reloj / CICLO_ALGAS, 1.0)
		i = clampi(int(t * float(n)), 0, n - 1)
	var esc := r.x / float(ancho)
	var alto := float(tex.get_height()) * esc
	draw_texture_rect_region(tex,
			Rect2(Vector2(0.0, r.y - alto), Vector2(r.x, alto)),
			Rect2(float(i * ancho), 0.0, float(ancho), float(tex.get_height())))


## Un alga sola, plantada a lo largo del lecho y cada una en otro momento.
##
## El desfase crece hacia la derecha, así que el mecido viaja aguas abajo igual
## que el azulejo. Si todas se doblaran a la vez, el lecho entero respiraría
## como un solo bicho.
func _dibujar_algas_sueltas(r: Vector2, a: Dictionary) -> void:
	var tex: Texture2D = a["tex"]
	var n: int = a["fotogramas"]
	var ancho := tex.get_width() / maxi(1, n)
	var alto := float(tex.get_height())
	# Se escala igual que el telón, pero pasando por las unidades de arte: el
	# alga y el lecho no vienen rasterizados a la misma resolución.
	var por_unidad := r.x / ARTE_ANCHO
	var esc := por_unidad * (ALGA_ANCHO_UNIDADES / float(ancho))
	var paso := PASO_ALGA * por_unidad
	var base := r.y - ALGA_BASE * por_unidad
	var w := float(ancho) * esc
	var h := alto * esc
	var vuelta := _reloj / CICLO_ALGAS
	var k := 0
	var x := -paso * 0.5
	while x < r.x:
		var t := fposmod(vuelta + float(k) * DESFASE_ALGA, 1.0)
		var i := clampi(int(t * float(n)), 0, n - 1)
		# Cada copia crece o mengua un poco, con un valor propio y estable.
		# Sin esto se ve que es la misma estampada doce veces; con esto se
		# lee como un lecho. La variación sale de una función del índice y
		# no de randf(), o cambiaría en cada fotograma y las algas darían
		# saltos de tamaño.
		var v := sin(float(k) * 2.399963) * 0.5 + 0.5
		var mide := lerpf(ALGA_ESCALA_MIN, ALGA_ESCALA_MAX, v)
		var ww := w * mide
		var hh := h * mide
		draw_texture_rect_region(tex,
				Rect2(Vector2(x - (ww - w) * 0.5, base - hh), Vector2(ww, hh)),
				Rect2(float(i * ancho), 0.0, float(ancho), alto))
		x += paso * lerpf(0.82, 1.18, fposmod(v * 3.7, 1.0))
		k += 1


func _cubrir(tex: Texture2D, r: Vector2) -> void:
	var t := Vector2(tex.get_size())
	if t.x <= 0.0 or t.y <= 0.0:
		return
	var escala := maxf(r.x / t.x, r.y / t.y)
	var tam := t * escala
	draw_texture_rect(tex, Rect2((r - tam) * 0.5, tam), false)


## Lee el manifiesto de astros del bioma. Sin manifiesto, la capa no existe.
##
## Es la cuarta capa del fondo y la única cuyas piezas NO se deforman: van
## centradas en una coordenada y escaladas por el ancho con la MISMA escala en
## los dos ejes. Un sol dentro de la elástica se achata con ella —un 10% en un
## móvil 1:2,17 y mucho más en tableta— y un sol achatado deja de ser un sol.
## Tampoco podían ir en el azulejo, porque el azulejo se repite y un sol no.
func _cargar_astros() -> void:
	_astros.clear()
	if bioma.is_empty():
		return
	var ruta := RUTA_ASTROS % Arte.slug(bioma)
	if not FileAccess.file_exists(ruta):
		return
	var datos = JSON.parse_string(FileAccess.get_file_as_string(ruta))
	if typeof(datos) != TYPE_DICTIONARY:
		return
	for a in datos.get("astros", []):
		if typeof(a) != TYPE_DICTIONARY:
			continue
		_astros.append({
			"pieza": str(a.get("pieza", "")),
			"x": float(a.get("x", 0.0)),
			"alto": float(a.get("alto", 0.0)),
			"ancho": float(a.get("ancho", 0.0)),
			"alfa": float(a.get("alfa", 1.0)),
		})


## Los astros, entre la elástica y el azulejo.
##
## Van DEBAJO del azulejo a propósito: las estelas de los meteoros tienen que
## pasar por delante de un planeta lejano, no por detrás.
##
## Y no se excluyen con el telón. La regla de «si existe el telón se dibuja y se
## retorna» es entre telón y banda; los astros son una lista aparte y se pintan
## siempre.
func _dibujar_astros(r: Vector2) -> void:
	if _astros.is_empty():
		return
	var esc := _escala_arte(r)
	for a in _astros:
		var tex := Arte.astro(str(a["pieza"]))
		if tex == null:
			continue
		# Una sola escala para los dos ejes: redondo en móvil y redondo en
		# tableta. El alto se mide sobre el borde INFERIOR, la misma convención
		# que ARTE_TEJADO y ARTE_PLANETA.
		var lado := float(a["ancho"]) * esc
		var centro := Vector2(float(a["x"]) * esc, r.y - float(a["alto"]) * esc)
		draw_texture_rect(tex,
				Rect2(centro - Vector2(lado, lado) * 0.5, Vector2(lado, lado)),
				false, Color(1.0, 1.0, 1.0, float(a["alfa"])))


## La línea de contacto, pulsando.
##
## En Asedio es la silueta de los 22 tramos; en Lluvia, la circunferencia del
## planeta. No hay una tercera forma porque no hay un tercer bioma donde se
## pierda por tocar el escenario.
func _dibujar_amenaza(r: Vector2) -> void:
	var col := Color(amenaza_color, amenaza)
	var grosor := AMENAZA_TRAZO * _escala_arte(r)
	if _es_planeta():
		draw_arc(planeta_centro(r), planeta_radio(r), 0.0, TAU, 64, col, grosor, true)
		return
	var tramos := _tramos_silueta()
	if tramos.is_empty():
		return
	var esc := _escala_arte(r)
	for t in tramos:
		var y := r.y - t.z * esc
		draw_line(Vector2(t.x * esc, y), Vector2(t.y * esc, y), col, grosor, true)


## Si lo que se defiende en este bioma es el planeta y no una franja.
func _es_planeta() -> bool:
	return marco == Marco.PLANETA


## Cada cuántos píxeles se repite el mosaico en curso.
##
## El azulejo entregado manda sobre el generado, y si no hay ninguno vale LADO,
## que es lo que mide el que fabrica el propio juego.
func _periodo_azulejo() -> Vector2:
	if Arte.fondo_bioma(bioma) != null:
		var lado := _lado_baldosa()
		return Vector2(lado, lado)
	return Vector2(LADO, LADO)


## Cuánto mide en pantalla una baldosa del azulejo entregado.
##
## Se redondea a entero: cada célula está dibujada nueve veces en el fichero
## —una por vecino— para que las que cruzan el borde continúen en la baldosa de
## al lado, y eso solo encaja si el mosaico se repite EXACTAMENTE cada lado. Con
## medio píxel de sobra o de menos aparece la costura.
func _lado_baldosa() -> float:
	var ancho := get_viewport_rect().size.x
	return maxf(1.0, round(ancho / float(COLUMNAS_AZULEJO)))


func _draw() -> void:
	var r := get_viewport_rect().size

	# El fondo del bioma va en dos capas, y la separación no es un capricho: una
	# se puede repetir y la otra no. El azulejo cubre la pantalla y se desplaza;
	# la composición se ancla abajo, donde están las piezas que tienen sitio
	# fijo. Aplastarlas juntas en una sola imagen obligaría a estirar la bañera.
	var forma_pantalla := Arte.variante_pantalla(r)
	var azulejo := Arte.fondo_bioma(bioma)
	var elastica := Arte.elastica_bioma(bioma, forma_pantalla)
	var capa := Arte.telon_bioma(bioma, forma_pantalla)

	# El orden, de abajo arriba: elástica, azulejo, rígida. La elástica es la
	# BASE —el degradado del cielo, el agua del fondo— y por eso va primero:
	# el azulejo lleva la textura y se pinta encima. Al revés, un azulejo con
	# color propio taparía la base y la capa no serviría de nada.
	#
	# Se estira a pantalla completa sin conservar proporción, que es
	# exactamente para lo que se declara elástica: deformarla es usarla bien,
	# no un apaño. Es la pieza que hace que cualquier proporción se llene sin
	# recortar nada que importe.
	if elastica != null:
		draw_texture_rect(elastica, Rect2(Vector2.ZERO, r), false)

	# Y encima, los astros: la cuarta capa. Sol, planetas y estrellas no pueden
	# ir dentro de la elástica porque se achatarían con ella, ni en el azulejo
	# porque el azulejo se repite y un sol no se repite.
	_dibujar_astros(r)

	# Las bandas van entre la elástica y el azulejo. El orden importa y no es
	# arbitrario: la aurora está a cien kilómetros y la nieve a diez metros, así
	# que los copos tienen que caer POR DELANTE de la aurora.
	for i in BANDAS_MAX:
		var banda := Arte.banda_bioma(bioma, i + 1)
		if banda == null:
			continue
		var ancho := float(banda.get_width())
		draw_texture_rect(banda,
				Rect2(Vector2(-_scroll_bandas[i], 0.0),
						Vector2(r.x + ancho, float(banda.get_height()))),
				true)

	if azulejo != null:
		# Se ESCALA para que quepan cuatro columnas, no se repite más veces. La
		# repetición se hace en el espacio del propio azulejo y de ahí se escala
		# entero: draw_texture_rect repite al tamaño de la textura y no a uno
		# cualquiera, así que la escala tiene que venir de la transformación.
		var lado := _lado_baldosa()
		var esc := lado / maxf(1.0, float(azulejo.get_width()))
		var per := Vector2(azulejo.get_size())
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(esc, esc))
		# El margen de más tiene que ser el periodo del propio azulejo: con uno
		# menor, el desplazamiento descubriría el borde antes de repetir.
		draw_texture_rect(azulejo,
				Rect2(_scroll / esc - per, r / esc + per * 2.0), true)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	elif _tex == null and _tex_banda == null and capa == null and elastica == null:
		return

	# Una sola llamada para todo el telón. Se dibuja un mosaico de más en cada
	# lado para que el desplazamiento no descubra el borde.
	if _tex != null and azulejo == null:
		draw_texture_rect(
			_tex,
			Rect2(_scroll - Vector2(LADO, LADO), r + Vector2(LADO, LADO) * 2.0),
			true,
			_tinte(tipo))

	# La banda va anclada a un borde y con la altura EXACTA de su textura: así
	# se repite en horizontal y no en vertical.
	# La composición del bioma ya trae su banda y su marco dibujados, así que
	# los procedurales se callan: pintarlos encima dejaría dos ciudades.
	# El aviso de amenaza va encima del telón y debajo de los targets, que es
	# donde está la línea que marca.
	if amenaza > 0.0:
		_dibujar_amenaza(r)

	if capa != null:
		# Las algas van DEBAJO del telón: el montículo de limo les tapa la base
		# y parece que salen del fondo.
		_dibujar_algas(r)
		var esc := r.x / float(capa.get_width())
		var alto := float(capa.get_height()) * esc
		# Si falta POCO para cubrir la pantalla, se estira ese poco.
		#
		# Sin esto, en un 16:9 queda una franja de azulejo del 9% justo encima
		# de la composición, y una franja delgada de otro color se lee como un
		# error de montaje, no como cielo. Un estirado del 12% no lo ve nadie;
		# a partir de ahí sí se nota, y entonces es mejor que se vea el azulejo
		# y que el arte esté diseñado contando con él.
		if alto < r.y and alto > r.y * (1.0 - ESTIRADO_MAX):
			alto = r.y
		draw_texture_rect(capa, Rect2(Vector2(0.0, r.y - alto), Vector2(r.x, alto)), false)
		if _fugaces and _fugaz_avance < 1.0:
			_dibujar_fugaz()
		return

	if _tex_banda != null:
		var alto := float(_tex_banda.get_height())
		var y := 0.0 if _banda_arriba else r.y - alto
		var x := -_scroll_banda if _banda_arriba else 0.0
		draw_texture_rect(
			_tex_banda,
			Rect2(Vector2(x, y), Vector2(r.x + float(LADO), alto)),
			true,
			_color_banda if not _es_asset.get(_tipo_banda, false) else Color.WHITE)

	if marco == Marco.MESA:
		_dibujar_mesa(r)
	elif marco == Marco.TINA:
		_dibujar_tina(r)
	elif marco == Marco.PLANETA:
		_dibujar_planeta(r)
	if _fugaces and _fugaz_avance < 1.0:
		_dibujar_fugaz()


# --- adornos que no se repiten ---------------------------------------------

## Mesa de billar: banda de madera y las seis troneras.
##
## Va aparte del mosaico porque su sitio importa: las troneras están en las
## cuatro esquinas y a media altura de los lados largos, y eso no se puede
## repetir en baldosas. Se dibujan en oscuro explícito, no con el color del
## bioma: una tronera es un agujero, y un agujero no emite luz.
func _dibujar_mesa(r: Vector2) -> void:
	var margen := 26.0
	var banda := Color(0.34, 0.2, 0.1, 0.5)
	var paño := Color(1, 1, 1, 0.05)
	draw_rect(Rect2(margen * 0.4, margen * 0.4, r.x - margen * 0.8, r.y - margen * 0.8),
			banda, false, margen * 0.55)
	draw_rect(Rect2(margen, margen, r.x - margen * 2.0, r.y - margen * 2.0),
			paño, false, 2.0)

	var hoyo := 21.0
	var negro := Color(0.02, 0.03, 0.02, 0.92)
	var borde := Color(0.5, 0.42, 0.3, 0.4)
	for pos in [
			Vector2(margen, margen), Vector2(r.x - margen, margen),
			Vector2(margen, r.y * 0.5), Vector2(r.x - margen, r.y * 0.5),
			Vector2(margen, r.y - margen), Vector2(r.x - margen, r.y - margen)]:
		draw_circle(pos, hoyo, negro)
		draw_arc(pos, hoyo, 0.0, TAU, 24, borde, 2.0, true)


## Ancho del lienzo en el que se componen los fondos. Solo el ancho: la altura
## no aparece en ninguna cuenta, y es a propósito.
##
## La composición se escala por el ancho y se ancla abajo, así que todo lo que
## importa se puede medir DESDE EL BORDE INFERIOR. Con eso, el lienzo puede
## crecer a lo alto —y va a crecer, para que no queden huecos en los móviles
## alargados— sin que ninguna de estas cifras deje de valer.
const ARTE_ANCHO := 208.0
## Tejado más alto de la ciudad de Asedio, en unidades sobre el borde inferior.
##
## Se toma el MÁS ALTO y no una media: con la media, un misil atravesaría la
## parte de arriba de los edificios altos antes de contar como impacto, y eso se
## lee como que el juego está roto. Disparar un poco antes sobre un hueco entre
## edificios se lee, en cambio, como el espacio aéreo de la ciudad.
const ARTE_TEJADO := 104.0
## El perfil de la ciudad de Asedio, como lista de tramos [x0, x1, alto].
##
## ARTE_TEJADO es el tejado MÁS ALTO, el de la torre de la izquierda. Usado como
## recta, toda la ciudad tenía ese techo: un misil que cruzaba por x=105 estallaba
## a 104 de alto cuando el edificio de debajo mide 31. Setenta y tres units de
## cielo entre la explosión y lo que supuestamente había tocado.
##
## Es el mismo error que ya se corrigió en Lluvia de meteoros —el contacto es la
## curva, no una línea— con una vuelta más: aquí el borde no es una curva sino
## una escalera de trece edificios.
##
## ARTE_TEJADO no desaparece: sigue siendo el máximo del perfil y vale para
## encuadrar y descartar rápido. Lo que deja de ser es el contacto.
const RUTA_SILUETA := "res://datos/asedio_silueta.json"
## Manifiesto de la capa de astros de cada bioma, si lo tiene.
const RUTA_ASTROS := "res://datos/%s_astros.json"

## Las colocaciones del bioma en curso: pieza, x, alto, ancho y alfa.
var _astros: Array[Dictionary] = []

## El aviso de amenaza: cuánto pulsa la línea de contacto, de 0 a 1, y de qué
## color. Lo pone Main, que es quien sabe si hay un target cerca.
##
## Sin arco no hay crítico: hay AMENAZA. En estos dos biomas no se pierde por
## tiempo, así que lo que avisa no puede ser un arco que se vacía; lo que avisa
## es la propia cosa que te va a matar. Se dibuja en el mundo y no en el HUD
## porque es geometría del escenario, y usa la que ya está en el contrato: la
## silueta de la ciudad y el radio del planeta. Si el dibujo cambia, el aviso se
## mueve con él sin tocar nada.
var amenaza: float = 0.0
var amenaza_color := Color.WHITE
## Grosor del trazo del aviso, en units del lienzo.
const AMENAZA_TRAZO := 3.0

## Los tramos, cargados una vez. Vacío mientras no se pidan.
static var _silueta: Array[Vector3] = []
static var _silueta_leida := false
## El planeta de Lluvia de meteoros: x desde la izquierda, y sobre el borde
## inferior, y radio. La y es NEGATIVA a propósito: el centro cae por debajo del
## borde, así que solo se ve un casquete y se lee como un mundo, no como una
## pelota.
const ARTE_PLANETA := Vector3(26.0, -8.0, 96.0)
## Cuánto tarda una vuelta completa del mecido de las algas, en segundos.
##
## Más lento que el coleo del pez, que es 1.1: una planta se mece, no se agita.
## Pero 2.6 se leía como agua parada, no como corriente.
const CICLO_ALGAS := 1.8
## Ancho del lienzo de un cuadro del alga, en unidades de arte.
##
## Hace falta porque cada pieza viene rasterizada a su propia resolución: el
## telón a 3x -624 px para 208 unidades- y el alga a 2x. Escalando por píxeles,
## como se hacía antes con un 540 mágico heredado del alga vieja, la nueva salía
## al 77% de su tamaño y se quedaba enterrada en el lecho. Pasando por unidades,
## una entrega futura a otra resolución sale del tamaño correcto sin tocar nada.
const ALGA_ANCHO_UNIDADES := 36.0
## A qué altura sobre el borde inferior se planta la base del alga, en unidades.
##
## No en el suelo de la pantalla: el lecho de Río sube hasta 38,7 unidades y se
## dibuja ENCIMA, así que un alga plantada abajo queda entera detrás. Plantada a
## 27 la base queda enterrada unas once unidades —que es lo que pide la entrega,
## que el limo le tape el arranque— y el resto asoma.
const ALGA_BASE := 27.0
## Cada cuántas unidades se planta un alga cuando se repite una sola.
const PASO_ALGA := 17.7
## Cuánto se retrasa cada alga respecto a la de su izquierda, en vueltas.
##
## No es una fracción entera a propósito: con 1/2 o 1/4 las algas volverían a
## coincidir cada pocas copias y se vería la repetición. Y el retraso va creciendo
## hacia la derecha, así que el mecido VIAJA aguas abajo, en el mismo sentido que
## corre el azulejo.
const DESFASE_ALGA := 0.37
## Entre qué tamaños se planta cada alga. El máximo es 1.0 —el alga dibujada a
## su tamaño— y hacia abajo hay margen: una mata donde todas midan igual se lee
## como una estampa repetida, y hacia arriba solo se vería el pixelado.
const ALGA_ESCALA_MIN := 0.58
const ALGA_ESCALA_MAX := 1.0

## Cuántas bandas puede llevar un bioma.
##
## Dos, y no por límite técnico: con dos capas a velocidades distintas los
## máximos de una caen sobre los huecos de la otra y el brillo late en el sitio.
## Con una se ve una cortina corriéndose de lado, y con tres no se gana nada que
## el ojo pueda distinguir.
const BANDAS_MAX := 2
## A qué velocidad se desplaza cada banda, en píxeles por segundo.
##
## Sentidos opuestos y valores primos entre sí, para que el patrón conjunto tarde
## en repetirse: 5 y 3 dan un ciclo completo de seis minutos. Si fueran múltiplos
## volverían a coincidir enseguida y se vería el bucle.
const BANDA_VELOCIDAD := [5.0, -3.0]

## Cuánto se puede estirar la composición para cubrir la pantalla entera.
##
## Es la única deformación que se permite, y va acotada a propósito: por debajo
## de este umbral nadie la ve, y por encima el arte se nota aplastado. Cuando no
## llega, no se fuerza: se deja ver el azulejo por arriba, que es cielo, y el
## arte se diseña contando con eso.
const ESTIRADO_MAX := 0.12


## Cuánto mide en pantalla una unidad del lienzo del arte.
##
## La composición se dibuja escalada por el ancho y anclada abajo, así que una
## unidad vale lo mismo en los dos ejes y el borde inferior siempre coincide.
func _escala_arte(r: Vector2) -> float:
	return r.x / ARTE_ANCHO


## Dónde está el planeta y cuánto ocupa.
##
## Vive aquí porque lo DIBUJA Fondo y lo COMPRUEBA Main: es la frontera entre lo
## que se ve y la derrota. Si cada uno calculara su versión, bastaría con
## retocar el dibujo para que el impacto dejara de coincidir con el borde
## visible, y el jugador perdería por tocar algo que ya no estaba ahí.
##
## Justo eso pasó al entrar el arte nuevo: el disco calculado quedaba más
## pequeño y más a la izquierda que la Tierra dibujada. Por eso ahora las cifras
## salen del propio SVG del fondo cuando hay asset, y solo se cae al cálculo
## viejo si el bioma sigue dibujado por código.
func planeta_centro(r: Vector2) -> Vector2:
	if Arte.telon_bioma(bioma) != null:
		var e := _escala_arte(r)
		return Vector2(ARTE_PLANETA.x * e, r.y - ARTE_PLANETA.y * e)
	return Vector2(r.x * 0.06, r.y * 1.06)


func planeta_radio(r: Vector2) -> float:
	if Arte.telon_bioma(bioma) != null:
		return ARTE_PLANETA.z * _escala_arte(r)
	return minf(r.x, r.y) * 0.40


## Altura de la franja de abajo que cuenta como ciudad, en píxeles.
##
## Es el MÁXIMO del perfil, así que sirve para encuadrar y para descartar rápido,
## no para decidir el contacto. Para eso está altura_contacto().
func altura_ciudad(r: Vector2, por_defecto: float) -> float:
	if Arte.telon_bioma(bioma) != null:
		return ARTE_TEJADO * _escala_arte(r)
	return por_defecto


## A qué altura toca la ciudad bajo la HUELLA de un target, en píxeles.
##
## Se toma el máximo de los tramos que solapan la huella y no el tramo del
## centro: con el centro solo, un target de 48 px podría colar media silueta por
## el canto de un edificio y estallar por detrás de él.
##
## Sin perfil cargado se cae a la franja plana de siempre, que es lo que hacen
## los biomas de defensa que no tienen ciudad dibujada.
func altura_contacto(r: Vector2, x_izq: float, x_der: float,
		por_defecto: float) -> float:
	if Arte.telon_bioma(bioma) == null:
		return por_defecto
	var tramos := _tramos_silueta()
	if tramos.is_empty():
		return ARTE_TEJADO * _escala_arte(r)
	var esc := _escala_arte(r)
	var u_izq := x_izq / esc
	var u_der := x_der / esc
	var alto := 0.0
	for t in tramos:
		# t = (x0, x1, alto). Solapa si empieza antes de que acabe la huella y
		# acaba después de que empiece.
		if t.y > u_izq and t.x < u_der:
			alto = maxf(alto, t.z)
	return alto * esc


## El perfil, leído una vez por ejecución.
func _tramos_silueta() -> Array[Vector3]:
	if _silueta_leida:
		return _silueta
	_silueta_leida = true
	if not FileAccess.file_exists(RUTA_SILUETA):
		return _silueta
	var datos = JSON.parse_string(FileAccess.get_file_as_string(RUTA_SILUETA))
	if typeof(datos) != TYPE_DICTIONARY:
		return _silueta
	for t in datos.get("tramos", []):
		if typeof(t) == TYPE_ARRAY and t.size() >= 3:
			_silueta.append(Vector3(float(t[0]), float(t[1]), float(t[2])))
	return _silueta


## La Tierra, abajo a la izquierda.
##
## Va como marco y no como mosaico por lo mismo que la mesa de billar: un
## planeta repetido en baldosas no es un planeta.
func _dibujar_planeta(r: Vector2) -> void:
	var c := planeta_centro(r)
	var rad := planeta_radio(r)

	# Atmósfera: dos aros muy tenues por fuera del borde. Es lo que separa un
	# planeta de un círculo azul.
	draw_arc(c, rad * 1.06, 0.0, TAU, 72, Color(0.45, 0.78, 1.0, 0.10), rad * 0.14, true)
	draw_arc(c, rad * 1.01, 0.0, TAU, 72, Color(0.55, 0.85, 1.0, 0.22), rad * 0.05, true)

	# Océano.
	draw_circle(c, rad, Color("14386f"))

	# Continentes: masas deformadas en posiciones fijas. Fijas y no aleatorias
	# porque la Tierra tiene que ser la misma cada vez que entras al nivel.
	var tierra := Color("2f8a52")
	_masa(c, rad, -0.55, 0.42, 0.46, tierra)
	_masa(c, rad, 0.35, 0.60, 0.34, tierra)
	_masa(c, rad, 1.45, 0.50, 0.30, tierra.darkened(0.12))
	_masa(c, rad, 2.55, 0.66, 0.26, tierra)
	# Casquete polar, arriba del todo.
	_masa(c, rad, -PI * 0.5, 0.86, 0.30, Color("dff0f7"))

	# Luz por arriba a la derecha, que es de donde vienen los meteoros: el
	# borde iluminado dice dónde está el sol sin dibujar el sol.
	draw_arc(c, rad * 0.96, -PI * 0.55, PI * 0.12, 24, Color(1, 1, 1, 0.16), rad * 0.07, true)


## Una masa continental: polígono deformado a una distancia y ángulo del centro.
func _masa(c: Vector2, rad: float, ang: float, dist: float, tam: float, tinte: Color) -> void:
	var centro := c + Vector2.from_angle(ang) * rad * dist
	var pts := PackedVector2Array()
	var n := 13
	for i in n:
		var a := TAU * float(i) / float(n)
		var rr := rad * tam * (0.72 + 0.36 * sin(a * 3.0 + ang * 4.0) * cos(a * 2.0 + ang))
		var punto := centro + Vector2(cos(a) * rr, sin(a) * rr)
		# Recortado al disco: un continente no se sale del planeta.
		if punto.distance_to(c) > rad * 0.985:
			punto = c + (punto - c).normalized() * rad * 0.985
		pts.append(punto)
	draw_colored_polygon(pts, tinte)


## Bañera: silueta redondeada abajo, con patas, grifo y línea de agua.
##
## Va como marco y no como mosaico por lo mismo que la mesa de billar: una
## bañera repetida en baldosas no es una bañera.
func _dibujar_tina(r: Vector2) -> void:
	var alto := 190.0
	var margen := 34.0
	var arriba := r.y - alto
	var linea := Color(1, 1, 1, 0.16)
	var agua := Color(0.45, 0.85, 1.0, 0.1)

	# Cuerpo.
	draw_rect(Rect2(margen, arriba, r.x - margen * 2.0, alto - 34.0), agua)
	draw_rect(Rect2(margen, arriba, r.x - margen * 2.0, alto - 34.0), linea, false, 3.0)
	# Borde superior, más grueso: es el canto de la bañera.
	draw_line(Vector2(margen - 10.0, arriba), Vector2(r.x - margen + 10.0, arriba),
			Color(1, 1, 1, 0.28), 6.0)

	# Patas.
	for x in [margen + 34.0, r.x - margen - 34.0]:
		draw_rect(Rect2(x - 9.0, r.y - 34.0, 18.0, 26.0), linea)

	# Grifo, arriba a la derecha.
	var gx := r.x - margen - 54.0
	draw_line(Vector2(gx, arriba - 46.0), Vector2(gx, arriba - 10.0), linea, 5.0)
	draw_line(Vector2(gx, arriba - 46.0), Vector2(gx - 26.0, arriba - 46.0), linea, 5.0)

	# Espuma: una hilera de arcos sobre la línea de agua.
	var x := margen + 12.0
	while x < r.x - margen - 12.0:
		draw_arc(Vector2(x, arriba + 6.0), 13.0, PI, TAU, 10, Color(1, 1, 1, 0.14), 2.0, true)
		x += 21.0


## Una estrella fugaz cada pocos segundos. Cruza en diagonal y deja estela.
func _tick_fugaz(delta: float) -> void:
	if _fugaz_avance < 1.0:
		_fugaz_avance = minf(1.0, _fugaz_avance + delta * 1.3)
		return
	_fugaz_espera -= delta
	if _fugaz_espera > 0.0:
		return
	_fugaz_espera = randf_range(4.0, 9.0)
	_fugaz_avance = 0.0
	var r := get_viewport_rect().size
	# Sale de arriba y cruza hacia un lado, siempre en diagonal descendente.
	var desde_izq := randf() < 0.5
	_fugaz_ini = Vector2(randf_range(-0.1, 0.5) * r.x if desde_izq
			else randf_range(0.5, 1.1) * r.x, randf_range(-0.05, 0.25) * r.y)
	var largo := r.x * randf_range(0.55, 0.9)
	_fugaz_fin = _fugaz_ini + Vector2(largo if desde_izq else -largo, largo * 0.45)


func _dibujar_fugaz() -> void:
	var cabeza := _fugaz_ini.lerp(_fugaz_fin, _fugaz_avance)
	# La estela se dibuja como tramos con alfa decreciente: cuesta seis líneas y
	# se lee mejor que un degradado real.
	var tramos := 6
	var largo_estela := 0.22
	for i in tramos:
		var t0 := clampf(_fugaz_avance - largo_estela * float(i) / float(tramos), 0.0, 1.0)
		var t1 := clampf(_fugaz_avance - largo_estela * float(i + 1) / float(tramos), 0.0, 1.0)
		if is_equal_approx(t0, t1):
			continue
		var desvanece := (1.0 - float(i) / float(tramos)) * (1.0 - _fugaz_avance * 0.35)
		draw_line(_fugaz_ini.lerp(_fugaz_fin, t0), _fugaz_ini.lerp(_fugaz_fin, t1),
				Color(color, 0.5 * desvanece), 2.6 - 0.3 * float(i), true)
	draw_circle(cabeza, 2.6, Color(color, 0.7 * (1.0 - _fugaz_avance * 0.5)))


# --- generación del mosaico ------------------------------------------------

func _mosaico(t: Tipo) -> ImageTexture:
	if t == Tipo.LISO:
		return null
	if _cache.has(t):
		return _cache[t]

	# Un asset sustituye al patrón generado. Tiene que ser tileable por su
	# cuenta: aquí se repite sin más, y una imagen que no case consigo misma
	# deja una rejilla de costuras visible por toda la pantalla.
	var propio := Arte.fondo(t)
	if propio != null:
		var tex_propia := ImageTexture.create_from_image(propio.get_image())
		_cache[t] = tex_propia
		_es_asset[t] = true
		return tex_propia

	var banda := t in [Tipo.HORIZONTE, Tipo.HORIZONTE_ROTO, Tipo.AURORA, Tipo.BANDERINES]
	_wrap_y = not banda
	var alto := LADO
	if t == Tipo.AURORA or t == Tipo.BANDERINES:
		alto = ALTO_AURORA
	elif banda:
		alto = ALTO_CIUDAD
	var img := Image.create(LADO, alto, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 0))
	# Semilla fija: el mosaico de un bioma tiene que ser siempre el mismo, o el
	# fondo cambiaría de dibujo cada vez que se entra al nivel.
	var rnd := RandomNumberGenerator.new()
	rnd.seed = 20260830 + int(t)

	match t:
		Tipo.ESTRELLAS: _gen_puntos(img, rnd, 14, 1.0, 2.2, 0.10)
		Tipo.COPOS: _gen_puntos(img, rnd, 10, 1.2, 1.8, 0.11)
		Tipo.PAVESAS: _gen_puntos(img, rnd, 12, 1.0, 2.0, 0.10)
		Tipo.HOJAS: _gen_hojas(img, rnd)
		Tipo.CELULAS: _gen_celulas(img, rnd)
		Tipo.CORRIENTE: _gen_corriente(img)
		Tipo.TAPETE: _gen_tapete(img)
		Tipo.REJILLA: _gen_rejilla(img)
		Tipo.PANAL: _gen_panal(img)
		Tipo.TRAZAS: _gen_trazas(img, rnd)
		Tipo.ESTELAS: _gen_estelas(img)
		Tipo.HORIZONTE: _gen_horizonte(img, rnd, false)
		Tipo.HORIZONTE_ROTO: _gen_horizonte(img, rnd, true)
		Tipo.AURORA: _gen_aurora(img, rnd)
		Tipo.AZULEJOS: _gen_azulejos(img)
		Tipo.CONFETI: _gen_confeti(img, rnd)
		Tipo.BANDERINES: _gen_banderines(img)
		Tipo.PLACAS: _gen_placas(img)
		Tipo.TIERRA: _gen_tierra(img, rnd)

	var tex := ImageTexture.create_from_image(img)
	_cache[t] = tex
	return tex


## Pinta un píxel con envoltura y quedándose con el alfa más alto.
##
## La envoltura es lo que hace que el mosaico encaje: una figura que se sale por
## un borde entra por el opuesto, así que nunca hay costura.
func _px(img: Image, x: int, y: int, a: float) -> void:
	var px := posmod(x, img.get_width())
	var py := y
	if _wrap_y:
		py = posmod(y, img.get_height())
	elif py < 0 or py >= img.get_height():
		return
	var previo := img.get_pixel(px, py).a
	img.set_pixel(px, py, Color(1, 1, 1, maxf(previo, a)))


func _disco(img: Image, c: Vector2, r: float, a: float) -> void:
	var ri := int(ceil(r))
	for dy in range(-ri, ri + 1):
		for dx in range(-ri, ri + 1):
			var d := sqrt(float(dx * dx + dy * dy))
			if d > r:
				continue
			# Borde suavizado: sin esto los puntos pequeños se ven dentados.
			_px(img, int(c.x) + dx, int(c.y) + dy, a * clampf(r - d, 0.0, 1.0))


func _linea(img: Image, a: Vector2, b: Vector2, alfa: float, grosor: float = 1.0) -> void:
	var largo := a.distance_to(b)
	var pasos := int(largo * 2.0) + 1
	for i in pasos + 1:
		var p := a.lerp(b, float(i) / float(pasos))
		if grosor <= 1.0:
			_px(img, int(round(p.x)), int(round(p.y)), alfa)
		else:
			_disco(img, p, grosor * 0.5, alfa)


func _gen_puntos(img: Image, rnd: RandomNumberGenerator, n: int,
		rmin: float, rmax: float, alfa: float) -> void:
	for i in n:
		_disco(img,
			Vector2(rnd.randf() * LADO, rnd.randf() * LADO),
			rnd.randf_range(rmin, rmax),
			alfa * rnd.randf_range(0.6, 1.0))


func _gen_hojas(img: Image, rnd: RandomNumberGenerator) -> void:
	for i in 8:
		var c := Vector2(rnd.randf() * LADO, rnd.randf() * LADO)
		var d := Vector2.from_angle(rnd.randf() * TAU) * 5.0
		_linea(img, c - d, c + d, 0.10, 2.5)


func _gen_celulas(img: Image, rnd: RandomNumberGenerator) -> void:
	# Manchas grandes y muy tenues. Se dibujan como anillos difusos en vez de
	# discos llenos: un disco de este tamaño taparía el fondo.
	for i in 3:
		var c := Vector2(rnd.randf() * LADO, rnd.randf() * LADO)
		var r := rnd.randf_range(26.0, 40.0)
		var pasos := 90
		for k in pasos:
			var p := c + Vector2.from_angle(TAU * float(k) / float(pasos)) * r
			_disco(img, p, 3.0, 0.05)


func _gen_corriente(img: Image) -> void:
	# Ondas horizontales cuyo periodo es exactamente el lado del mosaico, así
	# que la onda continúa sin salto al repetirse.
	for fila in 3:
		var base := 20.0 + 42.0 * float(fila)
		var pts := PackedVector2Array()
		for x in LADO + 1:
			pts.append(Vector2(float(x), base + sin(TAU * float(x) / float(LADO)) * 6.0))
		for i in pts.size() - 1:
			_linea(img, pts[i], pts[i + 1], 0.08, 1.6)


func _gen_tapete(img: Image) -> void:
	# Diagonales de paso 32: divide a 128, así que casan al repetir.
	var paso := 32
	for k in range(-LADO, LADO * 2, paso):
		_linea(img, Vector2(k, 0), Vector2(k + LADO, LADO), 0.05)


func _gen_rejilla(img: Image) -> void:
	var paso := 32
	for k in range(0, LADO, paso):
		_linea(img, Vector2(k, 0), Vector2(k, LADO), 0.055)
		_linea(img, Vector2(0, k), Vector2(LADO, k), 0.055)


func _gen_panal(img: Image) -> void:
	# Celdas centradas en una retícula que se repite cada 128 en los dos ejes:
	# dos columnas y dos filas por mosaico, con las impares desplazadas media
	# celda. Es lo que permite que el panal continúe de un mosaico al siguiente.
	# El paso tiene que ser la MITAD del mosaico para que la retícula encaje
	# consigo misma: con paso 128 el periodo sería 256 y aparecerían costuras.
	# La separación entre celdas se consigue encogiendo el hexágono, no
	# alejándolo: a 30 los bordes dejan de tocarse y la malla se afina.
	var paso := 64.0
	var lado := 30.0
	for fy in range(-1, 3):
		for fx in range(-1, 3):
			var c := Vector2(
				float(fx) * paso + (paso * 0.5 if posmod(fy, 2) == 1 else 0.0),
				float(fy) * paso)
			for i in 6:
				var a := c + Vector2.from_angle(deg_to_rad(60.0 * float(i) - 30.0)) * lado
				var b := c + Vector2.from_angle(deg_to_rad(60.0 * float(i + 1) - 30.0)) * lado
				# Más claro que el resto de telones: con celdas separadas hay
				# mucha menos línea en pantalla, así que puede permitirse.
				_linea(img, a, b, 0.11)


## Rastros diagonales, como algo cayendo del cielo. El paso divide a 128 para
## que la diagonal continúe de un mosaico al siguiente.
func _gen_estelas(img: Image) -> void:
	for k in range(-LADO, LADO * 2, 32):
		for i in 26:
			var t := float(i) / 25.0
			var p := Vector2(k, 0).lerp(Vector2(k + 44.0, 44.0), t)
			_disco(img, p, 1.2, 0.09 * (1.0 - t * 0.5))


## Perfil de ciudad: siluetas en contorno con ventanas encendidas.
##
## Se dibuja como contorno y no relleno porque el mosaico solo puede AÑADIR luz:
## no hay forma de pintar un edificio más oscuro que el cielo. Un horizonte
## nocturno es justo eso —perfiles y ventanas— así que la limitación coincide con
## lo que se quería.
func _gen_horizonte(img: Image, rnd: RandomNumberGenerator, roto: bool) -> void:
	var base := float(img.get_height())
	var x := 0.0
	while x < float(LADO):
		var ancho := float(rnd.randi_range(26, 48))
		var alto := float(rnd.randi_range(150, 390))
		var cima := base - alto
		var alfa_perfil := 0.16 if not roto else 0.13

		if roto and rnd.randf() < 0.55:
			# Tejado partido: dos alturas y un borde dentado.
			var corte := x + ancho * rnd.randf_range(0.3, 0.7)
			var caida := cima + alto * rnd.randf_range(0.2, 0.5)
			_linea(img, Vector2(x, base), Vector2(x, cima), alfa_perfil)
			_linea(img, Vector2(x, cima), Vector2(corte, cima), alfa_perfil)
			_linea(img, Vector2(corte, cima), Vector2(corte, caida), alfa_perfil)
			_linea(img, Vector2(corte, caida), Vector2(x + ancho, caida), alfa_perfil)
			_linea(img, Vector2(x + ancho, caida), Vector2(x + ancho, base), alfa_perfil)
			# Fuego en la brecha.
			_disco(img, Vector2(corte, caida - 3.0), rnd.randf_range(3.0, 5.5), 0.30)
		else:
			_linea(img, Vector2(x, base), Vector2(x, cima), alfa_perfil)
			_linea(img, Vector2(x, cima), Vector2(x + ancho, cima), alfa_perfil)
			_linea(img, Vector2(x + ancho, cima), Vector2(x + ancho, base), alfa_perfil)

		# Ventanas. En la ciudad atacada quedan muchas menos encendidas.
		var prob := 0.55 if not roto else 0.18
		var vy := cima + 11.0
		while vy < base - 8.0:
			var vx := x + 7.0
			while vx < x + ancho - 5.0:
				if rnd.randf() < prob:
					_disco(img, Vector2(vx, vy), 1.8, 0.28)
				vx += 10.0
			vy += 13.0
		x += ancho + float(rnd.randi_range(2, 7))


## Aurora: cortinas verticales que se desvanecen hacia abajo.
##
## El alfa cae con el cuadrado de la altura para que la luz se apague antes de
## llegar al campo de juego. Una aurora que baje hasta el centro tapa círculos.
func _gen_aurora(img: Image, rnd: RandomNumberGenerator) -> void:
	var alto := float(img.get_height())
	for x in LADO:
		# Dos senos de periodo entero en el mosaico: así la cortina continúa al
		# repetirse sin corte visible.
		var fx := float(x) / float(LADO)
		var onda := sin(TAU * fx) * 0.5 + sin(TAU * 2.0 * fx + 1.3) * 0.3
		var intensidad := 0.10 * (0.45 + 0.55 * (0.5 + 0.5 * onda))
		var borde := alto * (0.45 + 0.28 * onda)
		var y := 0
		while float(y) < borde:
			var t := float(y) / borde
			_px(img, x, y, intensidad * (1.0 - t) * (1.0 - t))
			y += 1


## Chapa remachada: placas grandes con un remache en cada esquina.
##
## El remache es lo que la separa de la rejilla del circuito. Sin él son dos
## cuadrículas y el bioma de robots se confunde con el de chips.
func _gen_placas(img: Image) -> void:
	var paso := 64
	for k in range(0, LADO, paso):
		_linea(img, Vector2(k, 0), Vector2(k, LADO), 0.10)
		_linea(img, Vector2(0, k), Vector2(LADO, k), 0.10)
	for fy in range(0, LADO, paso):
		for fx in range(0, LADO, paso):
			for d in [Vector2(9, 9), Vector2(paso - 9, 9),
					Vector2(9, paso - 9), Vector2(paso - 9, paso - 9)]:
				var q: Vector2 = Vector2(fx, fy) + d
				_px(img, int(q.x), int(q.y), 0.24)
				_px(img, int(q.x) + 1, int(q.y), 0.18)
				_px(img, int(q.x), int(q.y) + 1, 0.18)
			# Costura interior, para que la placa no quede vacía del todo.
			_linea(img, Vector2(fx + 18, fy + paso * 0.5),
					Vector2(fx + paso - 18, fy + paso * 0.5), 0.05)


## Tierra vista desde arriba: granos, guijarros y galerías.
##
## Las galerías van con alfa muy baja y curvas: son lo que dice que debajo hay
## un hormiguero, pero si se ven demasiado compiten con las hormigas, que son lo
## que hay que mirar.
func _gen_tierra(img: Image, rnd: RandomNumberGenerator) -> void:
	for i in 150:
		_px(img, int(rnd.randf() * LADO), int(rnd.randf() * LADO),
				rnd.randf_range(0.04, 0.13))
	for i in 9:
		var c := Vector2(rnd.randf() * LADO, rnd.randf() * LADO)
		var rr := rnd.randf_range(1.6, 3.4)
		_linea(img, c - Vector2(rr, 0), c + Vector2(rr, 0), 0.14, rr * 1.6)
	# Galerías: una onda con periodo entero en el mosaico, o se vería el corte.
	for g in 2:
		var base := 30.0 + float(g) * 62.0
		for x in LADO:
			var y := base + sin(TAU * float(x) / float(LADO) + float(g) * 2.1) * 17.0
			_px(img, x, int(y), 0.07)
			_px(img, x, int(y) + 1, 0.04)


## Alicatado: cuadrícula de baldosas con junta y un brillo en cada una.
##
## El brillo desplazado hacia una esquina es lo que lo separa de una rejilla
## técnica: una baldosa refleja, un cable no.
func _gen_azulejos(img: Image) -> void:
	var paso := 32
	for k in range(0, LADO, paso):
		_linea(img, Vector2(k, 0), Vector2(k, LADO), 0.07)
		_linea(img, Vector2(0, k), Vector2(LADO, k), 0.07)
	for fy in range(0, LADO, paso):
		for fx in range(0, LADO, paso):
			_linea(img, Vector2(fx + 5, fy + 6), Vector2(fx + 13, fy + 6), 0.09)


## Confeti: papelillos inclinados, de tamaños distintos.
func _gen_confeti(img: Image, rnd: RandomNumberGenerator) -> void:
	for i in 22:
		var c := Vector2(rnd.randf() * LADO, rnd.randf() * LADO)
		var d := Vector2.from_angle(rnd.randf() * TAU) * rnd.randf_range(2.5, 5.0)
		_linea(img, c - d, c + d, rnd.randf_range(0.09, 0.16), 2.4)


## Banderines: la guirnalda cuelga en curva y de ella salen los triángulos.
##
## La curva tiene un periodo entero en el mosaico, así que la cuerda continúa de
## una repetición a la siguiente sin escalón.
func _gen_banderines(img: Image) -> void:
	var cuerda := 26.0
	var comba := 22.0
	for x in LADO:
		var y := cuerda + (1.0 - cos(TAU * float(x) / float(LADO))) * 0.5 * comba
		_px(img, x, int(y), 0.2)
		_px(img, x, int(y) + 1, 0.12)
	var paso := 32
	for k in range(0, LADO, paso):
		var cx := float(k) + float(paso) * 0.5
		var cy := cuerda + (1.0 - cos(TAU * cx / float(LADO))) * 0.5 * comba
		# Triángulo colgando: dos lados y la base.
		_linea(img, Vector2(cx - 11.0, cy), Vector2(cx, cy + 30.0), 0.17)
		_linea(img, Vector2(cx + 11.0, cy), Vector2(cx, cy + 30.0), 0.17)
		_linea(img, Vector2(cx - 11.0, cy), Vector2(cx + 11.0, cy), 0.17)


func _gen_trazas(img: Image, rnd: RandomNumberGenerator) -> void:
	# Una placa de verdad tiene tres cosas que la anterior no tenía: pistas de
	# grosores distintos, buses de varias líneas paralelas y zonas de puntos.
	# Con un solo grosor y trazos sueltos parecía una cuadrícula rota.

	# Buses: dos o tres pistas paralelas que giran juntas. Es lo que más se lee
	# como circuito, porque el paralelismo no aparece por casualidad.
	for i in 3:
		var p := Vector2(float(rnd.randi_range(0, 3)) * 32.0,
				float(rnd.randi_range(0, 3)) * 32.0)
		var horizontal := rnd.randf() < 0.5
		var largo := float(rnd.randi_range(2, 4)) * 32.0
		var carriles := rnd.randi_range(2, 3)
		for k in carriles:
			var sep := float(k) * 5.0
			var a := p + (Vector2.DOWN if horizontal else Vector2.RIGHT) * sep
			var medio := a + (Vector2.RIGHT if horizontal else Vector2.DOWN) * largo
			var fin := medio + (Vector2.DOWN if horizontal else Vector2.RIGHT) * (32.0 + sep)
			_linea(img, a, medio, 0.16)
			_linea(img, medio, fin, 0.16)

	# Pistas gruesas sueltas, con pad al final: anillo con agujero, como una
	# soldadura de verdad.
	for i in 4:
		var p := Vector2(rnd.randf() * LADO, rnd.randf() * LADO)
		var horizontal := rnd.randf() < 0.5
		var largo := float(rnd.randi_range(1, 3)) * 26.0
		var fin := p + (Vector2.RIGHT if horizontal else Vector2.DOWN) * largo
		_linea(img, p, fin, 0.2, 2.4)
		_disco(img, fin, 4.2, 0.24)
		_disco(img, fin, 1.7, 0.0)

	# Zona de puntos: la retícula de agujeros de una placa perforada.
	var zx := float(rnd.randi_range(0, 2)) * 32.0
	var zy := float(rnd.randi_range(0, 2)) * 32.0
	var y := zy
	while y < zy + 56.0:
		var x := zx
		while x < zx + 56.0:
			_disco(img, Vector2(x, y), 1.1, 0.1)
			x += 8.0
		y += 8.0
