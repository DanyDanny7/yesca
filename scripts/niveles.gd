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
	# --- Campo abierto: rebote. Aqui se aprende a jugar ---------------------
	{"bioma": "Campo abierto", "mov": Dot.Movimiento.REBOTE,
		"meta": Meta.PUNTOS, "valor": 60, "escalon": 0,
		"pista": "toca un círculo y deja que la onda haga el resto"},
	{"bioma": "Campo abierto", "mov": Dot.Movimiento.REBOTE,
		"meta": Meta.CADENA, "valor": 4, "escalon": 0,
		"pista": "busca cuatro juntos, no toques el primero que veas"},
	{"bioma": "Campo abierto", "mov": Dot.Movimiento.REBOTE,
		"meta": Meta.PUNTOS, "valor": 250, "escalon": 1,
		"pista": "cada eslabón vale más que el anterior"},
	{"bioma": "Campo abierto", "mov": Dot.Movimiento.REBOTE,
		"meta": Meta.CADENA, "valor": 6, "escalon": 1,
		"pista": "puedes tener varias cadenas a la vez, cada una con su cuenta"},

	# --- Ventisca: nieve. Lento, para respirar antes de apretar -------------
	{"bioma": "Ventisca", "mov": Dot.Movimiento.NIEVE,
		"meta": Meta.PUNTOS, "valor": 300, "escalon": 1,
		"pista": "caen despacio y en vaivén; el campo se renueva por arriba"},
	{"bioma": "Ventisca", "mov": Dot.Movimiento.NIEVE,
		"meta": Meta.CADENA, "valor": 7, "escalon": 2,
		"pista": "la caída los alinea sola: espera a que la columna se junte"},
	{"bioma": "Ventisca", "mov": Dot.Movimiento.NIEVE,
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
		"meta": Meta.CADENA, "valor": 6, "escalon": 3,
		"pista": "huyen de tus explosiones: atrapa a los vecinos antes de que escapen"},
	{"bioma": "Estampida", "mov": Dot.Movimiento.HUIDA,
		"meta": Meta.PUNTOS, "valor": 500, "escalon": 4,
		"pista": "cada onda dispersa lo que estabas cazando"},
	{"bioma": "Estampida", "mov": Dot.Movimiento.HUIDA,
		"meta": Meta.CADENA, "valor": 9, "escalon": 4,
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

	# --- Circuito: angulos rectos. Predecible pero exigente ----------------
	{"bioma": "Circuito", "mov": Dot.Movimiento.CIRCUITO,
		"meta": Meta.PUNTOS, "valor": 450, "escalon": 3,
		"pista": "solo giran noventa grados: por una vez puedes predecirlos"},
	{"bioma": "Circuito", "mov": Dot.Movimiento.CIRCUITO,
		"meta": Meta.CADENA, "valor": 9, "escalon": 4,
		"pista": "los cruces son donde se juntan; espera al cruce"},
	{"bioma": "Circuito", "mov": Dot.Movimiento.CIRCUITO,
		"meta": Meta.CADENA, "valor": 11, "escalon": 5,
		"pista": "el último de todos. Aquí ya no hay excusas"},
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
	"Campo abierto": {
		"forma": Dot.Forma.CIRCULO,
		"fondo": "0d0d12", "punto": "e8e8f0", "onda": "ff5470", "radio": 9.0},
	"Ventisca": {
		"forma": Dot.Forma.COPO,
		"fondo": "0c1219", "punto": "eef6ff", "onda": "8fd8ff", "radio": 10.0},
	"Río": {
		"forma": Dot.Forma.CIRCULO,
		"fondo": "07161c", "punto": "d6f5ec", "onda": "2fd6c0", "radio": 9.0},
	"Enjambre": {
		"forma": Dot.Forma.CIRCULO,
		"fondo": "150f1a", "punto": "e6d8f7", "onda": "b45cff", "radio": 8.0},
	"Billar": {
		"forma": Dot.Forma.BOLA,
		"fondo": "0a1c13", "punto": "f4efdc", "onda": "ffc24d", "radio": 10.0},
	"Panal": {
		"forma": Dot.Forma.ABEJA,
		"fondo": "17100a", "punto": "ffd24a", "onda": "ff8c1a", "radio": 9.0},
	"Estampida": {
		"forma": Dot.Forma.DRON,
		"fondo": "060a12", "punto": "6feaff", "onda": "ff3b30", "radio": 8.0},
	"Otoño": {
		"forma": Dot.Forma.HOJA,
		"fondo": "1a1208", "punto": "ffb347", "onda": "ff7038", "radio": 11.0},
	"Brasas": {
		"forma": Dot.Forma.CHISPA,
		"fondo": "120806", "punto": "ffca6b", "onda": "ff5a1f", "radio": 8.0},
	"Circuito": {
		"forma": Dot.Forma.CHIP,
		"fondo": "030b07", "punto": "8dffb0", "onda": "34ff88", "radio": 8.0},
}


## La paleta del bioma de un nivel, o la neutra si no la tiene.
static func paleta(i: int) -> Dictionary:
	return PALETAS.get(str(nivel(i)["bioma"]), PALETAS["Campo abierto"])


static func paleta_neutra() -> Dictionary:
	return PALETAS["Campo abierto"]

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
