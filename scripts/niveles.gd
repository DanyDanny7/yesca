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
	# --- Cielo abierto: rebote. Aqui se aprende a jugar ---------------------
	{"bioma": "Cielo abierto", "mov": Dot.Movimiento.REBOTE,
		"meta": Meta.PUNTOS, "valor": 60, "escalon": 0,
		"pista": "toca un círculo y deja que la onda haga el resto"},
	{"bioma": "Cielo abierto", "mov": Dot.Movimiento.REBOTE,
		"meta": Meta.CADENA, "valor": 4, "escalon": 0,
		"pista": "busca cuatro juntos, no toques el primero que veas"},
	{"bioma": "Cielo abierto", "mov": Dot.Movimiento.REBOTE,
		"meta": Meta.PUNTOS, "valor": 250, "escalon": 1,
		"pista": "cada eslabón vale más que el anterior"},
	{"bioma": "Cielo abierto", "mov": Dot.Movimiento.REBOTE,
		"meta": Meta.CADENA, "valor": 6, "escalon": 1,
		"pista": "puedes tener varias cadenas a la vez, cada una con su cuenta"},

	# --- Invierno: nieve. Lento, para respirar antes de apretar -------------
	{"bioma": "Invierno", "mov": Dot.Movimiento.NIEVE,
		"meta": Meta.PUNTOS, "valor": 300, "escalon": 1,
		"pista": "caen despacio y en vaivén; el campo se renueva por arriba"},
	{"bioma": "Invierno", "mov": Dot.Movimiento.NIEVE,
		"meta": Meta.CADENA, "valor": 7, "escalon": 2,
		"pista": "la caída los alinea sola: espera a que la columna se junte"},
	{"bioma": "Invierno", "mov": Dot.Movimiento.NIEVE,
		"meta": Meta.SEGUNDOS, "valor": 50, "escalon": 2,
		"pista": "aquí no puntúas, sobrevives"},

	# --- Rio: corriente. Los grupos se forman solos rio abajo ---------------
	{"bioma": "Río", "mov": Dot.Movimiento.CORRIENTE,
		"meta": Meta.PUNTOS, "valor": 400, "escalon": 2,
		"pista": "todos van en la misma dirección: deja que la corriente los junte"},
	{"bioma": "Río", "mov": Dot.Movimiento.CORRIENTE,
		"meta": Meta.CADENA, "valor": 8, "escalon": 2,
		"pista": "el mejor momento es justo antes de que salgan por el borde"},
	{"bioma": "Río", "mov": Dot.Movimiento.CORRIENTE,
		"meta": Meta.PUNTOS_LIMPIOS, "valor": 250, "escalon": 2,
		"pista": "un solo fallo y se acabó; van todos al mismo sitio, no hay excusa"},

	# --- Hormigas: muchas, lentas y pegadas. Aqui se aprende a encadenar ---
	{"bioma": "Hormigas", "mov": Dot.Movimiento.HORMIGA,
		"meta": Meta.PUNTOS, "valor": 380, "escalon": 2,
		"pista": "son muchas y van despacio: deja que se junten"},
	{"bioma": "Hormigas", "mov": Dot.Movimiento.HORMIGA,
		"meta": Meta.CADENA, "valor": 12, "escalon": 2,
		"pista": "con este gentío, doce seguidas es cuestión de elegir bien"},
	{"bioma": "Hormigas", "mov": Dot.Movimiento.HORMIGA,
		"meta": Meta.SEGUNDOS, "valor": 55, "escalon": 3,
		"pista": "no dejan de venir: aquí el problema nunca es a quién tocar"},

	# --- Enjambre: se buscan entre si. El grupo viene servido --------------
	{"bioma": "Enjambre", "mov": Dot.Movimiento.ENJAMBRE,
		"meta": Meta.CADENA, "valor": 10, "escalon": 2,
		"pista": "se agrupan solos; aquí lo difícil no es encontrarlos sino el instante"},
	{"bioma": "Enjambre", "mov": Dot.Movimiento.ENJAMBRE,
		"meta": Meta.PUNTOS, "valor": 600, "escalon": 3,
		"pista": "el grumo se deshace tras cada onda: hay que dejarlo rehacerse"},
	{"bioma": "Enjambre", "mov": Dot.Movimiento.ENJAMBRE,
		"meta": Meta.SEGUNDOS, "valor": 60, "escalon": 3,
		"pista": "con el grupo tan junto, la tentación de tocar todo el rato te mata"},

	# --- Billar: chocan entre ellos. Nada se queda quieto -------------------
	{"bioma": "Billar", "mov": Dot.Movimiento.CHOQUE,
		"meta": Meta.PUNTOS, "valor": 400, "escalon": 2,
		"pista": "chocan entre ellos, así que los grupos se deshacen solos"},
	{"bioma": "Billar", "mov": Dot.Movimiento.CHOQUE,
		"meta": Meta.CADENA, "valor": 7, "escalon": 3,
		"pista": "apunta a donde van a estar, no a donde están"},
	{"bioma": "Billar", "mov": Dot.Movimiento.CHOQUE,
		"meta": Meta.SEGUNDOS, "valor": 55, "escalon": 3,
		"pista": "un choque puede regalarte la cadena o arruinártela"},

	# --- Panal: abeja. Tirones y giros bruscos, dificil de leer ------------
	{"bioma": "Panal", "mov": Dot.Movimiento.ABEJA,
		"meta": Meta.PUNTOS, "valor": 450, "escalon": 3,
		"pista": "van a tirones: mira hacia dónde salen, no dónde están"},
	{"bioma": "Panal", "mov": Dot.Movimiento.ABEJA,
		"meta": Meta.CADENA, "valor": 7, "escalon": 3,
		"pista": "los grupos duran un instante; hay que tocar en cuanto se forman"},
	{"bioma": "Panal", "mov": Dot.Movimiento.ABEJA,
		"meta": Meta.PUNTOS_LIMPIOS, "valor": 300, "escalon": 4,
		"pista": "un fallo y se acabó, y encima no se están quietos"},

	# --- Estampida: huyen de tus ondas. El bioma que se defiende -----------
	{"bioma": "Estampida", "mov": Dot.Movimiento.HUIDA,
		"meta": Meta.CADENA, "valor": 6, "escalon": 2,
		"pista": "huyen de tus explosiones: atrapa a los vecinos antes de que escapen"},
	{"bioma": "Estampida", "mov": Dot.Movimiento.HUIDA,
		"meta": Meta.PUNTOS, "valor": 420, "escalon": 2,
		"pista": "cada onda dispersa lo que estabas cazando; encadena corto y seguido"},
	{"bioma": "Estampida", "mov": Dot.Movimiento.HUIDA,
		"meta": Meta.CADENA, "valor": 9, "escalon": 3,
		"pista": "solo cae si los pillas antes de que reaccionen"},

	# --- Otoño: la caída de la nieve, pero en hojas y en calido -------------
	{"bioma": "Otoño", "mov": Dot.Movimiento.NIEVE,
		"meta": Meta.PUNTOS, "valor": 350, "escalon": 2,
		"pista": "caen girando; son grandes y lentas, aprovecha"},
	{"bioma": "Otoño", "mov": Dot.Movimiento.NIEVE,
		"meta": Meta.CADENA, "valor": 8, "escalon": 3,
		"pista": "la caída las alinea en columnas: espera a la más poblada"},
	{"bioma": "Otoño", "mov": Dot.Movimiento.NIEVE,
		"meta": Meta.SEGUNDOS, "valor": 55, "escalon": 3,
		"pista": "el bioma más amable del juego, aprovéchalo para respirar"},

	# --- Brasas: la nieve del reves. Se caza hacia arriba -------------------
	{"bioma": "Brasas", "mov": Dot.Movimiento.BRASA,
		"meta": Meta.PUNTOS, "valor": 400, "escalon": 3,
		"pista": "suben en vez de caer; el ojo tarda en acostumbrarse"},
	{"bioma": "Brasas", "mov": Dot.Movimiento.BRASA,
		"meta": Meta.CADENA, "valor": 8, "escalon": 3,
		"pista": "se apiñan al subir: el mejor momento es a media altura"},
	{"bioma": "Brasas", "mov": Dot.Movimiento.BRASA,
		"meta": Meta.PUNTOS_LIMPIOS, "valor": 350, "escalon": 4,
		"pista": "un fallo y se acabó, y aquí todo va hacia arriba"},

	# --- Caza de robots: pocos, esquivos y con un tiron antes de cada giro -
	{"bioma": "Caza de robots", "mov": Dot.Movimiento.PATRULLA,
		"meta": Meta.PUNTOS, "valor": 420, "escalon": 3,
		"pista": "se paran un instante antes de virar: ese es tu momento"},
	{"bioma": "Caza de robots", "mov": Dot.Movimiento.PATRULLA,
		"meta": Meta.CADENA, "valor": 7, "escalon": 4,
		"pista": "cuesta juntarlos; cuando coincidan tres, no lo pienses"},
	{"bioma": "Caza de robots", "mov": Dot.Movimiento.PATRULLA,
		"meta": Meta.SEGUNDOS, "valor": 50, "escalon": 4,
		"pista": "entran por los cuatro lados: no te quedes mirando a uno"},

	# --- Circuito: angulos rectos. Predecible pero exigente ----------------
	{"bioma": "Circuito", "mov": Dot.Movimiento.CIRCUITO,
		"meta": Meta.PUNTOS, "valor": 450, "escalon": 3,
		"pista": "solo giran noventa grados: por una vez puedes predecirlos"},
	{"bioma": "Circuito", "mov": Dot.Movimiento.CIRCUITO,
		"meta": Meta.CADENA, "valor": 9, "escalon": 4,
		"pista": "los cruces son donde se juntan; espera al cruce"},
	{"bioma": "Circuito", "mov": Dot.Movimiento.CIRCUITO,
		"meta": Meta.CADENA, "valor": 11, "escalon": 5,
		"pista": "los cruces son tuyos si sabes esperarlos"},

	# --- Ciudad de papel: planean sobre una ciudad encendida ---------------
	{"bioma": "Ciudad de papel", "mov": Dot.Movimiento.PLANEO,
		"meta": Meta.PUNTOS, "valor": 380, "escalon": 2,
		"pista": "planean y viran despacio; ningún tramo es recto del todo"},
	{"bioma": "Ciudad de papel", "mov": Dot.Movimiento.PLANEO,
		"meta": Meta.CADENA, "valor": 8, "escalon": 3,
		"pista": "míralos un segundo entero antes de decidir a cuál tocas"},
	{"bioma": "Ciudad de papel", "mov": Dot.Movimiento.PLANEO,
		"meta": Meta.SEGUNDOS, "valor": 55, "escalon": 3,
		"pista": "abajo la ciudad sigue encendida; aquí solo hay que aguantar"},

	# --- Ducha: burbujas que suben. El bioma mas amable de todos -----------
	{"bioma": "Ducha", "mov": Dot.Movimiento.BRASA,
		"meta": Meta.PUNTOS, "valor": 320, "escalon": 1,
		"pista": "suben despacio desde el agua; tómate tu tiempo"},
	{"bioma": "Ducha", "mov": Dot.Movimiento.BRASA,
		"meta": Meta.CADENA, "valor": 8, "escalon": 2,
		"pista": "se apiñan al subir: espera a que la columna se junte"},
	{"bioma": "Ducha", "mov": Dot.Movimiento.BRASA,
		"meta": Meta.SEGUNDOS, "valor": 50, "escalon": 2,
		"pista": "aquí no hay prisa, solo hay que aguantar"},

	# --- Fiesta: globos que chocan entre si --------------------------------
	{"bioma": "Fiesta", "mov": Dot.Movimiento.CHOQUE,
		"meta": Meta.PUNTOS, "valor": 420, "escalon": 2,
		"pista": "rebotan entre ellos: los grupos se hacen y se deshacen solos"},
	{"bioma": "Fiesta", "mov": Dot.Movimiento.CHOQUE,
		"meta": Meta.CADENA, "valor": 9, "escalon": 3,
		"pista": "un choque puede regalarte la cadena o arruinártela"},
	{"bioma": "Fiesta", "mov": Dot.Movimiento.CHOQUE,
		"meta": Meta.SEGUNDOS, "valor": 55, "escalon": 3,
		"pista": "el racimo cambia de forma cada segundo; no te enamores de uno"},

	# --- Asedio: caen sobre la ciudad --------------------------------------
	{"bioma": "Asedio", "mov": Dot.Movimiento.BOMBARDEO,
		"meta": Meta.SEGUNDOS, "valor": 40, "escalon": 1,
		"pista": "caen sobre la ciudad: si uno toca el suelo, se acabó"},
	{"bioma": "Asedio", "mov": Dot.Movimiento.BOMBARDEO,
		"meta": Meta.PUNTOS, "valor": 400, "escalon": 2,
		"pista": "zigzaguean, así que no basta con mirar dónde están ahora"},
	{"bioma": "Asedio", "mov": Dot.Movimiento.BOMBARDEO,
		"meta": Meta.SEGUNDOS, "valor": 65, "escalon": 3,
		"pista": "aguanta el bombardeo entero"},

	# --- Lluvia de meteoros: todos caen hacia el planeta --------------------
	{"bioma": "Lluvia de meteoros", "mov": Dot.Movimiento.METEORO,
		"meta": Meta.SEGUNDOS, "valor": 40, "escalon": 1,
		"pista": "van todos a la Tierra: si uno llega, se acabó"},
	{"bioma": "Lluvia de meteoros", "mov": Dot.Movimiento.METEORO,
		"meta": Meta.PUNTOS, "valor": 420, "escalon": 2,
		"pista": "aceleran al caer, así que el que ignoras ahora vuelve peor"},
	{"bioma": "Lluvia de meteoros", "mov": Dot.Movimiento.METEORO,
		"meta": Meta.SEGUNDOS, "valor": 70, "escalon": 3,
		"pista": "el último de todos. Aguanta la lluvia entera"},
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
		"telon": Fondo.Tipo.ESTRELLAS, "fugaces": true,
		"forma": Dot.Forma.ESTRELLA,
		"fondo": "070b16", "punto": "fdfbff", "onda": "8ec5ff", "radio": 9.0},
	"Invierno": {
		"telon": Fondo.Tipo.COPOS,
		"banda": Fondo.Tipo.AURORA, "banda_color": "6bffc4",
		"forma": Dot.Forma.COPO,
		"fondo": "0f2033", "punto": "f4fbff", "onda": "8fd8ff", "radio": 10.0},
	"Río": {
		"telon": Fondo.Tipo.CORRIENTE,
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
	"Enjambre": {
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
		"fondo": "180f26", "punto": "ff8ad0", "onda": "ff5fd0", "radio": 11.0},
	"Asedio": {
		"telon": Fondo.Tipo.ESTELAS,
		"banda": Fondo.Tipo.HORIZONTE_ROTO, "banda_color": "ff7a3c",
		"forma": Dot.Forma.MISIL,
		# Caen más despacio pero salen mucho más seguido: la amenaza no es la
		# velocidad de cada proyectil sino cuántos hay bajando a la vez.
		# El reloj pasa a segundo plano: aquí la amenaza es la ciudad, no la barra.
		# Con el desagüe normal se perdía por tiempo a los 11 s mientras los
		# proyectiles tardaban 21 s en llegar abajo, así que la mecánica del
		# bioma no llegaba ni a entrar en juego.
		"vel_mult": 0.8, "respawn_mult": 1.2, "targets": 10, "drain_mult": 0.45,
		# Si uno llega abajo, revienta en la ciudad y se acabó la partida.
		"defender": true,
		"fondo": "140809", "punto": "ffd9cc", "onda": "ff4530", "radio": 9.0},
	"Lluvia de meteoros": {
		"telon": Fondo.Tipo.ESTRELLAS, "marco": Fondo.Marco.PLANETA,
		"forma": Dot.Forma.METEORO,
		# Entran despacio y van acelerando solos, así que el multiplicador de
		# velocidad es bajo a propósito: lo que aprieta es el tiempo que llevan
		# cayendo, no con qué rapidez salieron.
		"vel_mult": 0.3, "respawn_mult": 1.1, "targets": 12, "drain_mult": 0.45,
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


## Los biomas aptos para el modo sin fin.
##
## Quedan fuera los de defensa: perder porque un proyectil tocó el suelo tiene
## sentido en un nivel que avisa de ello, pero en una partida sin fin aparecería
## de la nada a los tres minutos y se leería como una injusticia.
static func biomas_sinfin() -> Array:
	var aptos: Array = []
	for b in biomas():
		if not bool(PALETAS.get(b, {}).get("defender", false)):
			aptos.append(b)
	return aptos


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
	match int(n["meta"]):
		Meta.PUNTOS:
			return "llega a %d puntos" % n["valor"]
		Meta.CADENA:
			return "haz una cadena de ×%d" % n["valor"]
		Meta.LIMPIAS:
			return "vacía la pantalla %d %s" % [n["valor"], "vez" if n["valor"] == 1 else "veces"]
		Meta.SEGUNDOS:
			return "aguanta %d segundos" % n["valor"]
		Meta.PUNTOS_LIMPIOS:
			return "llega a %d puntos sin fallar" % n["valor"]
	return ""


## Progreso actual como "23 / 60", para el HUD.
static func progreso(i: int, puntos: int, cadena: int, limpias: int, segundos: float) -> String:
	var n := nivel(i)
	var v: int = n["valor"]
	match int(n["meta"]):
		Meta.PUNTOS, Meta.PUNTOS_LIMPIOS:
			return "%d / %d" % [puntos, v]
		Meta.CADENA:
			return "×%d / ×%d" % [cadena, v]
		Meta.LIMPIAS:
			return "%d / %d" % [limpias, v]
		Meta.SEGUNDOS:
			return "%d / %d s" % [int(segundos), v]
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
