class_name Niveles
extends RefCounted

## La campaña, como tabla de datos.
##
## Un nivel aquí NO es contenido dibujado a mano: es un objetivo más un escalón
## de partida. Eso es lo que permite tener campaña sin violar la decisión de
## `contexto/00-decisiones.md` de evitar géneros con hambre de contenido —
## añadir un nivel cuesta una fila, no una tarde de arte.
##
## La variedad real no sale de subir números, sale de que el OBJETIVO cambie:
## puntuar, encadenar, limpiar y sobrevivir son cuatro habilidades distintas del
## mismo mecanismo. Los primeros niveles están ordenados para enseñar una cosa
## cada uno.
##
## Pendiente: los biomas de verdad, con reglas propias de movimiento e
## interacción con las explosiones. Este primer bioma usa el comportamiento
## base; añadir más biomas antes de tener esas reglas sería relleno.

enum Meta {
	PUNTOS,          ## llegar a N puntos
	CADENA,          ## conseguir una cadena de xN
	LIMPIAS,         ## vaciar la pantalla N veces
	SEGUNDOS,        ## aguantar N segundos
	PUNTOS_LIMPIOS,  ## llegar a N puntos sin fallar un solo tap
}

const LISTA: Array[Dictionary] = [
	{"bioma": "Campo abierto", "meta": Meta.PUNTOS, "valor": 60, "escalon": 0,
		"pista": "toca un círculo y deja que la onda haga el resto"},
	{"bioma": "Campo abierto", "meta": Meta.CADENA, "valor": 4, "escalon": 0,
		"pista": "busca cuatro juntos, no toques el primero que veas"},
	{"bioma": "Campo abierto", "meta": Meta.PUNTOS, "valor": 250, "escalon": 1,
		"pista": "cada eslabón vale más que el anterior"},
	{"bioma": "Campo abierto", "meta": Meta.LIMPIAS, "valor": 1, "escalon": 1,
		"pista": "espera a que el campo se junte"},
	{"bioma": "Campo abierto", "meta": Meta.CADENA, "valor": 6, "escalon": 2,
		"pista": "tocar durante una cascada la corta y pierdes el multiplicador"},
	{"bioma": "Campo abierto", "meta": Meta.SEGUNDOS, "valor": 45, "escalon": 2,
		"pista": "aquí no puntúas, sobrevives"},
	{"bioma": "Campo abierto", "meta": Meta.PUNTOS_LIMPIOS, "valor": 300, "escalon": 3,
		"pista": "un solo fallo y vuelves a empezar"},
	{"bioma": "Campo abierto", "meta": Meta.CADENA, "valor": 9, "escalon": 4,
		"pista": "con el campo así de rápido, la paciencia es todo"},
]


static func total() -> int:
	return LISTA.size()


static func nivel(i: int) -> Dictionary:
	return LISTA[clampi(i, 0, LISTA.size() - 1)]


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


## Si el nivel se pierde en cuanto fallas un tap.
static func exige_limpieza(i: int) -> bool:
	return int(nivel(i)["meta"]) == Meta.PUNTOS_LIMPIOS
