class_name Niveles
extends RefCounted

## La campaña, como tabla de datos.
##
## Un nivel aquí NO es contenido dibujado a mano: es un objetivo más un escalón
## de partida. Eso es lo que permite tener campaña sin violar la decisión de
## `contexto/00-decisiones.md` de evitar géneros con hambre de contenido —
## añadir un nivel cuesta una fila, no una tarde de arte.
##
## La variedad real no sale de subir números, sale de que cambien el OBJETIVO y
## la REGLA DE MOVIMIENTO. Cada bioma agrupa los niveles que comparten regla, y
## están ordenados de menos a más hostil: rebote enseña, nieve deja respirar,
## corriente y enjambre regalan los grupos, billar y panal los deshacen, y
## estampida se defiende de ti.
##
## Meta.LIMPIAS existe y funciona, pero ningún nivel la usa: vaciar la pantalla
## entera resultó demasiado duro y queda aparcada.
##
## Cada nivel trae además su regla de movimiento (`mov`), que es lo que
## convierte un bioma en algo más que una paleta: cambia cómo se lee el campo y
## cómo hay que planear la cadena.

enum Meta {
	PUNTOS,          ## llegar a N puntos
	CADENA,          ## conseguir una cadena de xN
	LIMPIAS,         ## vaciar la pantalla N veces
	SEGUNDOS,        ## aguantar N segundos
	PUNTOS_LIMPIOS,  ## llegar a N puntos sin fallar un solo tap
}

const LISTA: Array[Dictionary] = [
	# --- Basico: circulos lisos que se buscan. El grupo viene servido ------
	#
	# Abre la campaña. Es el bioma sin ficcion: circulos lisos sobre celulas, sin
	# nada que interpretar, y ademas el unico donde el grupo VIENE SERVIDO. Quien
	# no ha jugado nunca no tiene que buscar la jugada, solo elegir el instante,
	# que es la mitad del juego y la mas facil de entender.
	#
	# Sus escalones bajan a 0-0-1. Traia 2-3-3, calibrados para ir en el quinto
	# puesto de la curva; dejarlos ahi seria abrir con la dificultad de la mitad
	# de la campana. El escalon es la posicion en la curva, no una propiedad del
	# bioma, asi que se mueve con el.
	{"bioma": "Básico", "mov": Dot.Movimiento.ENJAMBRE,
		"meta": Meta.CADENA, "valor": 10, "escalon": 0,
		"pista": "pista_01"},
	{"bioma": "Básico", "mov": Dot.Movimiento.ENJAMBRE,
		"meta": Meta.PUNTOS, "valor": 600, "escalon": 0,
		"pista": "pista_02"},
	{"bioma": "Básico", "mov": Dot.Movimiento.ENJAMBRE,
		"meta": Meta.SEGUNDOS, "valor": 60, "escalon": 1,
		"pista": "pista_03"},

	# --- Cielo abierto: rebote. Aqui se aprende a apuntar -------------------
	#
	# Sube a 1-1-2-2 al pasar al segundo puesto: ya no es la primera pantalla que
	# se ve, asi que puede pedir algo mas.
	{"bioma": "Cielo abierto", "mov": Dot.Movimiento.REBOTE,
		"meta": Meta.PUNTOS, "valor": 60, "escalon": 1,
		"pista": "pista_04"},
	{"bioma": "Cielo abierto", "mov": Dot.Movimiento.REBOTE,
		"meta": Meta.CADENA, "valor": 4, "escalon": 1,
		"pista": "pista_05"},
	{"bioma": "Cielo abierto", "mov": Dot.Movimiento.REBOTE,
		"meta": Meta.PUNTOS, "valor": 250, "escalon": 2,
		"pista": "pista_06"},
	{"bioma": "Cielo abierto", "mov": Dot.Movimiento.REBOTE,
		"meta": Meta.CADENA, "valor": 6, "escalon": 2,
		"pista": "pista_07"},

	# --- Invierno: nieve. Lento, para respirar antes de apretar -------------
	{"bioma": "Invierno", "mov": Dot.Movimiento.NIEVE,
		"meta": Meta.PUNTOS, "valor": 300, "escalon": 1,
		"pista": "pista_08"},
	{"bioma": "Invierno", "mov": Dot.Movimiento.NIEVE,
		"meta": Meta.CADENA, "valor": 7, "escalon": 2,
		"pista": "pista_09"},
	{"bioma": "Invierno", "mov": Dot.Movimiento.NIEVE,
		"meta": Meta.SEGUNDOS, "valor": 50, "escalon": 2,
		"pista": "pista_10"},

	# --- Rio: corriente. Los grupos se forman solos rio abajo ---------------
	{"bioma": "Río", "mov": Dot.Movimiento.CORRIENTE,
		"meta": Meta.PUNTOS, "valor": 400, "escalon": 2,
		"pista": "pista_11"},
	{"bioma": "Río", "mov": Dot.Movimiento.CORRIENTE,
		"meta": Meta.CADENA, "valor": 8, "escalon": 2,
		"pista": "pista_12"},
	{"bioma": "Río", "mov": Dot.Movimiento.CORRIENTE,
		"meta": Meta.PUNTOS_LIMPIOS, "valor": 250, "escalon": 2,
		"pista": "pista_13"},

	# --- Hormigas: muchas, lentas y pegadas. Aqui se aprende a encadenar ---
	{"bioma": "Hormigas", "mov": Dot.Movimiento.HORMIGA,
		"meta": Meta.PUNTOS, "valor": 380, "escalon": 2,
		"pista": "pista_14"},
	{"bioma": "Hormigas", "mov": Dot.Movimiento.HORMIGA,
		"meta": Meta.CADENA, "valor": 12, "escalon": 2,
		"pista": "pista_15"},
	{"bioma": "Hormigas", "mov": Dot.Movimiento.HORMIGA,
		"meta": Meta.SEGUNDOS, "valor": 55, "escalon": 3,
		"pista": "pista_16"},

	# --- Billar: chocan entre ellos. Nada se queda quieto -------------------
	{"bioma": "Billar", "mov": Dot.Movimiento.CHOQUE,
		"meta": Meta.PUNTOS, "valor": 400, "escalon": 2,
		"pista": "pista_17"},
	{"bioma": "Billar", "mov": Dot.Movimiento.CHOQUE,
		"meta": Meta.CADENA, "valor": 7, "escalon": 3,
		"pista": "pista_18"},
	{"bioma": "Billar", "mov": Dot.Movimiento.CHOQUE,
		"meta": Meta.SEGUNDOS, "valor": 55, "escalon": 3,
		"pista": "pista_19"},

	# --- Panal: abeja. Tirones y giros bruscos, dificil de leer ------------
	{"bioma": "Panal", "mov": Dot.Movimiento.ABEJA,
		"meta": Meta.PUNTOS, "valor": 450, "escalon": 3,
		"pista": "pista_20"},
	{"bioma": "Panal", "mov": Dot.Movimiento.ABEJA,
		"meta": Meta.CADENA, "valor": 7, "escalon": 3,
		"pista": "pista_21"},
	{"bioma": "Panal", "mov": Dot.Movimiento.ABEJA,
		"meta": Meta.PUNTOS_LIMPIOS, "valor": 300, "escalon": 4,
		"pista": "pista_22"},

	# --- Estampida: huyen de tus ondas. El bioma que se defiende -----------
	{"bioma": "Estampida", "mov": Dot.Movimiento.HUIDA,
		"meta": Meta.CADENA, "valor": 6, "escalon": 2,
		"pista": "pista_23"},
	{"bioma": "Estampida", "mov": Dot.Movimiento.HUIDA,
		"meta": Meta.PUNTOS, "valor": 420, "escalon": 2,
		"pista": "pista_24"},
	{"bioma": "Estampida", "mov": Dot.Movimiento.HUIDA,
		"meta": Meta.CADENA, "valor": 9, "escalon": 3,
		"pista": "pista_25"},

	# --- Otoño: la caída de la nieve, pero en hojas y en calido -------------
	{"bioma": "Otoño", "mov": Dot.Movimiento.NIEVE,
		"meta": Meta.PUNTOS, "valor": 350, "escalon": 2,
		"pista": "pista_26"},
	{"bioma": "Otoño", "mov": Dot.Movimiento.NIEVE,
		"meta": Meta.CADENA, "valor": 8, "escalon": 3,
		"pista": "pista_27"},
	{"bioma": "Otoño", "mov": Dot.Movimiento.NIEVE,
		"meta": Meta.SEGUNDOS, "valor": 55, "escalon": 3,
		"pista": "pista_28"},

	# --- Brasas: la nieve del reves. Se caza hacia arriba -------------------
	{"bioma": "Brasas", "mov": Dot.Movimiento.BRASA,
		"meta": Meta.PUNTOS, "valor": 400, "escalon": 3,
		"pista": "pista_29"},
	{"bioma": "Brasas", "mov": Dot.Movimiento.BRASA,
		"meta": Meta.CADENA, "valor": 8, "escalon": 3,
		"pista": "pista_30"},
	{"bioma": "Brasas", "mov": Dot.Movimiento.BRASA,
		"meta": Meta.PUNTOS_LIMPIOS, "valor": 350, "escalon": 4,
		"pista": "pista_31"},

	# --- Caza de robots: pocos, esquivos y con un tiron antes de cada giro -
	{"bioma": "Caza de robots", "mov": Dot.Movimiento.PATRULLA,
		"meta": Meta.PUNTOS, "valor": 420, "escalon": 3,
		"pista": "pista_32"},
	{"bioma": "Caza de robots", "mov": Dot.Movimiento.PATRULLA,
		"meta": Meta.CADENA, "valor": 7, "escalon": 4,
		"pista": "pista_33"},
	{"bioma": "Caza de robots", "mov": Dot.Movimiento.PATRULLA,
		"meta": Meta.SEGUNDOS, "valor": 50, "escalon": 4,
		"pista": "pista_34"},

	# --- Circuito: angulos rectos. Predecible pero exigente ----------------
	{"bioma": "Circuito", "mov": Dot.Movimiento.CIRCUITO,
		"meta": Meta.PUNTOS, "valor": 450, "escalon": 3,
		"pista": "pista_35"},
	{"bioma": "Circuito", "mov": Dot.Movimiento.CIRCUITO,
		"meta": Meta.CADENA, "valor": 9, "escalon": 4,
		"pista": "pista_36"},
	{"bioma": "Circuito", "mov": Dot.Movimiento.CIRCUITO,
		"meta": Meta.CADENA, "valor": 11, "escalon": 5,
		"pista": "pista_37"},

	# --- Ciudad de papel: planean sobre una ciudad encendida ---------------
	{"bioma": "Ciudad de papel", "mov": Dot.Movimiento.PLANEO,
		"meta": Meta.PUNTOS, "valor": 380, "escalon": 2,
		"pista": "pista_38"},
	{"bioma": "Ciudad de papel", "mov": Dot.Movimiento.PLANEO,
		"meta": Meta.CADENA, "valor": 8, "escalon": 3,
		"pista": "pista_39"},
	{"bioma": "Ciudad de papel", "mov": Dot.Movimiento.PLANEO,
		"meta": Meta.SEGUNDOS, "valor": 55, "escalon": 3,
		"pista": "pista_40"},

	# --- Ducha: burbujas que suben. El bioma mas amable de todos -----------
	{"bioma": "Ducha", "mov": Dot.Movimiento.BRASA,
		"meta": Meta.PUNTOS, "valor": 320, "escalon": 1,
		"pista": "pista_41"},
	{"bioma": "Ducha", "mov": Dot.Movimiento.BRASA,
		"meta": Meta.CADENA, "valor": 8, "escalon": 2,
		"pista": "pista_42"},
	{"bioma": "Ducha", "mov": Dot.Movimiento.BRASA,
		"meta": Meta.SEGUNDOS, "valor": 50, "escalon": 2,
		"pista": "pista_43"},

	# --- Fiesta: globos que suben y se van ---------------------------------
	{"bioma": "Fiesta", "mov": Dot.Movimiento.GLOBO,
		"meta": Meta.PUNTOS, "valor": 420, "escalon": 2,
		"pista": "pista_44"},
	{"bioma": "Fiesta", "mov": Dot.Movimiento.GLOBO,
		"meta": Meta.CADENA, "valor": 9, "escalon": 3,
		"pista": "pista_45"},
	{"bioma": "Fiesta", "mov": Dot.Movimiento.GLOBO,
		"meta": Meta.SEGUNDOS, "valor": 55, "escalon": 3,
		"pista": "pista_46"},

	# --- Asedio: caen sobre la ciudad --------------------------------------
	{"bioma": "Asedio", "mov": Dot.Movimiento.BOMBARDEO,
		"meta": Meta.SEGUNDOS, "valor": 40, "escalon": 1,
		"pista": "pista_47"},
	{"bioma": "Asedio", "mov": Dot.Movimiento.BOMBARDEO,
		"meta": Meta.PUNTOS, "valor": 400, "escalon": 2,
		"pista": "pista_48"},
	{"bioma": "Asedio", "mov": Dot.Movimiento.BOMBARDEO,
		"meta": Meta.SEGUNDOS, "valor": 65, "escalon": 3,
		"pista": "pista_49"},

	# --- Lluvia de meteoros: todos caen hacia el planeta --------------------
	{"bioma": "Lluvia de meteoros", "mov": Dot.Movimiento.METEORO,
		"meta": Meta.SEGUNDOS, "valor": 40, "escalon": 1,
		"pista": "pista_50"},
	{"bioma": "Lluvia de meteoros", "mov": Dot.Movimiento.METEORO,
		"meta": Meta.PUNTOS, "valor": 420, "escalon": 2,
		"pista": "pista_51"},
	{"bioma": "Lluvia de meteoros", "mov": Dot.Movimiento.METEORO,
		"meta": Meta.SEGUNDOS, "valor": 70, "escalon": 3,
		"pista": "pista_52"},
]


## Paleta de cada bioma: fondo, círculos y ondas.
##
## Lo que NO se tematiza: la barra de tiempo (verde, ámbar, rojo) y el anillo
## gris del fallo. Esos colores no decoran, informan, y cambiarlos por bioma
## obligaría al jugador a reaprender a leerlos siete veces. Se tematiza el
## mundo; la interfaz se queda quieta.
##
## Regla de legibilidad: el círculo siempre mucho más claro que su fondo. Es lo
## único que el jugador tiene que localizar a toda velocidad, así que ningún
## capricho de color puede comprometerlo.
const PALETAS := {
	"Cielo abierto": {
		"telon": Fondo.Tipo.ESTRELLAS,
		# La estrella fugaz ya no es decorado del fondo: es un OBJETIVO que
		# vale diez y revienta más grande. Dos estrellas fugaces, una tocable
		# y otra no, serían el mismo fallo que la espuma dibujada de Ducha.
		"fugaz": true,
		"forma": Dot.Forma.ESTRELLA,
		"fondo": "070b16", "punto": "fdfbff", "onda": "8ec5ff", "radio": 9.0},
	"Invierno": {
		"telon": Fondo.Tipo.COPOS,
		"banda": Fondo.Tipo.AURORA, "banda_color": "6bffc4",
		"forma": Dot.Forma.COPO,
		"fondo": "0f2033", "punto": "f4fbff", "onda": "8fd8ff", "radio": 10.0},
	"Río": {
		"telon": Fondo.Tipo.CORRIENTE,
		# Cada detonación suelta burbujas que suben y viven más que la onda.
		"burbujas": true,
		"forma": Dot.Forma.PEZ,
		"fondo": "07161c", "punto": "ffd98a", "onda": "2fd6c0", "radio": 9.0},
	"Hormigas": {
		"telon": Fondo.Tipo.TIERRA,
		"forma": Dot.Forma.HORMIGA,
		# Muchas y lentas, que es justo lo contrario que los robots. Con treinta
		# y cuatro bichos pegados, esperar medio segundo más siempre paga: es el
		# bioma donde se aprende que la cadena vale más que la prisa.
		"vel_mult": 0.6, "targets": 34,
		"fondo": "150d07", "punto": "ff8a52", "onda": "ffb066", "radio": 9.0},
	"Básico": {
		"telon": Fondo.Tipo.CELULAS,
		"forma": Dot.Forma.CIRCULO,
		"fondo": "150f1a", "punto": "e6d8f7", "onda": "b45cff", "radio": 8.0},
	"Billar": {
		"telon": Fondo.Tipo.TAPETE, "marco": Fondo.Marco.MESA,
		"forma": Dot.Forma.BOLA,
		"fondo": "0a2717", "punto": "fff8e4", "onda": "ffc24d", "radio": 10.0},
	"Panal": {
		"telon": Fondo.Tipo.PANAL,
		"forma": Dot.Forma.ABEJA,
		"fondo": "17100a", "punto": "ffd24a", "onda": "ff8c1a", "radio": 9.0},
	"Estampida": {
		"telon": Fondo.Tipo.REJILLA,
		"forma": Dot.Forma.DRON,
		"fondo": "060a12", "punto": "6feaff", "onda": "ff3b30", "radio": 8.0},
	"Otoño": {
		"telon": Fondo.Tipo.HOJAS,
		"forma": Dot.Forma.HOJA,
		"fondo": "1a1208", "punto": "ffb347", "onda": "ff7038", "radio": 11.0},
	"Brasas": {
		"telon": Fondo.Tipo.PAVESAS,
		"forma": Dot.Forma.LLAMA,
		"fondo": "120806", "punto": "ffca6b", "onda": "ff5a1f", "radio": 8.0},
	"Caza de robots": {
		"telon": Fondo.Tipo.PLACAS,
		"forma": Dot.Forma.ROBOT,
		# Pocos y rápidos. Lo que cuesta aquí no es llegar hasta ellos sino
		# acertarles, así que hay menos en pantalla y valen más cada uno.
		"vel_mult": 1.15, "targets": 14,
		"fondo": "0b1216", "punto": "9ee6ff", "onda": "3fd0ff", "radio": 11.0},
	"Circuito": {
		"telon": Fondo.Tipo.TRAZAS,
		"forma": Dot.Forma.CHIP,
		"fondo": "030b07", "punto": "8dffb0", "onda": "34ff88", "radio": 8.0},
	"Ciudad de papel": {
		"telon": Fondo.Tipo.ESTRELLAS,
		"banda": Fondo.Tipo.HORIZONTE, "banda_color": "ffc879",
		"forma": Dot.Forma.AVION,
		"fondo": "101a2b", "punto": "fff4e2", "onda": "ffd166", "radio": 10.0},
	"Ducha": {
		"telon": Fondo.Tipo.AZULEJOS, "marco": Fondo.Marco.TINA,
		"forma": Dot.Forma.BURBUJA,
		"fondo": "0c1d24", "punto": "d9f7ff", "onda": "7fe3ff", "radio": 11.0},
	"Fiesta": {
		"telon": Fondo.Tipo.CONFETI,
		"banda": Fondo.Tipo.BANDERINES, "banda_color": "ffd66b",
		"forma": Dot.Forma.GLOBO,
		# Azul noche y no morado: el confeti del bioma tiene seis colores y sobre
		# morado el rosa y el lila se hundían, así que dos de los seis dejaban de
		# contar. Es el color de la sala del fondo entregado.
		"fondo": "101a2b", "punto": "ff8ad0", "onda": "ff5fd0", "radio": 11.0},
	"Asedio": {
		"telon": Fondo.Tipo.ESTELAS,
		"banda": Fondo.Tipo.HORIZONTE_ROTO, "banda_color": "ff7a3c",
		"forma": Dot.Forma.MISIL,
		# Caen RÁPIDO: un proyectil tarda unos seis segundos en llegar abajo.
		# Lentos se leían como un adorno de fondo, no como una amenaza, y la
		# tensión de un bioma de defensa está en el poco tiempo que tienes para
		# reaccionar a cada uno, no en cuántos hay.
		# El reloj pasa a segundo plano: aquí la amenaza es la ciudad, no la barra.
		# Con el desagüe normal se perdía por tiempo a los 11 s mientras los
		# proyectiles tardaban 21 s en llegar abajo, así que la mecánica del
		# bioma no llegaba ni a entrar en juego.
		"vel_mult": 1.25, "respawn_mult": 1.2, "targets": 10, "drain_mult": 0.45,
		# Si uno llega abajo, revienta en la ciudad y se acabó la partida.
		"defender": true,
		"fondo": "140809", "punto": "ffd9cc", "onda": "ff4530", "radio": 9.0},
	"Lluvia de meteoros": {
		"telon": Fondo.Tipo.ESTRELLAS, "marco": Fondo.Marco.PLANETA,
		"forma": Dot.Forma.METEORO,
		# Entran rápido y encima aceleran: el recorrido largo, de la esquina de
		# arriba al planeta, se hace en unos seis segundos.
		"vel_mult": 1.0, "respawn_mult": 1.1, "targets": 12, "drain_mult": 0.45,
		# La derrota no es una franja abajo como en el asedio sino el disco del
		# planeta, que está en una esquina. Por eso lleva su propia clave.
		"defender": true, "defensa": "planeta",
		"fondo": "04060e", "punto": "ffa14d", "onda": "ff6a2b", "radio": 10.0},
}



## Los biomas en el orden en que aparecen en la campaña.
##
## Se saca de la lista de niveles y no de las paletas: el diccionario no
## garantiza orden, y en el modo sin fin la rotación tiene que seguir la misma
## curva de menos a más hostil que la campaña.
static func biomas() -> Array:
	var vistos: Array = []
	for n in LISTA:
		var b: String = str(n["bioma"])
		if not vistos.has(b):
			vistos.append(b)
	return vistos


## Los biomas del modo sin fin: todos.
##
## Durante un tiempo los de defensa quedaron fuera, con el argumento de que
## perder porque un proyectil toca el suelo aparecería de la nada a los tres
## minutos y se leería como una injusticia. El argumento no era malo, pero la
## conclusión sí: quitarlos convertía el modo sin fin en una versión recortada
## del juego, y dos de las cosas más memorables que tiene no salían nunca.
##
## Lo que hacía injusta la derrota no era el bioma, era **no haber avisado**. El
## aviso se da ahora al entrar (ver `_empezar_transicion`), y con eso el riesgo
## deja de venir de la nada y pasa a ser parte del trato.
static func biomas_sinfin() -> Array:
	return biomas()


## El movimiento con el que juega un bioma, tomado de su primer nivel.
static func movimiento_de_bioma(nombre: String) -> int:
	for n in LISTA:
		if str(n["bioma"]) == nombre:
			return int(n.get("mov", Dot.Movimiento.REBOTE))
	return Dot.Movimiento.REBOTE


## La paleta de un bioma por nombre.
static func paleta_de(nombre: String) -> Dictionary:
	return PALETAS.get(nombre, PALETAS["Cielo abierto"])

## La paleta del bioma de un nivel, o la neutra si no la tiene.
static func paleta(i: int) -> Dictionary:
	return PALETAS.get(str(nivel(i)["bioma"]), PALETAS["Cielo abierto"])


static func paleta_neutra() -> Dictionary:
	return PALETAS["Cielo abierto"]

static func total() -> int:
	return LISTA.size()


static func nivel(i: int) -> Dictionary:
	return LISTA[clampi(i, 0, LISTA.size() - 1)]


## Primera letra en mayúscula. Se hace al mostrar y no en los datos: así las
## frases se escriben una sola vez y con naturalidad, y no hay que acordarse de
## capitalizar cada una de las cuarenta que hay en la tabla.
static func capitalizar(t: String) -> String:
	if t.is_empty():
		return t
	return t.substr(0, 1).to_upper() + t.substr(1)


## El objetivo en una línea, para la tarjeta de inicio y el HUD.
static func describir(i: int) -> String:
	var n := nivel(i)
	var v: int = n["valor"]
	match int(n["meta"]):
		Meta.PUNTOS:
			return Textos.t("meta_puntos", [v])
		Meta.CADENA:
			return Textos.t("meta_cadena", [v])
		Meta.LIMPIAS:
			# El singular y el plural salen de dos claves y no de un "vez/veces"
			# cosido aquí: hay idiomas que parten el plural por otro sitio, y
			# alguno que no lo parte.
			return Textos.plural("meta_limpias", v, [v])
		Meta.SEGUNDOS:
			return Textos.t("meta_segundos", [v])
		Meta.PUNTOS_LIMPIOS:
			return Textos.t("meta_puntos_limpios", [v])
	return ""


## El nombre del bioma tal como se enseña, que NO es su clave.
##
## En `LISTA` y en `PALETAS` el bioma se llama «Río», y esa cadena es una CLAVE:
## con ella se busca `rio.png`, su trío de colores del HUD y su manifiesto de
## astros. Traducirla rompería los assets. Así que la clave se queda en español
## y lo que lee el jugador sale de la tabla de idiomas.
static func nombre_bioma(clave: String) -> String:
	return Textos.t("bioma_" + Arte.slug(clave))


## Progreso actual como "23 / 60", para el HUD.
static func progreso(i: int, puntos: int, cadena: int, limpias: int, segundos: float) -> String:
	var n := nivel(i)
	var v: int = n["valor"]
	match int(n["meta"]):
		Meta.PUNTOS, Meta.PUNTOS_LIMPIOS:
			return Textos.t("progreso_simple", [puntos, v])
		Meta.CADENA:
			return Textos.t("progreso_cadena", [cadena, v])
		Meta.LIMPIAS:
			return Textos.t("progreso_simple", [limpias, v])
		Meta.SEGUNDOS:
			return Textos.t("progreso_segundos", [int(segundos), v])
	return ""


static func cumplido(i: int, puntos: int, cadena: int, limpias: int, segundos: float) -> bool:
	var n := nivel(i)
	var v: int = n["valor"]
	match int(n["meta"]):
		Meta.PUNTOS, Meta.PUNTOS_LIMPIOS:
			return puntos >= v
		Meta.CADENA:
			return cadena >= v
		Meta.LIMPIAS:
			return limpias >= v
		Meta.SEGUNDOS:
			return segundos >= float(v)
	return false


## La forma con la que se dibujan los círculos del nivel.
static func forma(i: int) -> int:
	return int(paleta(i).get("forma", Dot.Forma.CIRCULO))


## La regla de movimiento del nivel.
static func movimiento(i: int) -> int:
	return int(nivel(i).get("mov", Dot.Movimiento.REBOTE))


## Si el nivel se pierde en cuanto fallas un tap.
static func exige_limpieza(i: int) -> bool:
	return int(nivel(i)["meta"]) == Meta.PUNTOS_LIMPIOS
