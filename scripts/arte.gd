class_name Arte
extends RefCounted

## Carga de assets visuales intercambiables.
##
## Todo el arte del juego se dibuja con polígonos y líneas en código. Eso lo hace
## barato y coherente, pero también significa que mejorar el aspecto exige tocar
## la lógica. Este cargador rompe ese acoplamiento: **si existe el fichero, manda
## el fichero; si no, se dibuja como siempre**.
##
## Las consecuencias de esa regla, que son la mitad del valor:
##
## - Se puede sustituir una sola forma sin tocar las demás.
## - Si falta un fichero, o está corrupto, el juego sigue funcionando.
## - La lógica no se entera: radio, rotación, contagios y balance son idénticos.
##
## Lo que SÍ se pierde al sustituir: las formas que se mueven por dentro —las
## alas de la abeja, la cola del pez, el titileo de la estrella, el cordel del
## globo, el ondeo de la llama— pasan a ser imágenes quietas. Una imagen no bate
## alas. Para ésas conviene mantener el dibujo procedural, o aceptar que se
## queden estáticas.
##
## Dónde van los ficheros:
##
##   arte/targets/<forma>.png   (o .svg)   sustituye la forma de un target
##   arte/fondos/<telon>.png    (o .svg)   sustituye el mosaico de un fondo
##
## Los nombres son los del enum, en minúscula: abeja.png, copo.png, burbuja.png…
## `tools/exportar_arte.gd` genera todos los actuales como PNG para tener un
## punto de partida que editar.

const DIR_TARGETS := "res://arte/targets/"
## Mosaicos que se repiten. Tienen que casar consigo mismos.
const DIR_FONDOS := "res://arte/fondos/"
## Capa ELÁSTICA: se estira a pantalla completa, sin conservar proporción.
##
## Es la pieza que hace que el sistema funcione en cualquier aparato. Un
## degradado de cielo, una niebla, un agua de fondo: estirarlos al doble de alto
## no lo nota nadie, porque no tienen forma que reconocer. Lo que no se puede
## estirar —una bañera, una ciudad, un planeta— va en la capa rígida.
##
## Separar por lo que TOLERA deformación, y no por lo que la pieza es, es lo que
## permite rellenar cualquier proporción sin recortar nada importante.
const DIR_ELASTICAS := "res://arte/elasticas/"
## Imágenes de pantalla completa. NO se repiten: se escalan para cubrir.
##
## Son dos carpetas y no una porque son dos encargos distintos, y confundirlos
## se paga caro en las dos direcciones: un mosaico estirado a pantalla completa
## se ve borroso, y un cuadro repetido en baldosas deja una rejilla de costuras
## por todas partes. El nombre de la carpeta obliga a decidir cuál se está
## entregando.
const DIR_TELONES := "res://arte/telones/"
## Detonaciones.
const DIR_EXPLOSIONES := "res://arte/explosiones/"

## Cuántos radios de ancho tiene el lienzo de un target.
##
## El target NO llena la imagen: ocupa el centro y queda margen alrededor. Hace
## falta porque varias formas se salen de su radio —el cordel del globo llega a
## 2.65 radios, las aletas del misil a 1.35— y sin margen se recortarían.
##
## Quien dibuje un asset a mano tiene que respetar la misma proporción: el
## "radio" del target es 1/5.4 del ancho de la imagen. En un lienzo de 512, el
## cuerpo principal mide unos 190 px de diámetro y el resto es aire.
const LIENZO_EN_RADIOS := 5.4

## Cuántos radios de ancho tiene el lienzo de una explosión.
##
## Menos que el de un target porque una detonación es redonda y no tiene cola,
## pero más de dos: las esquirlas adelantan al anillo hasta un 28%, y sin margen
## se recortarían justo en el momento de más energía.
const EXPLOSION_EN_RADIOS := 3.0

## Nombres de fichero por tipo de detonación, en el orden de Explosion.Tipo.
const NOMBRE_EXPLOSION := ["cadena", "fallo", "impacto"]

## Nombres de fichero por forma, en el orden del enum Dot.Forma.
const NOMBRE_FORMA := [
	"circulo", "copo", "abeja", "hoja", "bola", "dron", "chispa", "chip",
	"avion", "misil", "pez", "estrella", "llama", "burbuja", "globo",
	"meteoro", "robot", "hormiga",
]

## Nombres de fichero por telón, en el orden del enum Fondo.Tipo.
const NOMBRE_FONDO := [
	"liso", "estrellas", "copos", "corriente", "celulas", "tapete", "panal",
	"rejilla", "hojas", "pavesas", "trazas", "estelas", "horizonte",
	"horizonte_roto", "aurora", "azulejos", "confeti", "banderines",
	"placas", "tierra",
]

## Se cachea también la AUSENCIA de textura: sin esto, cada frame de cada target
## sin asset intentaría abrir un fichero que no está.
static var _cache: Dictionary = {}


## El asset de una forma, o null si no lo hay.
##
## `variante` cubre las formas que cambian por instancia: la bola de billar
## lleva un número y el globo un color. Se prueba primero `bola_7.png` y se cae
## a `bola.png`, así que se puede dibujar una sola bola genérica o las quince,
## sin decidirlo por adelantado.
static func target(forma: int, variante: int = 0) -> Texture2D:
	if forma < 0 or forma >= NOMBRE_FORMA.size():
		return null
	var base: String = DIR_TARGETS + NOMBRE_FORMA[forma]
	if variante > 0:
		var propia := _buscar(base + "_" + str(variante))
		if propia != null:
			return propia
	return _buscar(base)


static func fondo(tipo: int) -> Texture2D:
	if tipo < 0 or tipo >= NOMBRE_FONDO.size():
		return null
	return _buscar(DIR_FONDOS + NOMBRE_FONDO[tipo])


## La imagen de pantalla completa de un telón, si la hay.
##
## Manda sobre el mosaico: si existen las dos, se usa esta. Lo que se pierde al
## entregar una pantalla completa es el desplazamiento —la nieve que cae, el río
## que corre, las pavesas que suben—, porque una imagen que no se repite no
## puede desplazarse sin descubrir su borde.
static func telon(tipo: int) -> Texture2D:
	if tipo < 0 or tipo >= NOMBRE_FONDO.size():
		return null
	return _buscar(DIR_TELONES + NOMBRE_FONDO[tipo])


## El azulejo del bioma: se repite y se desplaza como el generado.
##
## Los fondos se indexan por BIOMA y no por telón, al revés que los mosaicos
## generados. La razón la dio la primera entrega de arte: dos biomas pueden
## compartir telón —Cielo abierto y Lluvia de meteoros usan los dos un campo de
## estrellas— pero nadie dibuja «un campo de estrellas», dibuja «el cielo de
## Cielo abierto». El bioma es la unidad de identidad visual; el telón solo era
## la unidad del generador.
static func fondo_bioma(nombre: String) -> Texture2D:
	return _buscar(DIR_FONDOS + slug(nombre))


## La capa de encima del bioma: composición a lienzo completo.
##
## Trae lo que no se puede repetir —la bañera, la ciudad, el planeta, el nido—
## y por eso se ancla abajo y se escala solo por el ancho, nunca se estira. Una
## bañera al doble de ancho deja de ser una bañera.
static func telon_bioma(nombre: String, variante: String = "") -> Texture2D:
	return _con_variante(DIR_TELONES + slug(nombre), variante)


## La capa elástica del bioma, si la hay.
static func elastica_bioma(nombre: String, variante: String = "") -> Texture2D:
	return _con_variante(DIR_ELASTICAS + slug(nombre), variante)


## Busca primero la versión para esta proporción de pantalla y cae a la general.
##
## Así se puede entregar una sola imagen que valga para todo, o afinar solo los
## casos que lo pidan, sin que haya que entregar las tres siempre.
static func _con_variante(base: String, variante: String) -> Texture2D:
	if variante != "":
		var propia := _buscar(base + "__" + variante)
		if propia != null:
			return propia
	return _buscar(base)


## Qué grupo de proporción es esta pantalla: ancho, medio o alto.
##
## Tres y no más porque tres cubren el parque real y cada uno multiplica el
## trabajo de quien dibuja. Los cortes están donde de verdad se separan los
## aparatos: por debajo de 1.6 están las tabletas, por encima de 1.9 los móviles
## alargados de los últimos años, y en medio el 16:9 de toda la vida.
static func variante_pantalla(r: Vector2) -> String:
	if r.x <= 0.0:
		return "medio"
	var proporcion := r.y / r.x
	if proporcion < 1.6:
		return "ancho"
	if proporcion < 1.9:
		return "medio"
	return "alto"


## Nombre de bioma a nombre de fichero: minúsculas, sin acentos, con guiones.
##
## "Cielo abierto" -> cielo_abierto, "Otoño" -> otono, "Básico" -> basico.
static func slug(nombre: String) -> String:
	var s := nombre.to_lower()
	for par in [["á", "a"], ["é", "e"], ["í", "i"], ["ó", "o"], ["ú", "u"],
			["ñ", "n"], ["ü", "u"]]:
		s = s.replace(par[0], par[1])
	return s.replace(" ", "_")


## Cuántos fotogramas como mucho puede tener una tira.
##
## Se prueban uno a uno porque el número va en el nombre del fichero y no hay
## forma de preguntarlo antes de abrirlo. Sale caro una sola vez: el resultado,
## incluida la ausencia, queda cacheado para toda la partida.
const MAX_FOTOGRAMAS := 24

## El asset de una detonación: la textura y cuántos fotogramas trae.
##
## Devuelve un diccionario con "tex" y "fotogramas". Dos formas de entregarla:
##
##   cadena.png      una imagen quieta. El nodo la escala al radio de cada
##                   instante y la desvanece al final.
##   cadena@8.png    ocho fotogramas en fila, del mismo ancho. El nodo recorre
##                   la tira a lo largo de la vida de la onda y NO desvanece:
##                   el apagado lo decide el dibujo, que es de lo que se trata
##                   cuando alguien quiere diseñar el efecto de verdad.
##
## Y admite variante por bioma, igual que las bolas de billar: se prueba primero
## `impacto_asedio.png` y se cae a `impacto.png`. Así la explosión del planeta
## puede no parecerse en nada a la de la ciudad sin que haga falta un tipo nuevo.
static func explosion(tipo: int, bioma: String = "") -> Dictionary:
	if tipo < 0 or tipo >= NOMBRE_EXPLOSION.size():
		return {"tex": null, "fotogramas": 1}
	var base: String = DIR_EXPLOSIONES + NOMBRE_EXPLOSION[tipo]
	if bioma != "":
		var propia := _tira(base + "_" + slug(bioma))
		if propia["tex"] != null:
			return propia
	return _tira(base)


## Busca una imagen suelta o una tira `nombre@N`, y dice cuántos fotogramas trae.
static func _tira(base: String) -> Dictionary:
	var suelta := _buscar(base)
	if suelta != null:
		return {"tex": suelta, "fotogramas": 1}
	for n in range(2, MAX_FOTOGRAMAS + 1):
		var tira := _buscar("%s@%d" % [base, n])
		if tira != null:
			return {"tex": tira, "fotogramas": n}
	return {"tex": null, "fotogramas": 1}


## Busca el asset probando las extensiones que Godot importa como textura.
##
## Se comprueba el `.import` y no el fichero suelto: en una build exportada el
## PNG original no viaja, solo su versión importada, así que preguntar por el
## fichero de origen daría siempre que no en el teléfono.
static func _buscar(base: String) -> Texture2D:
	if _cache.has(base):
		return _cache[base]

	var encontrada: Texture2D = null
	for ext: String in [".png", ".svg", ".webp", ".jpg"]:
		var ruta := base + ext
		if ResourceLoader.exists(ruta):
			var res := ResourceLoader.load(ruta)
			if res is Texture2D:
				encontrada = res
				break

	_cache[base] = encontrada
	return encontrada


## Olvida lo cacheado. Solo hace falta al editar assets con el juego abierto.
static func recargar() -> void:
	_cache.clear()
