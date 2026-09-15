class_name Textos
extends RefCounted

## Todo el texto que el jugador lee, en un sitio y por idioma.
##
## No usa el sistema de traducción de Godot —`tr()` y ficheros `.po`— a
## propósito. Aquí casi nada es un Label: el HUD se dibuja con `draw_string`,
## así que la parte que Godot resuelve sola —traducir la propiedad `text` de un
## control— no aplicaría. Lo que quedaría sería el importador, y a cambio los
## textos dejarían de poder leerse y editarse como lo que son: una tabla.
##
## Un JSON por idioma en `datos/idiomas/`. Añadir uno es añadir un fichero y su
## entrada en IDIOMAS: no hay que tocar código ni reimportar nada.
##
## ## El registro NO se traduce
##
## `_diag.evento(...)` escribe para quien depura, no para quien juega, y se lee
## junto a nombres de función y de fichero que tampoco están traducidos. Un
## registro mitad en un idioma y mitad en otro es más difícil de leer que uno
## entero en el idioma del código.
##
## ## Los nombres de bioma son DOS cosas
##
## «Río» es a la vez el nombre que se enseña y la clave que busca `rio.png`, la
## tabla de colores del HUD y el manifiesto de astros. Traducir esa cadena
## rompería los assets, así que se separan: la clave se queda en español y sin
## acentos —`Niveles.LISTA` y las paletas siguen igual— y lo que se enseña sale
## de aquí, por esa clave.

const RUTA := "res://datos/idiomas/%s.json"
## El idioma que se usa si el pedido no está o viene roto. Es también el idioma
## en el que están escritas las claves.
const POR_DEFECTO := "es"
## Los que hay. Añadir uno: un fichero en datos/idiomas/ y una línea aquí.
const IDIOMAS := {
	"es": "Español",
	"en": "English",
}

static var _tabla := {}
static var _idioma := ""


## Deja cargado un idioma. Si no se puede, cae al de por defecto.
static func cargar(idioma: String) -> void:
	if idioma == _idioma:
		return
	var leida := _leer(idioma)
	if leida.is_empty() and idioma != POR_DEFECTO:
		push_warning("Textos: no pude leer '%s', uso '%s'" % [idioma, POR_DEFECTO])
		leida = _leer(POR_DEFECTO)
		idioma = POR_DEFECTO
	_tabla = leida
	_idioma = idioma


static func idioma() -> String:
	return _idioma if not _idioma.is_empty() else POR_DEFECTO


static func _leer(idioma: String) -> Dictionary:
	var ruta := RUTA % idioma
	if not FileAccess.file_exists(ruta):
		return {}
	var datos = JSON.parse_string(FileAccess.get_file_as_string(ruta))
	return datos if typeof(datos) == TYPE_DICTIONARY else {}


## El texto de una clave, con sus huecos rellenos.
##
## Si la clave falta devuelve la CLAVE, no una cadena vacía: un hueco en blanco
## en pantalla no dice qué falta, y la clave sí. Es la diferencia entre una
## traducción incompleta que se puede arreglar y una que hay que buscar.
static func t(clave: String, args: Array = []) -> String:
	if _idioma.is_empty():
		cargar(POR_DEFECTO)
	var linea: String = str(_tabla.get(clave, clave))
	if args.is_empty():
		return linea
	return linea % args


## Como t(), pero eligiendo entre singular y plural según un número.
##
## Va aparte porque el plural no se resuelve igual en todos los idiomas y meterlo
## dentro de t() obligaría a que todas las claves cargaran con esa complicación.
static func plural(clave: String, n: int, args: Array = []) -> String:
	var sufijo := "_uno" if n == 1 else "_varios"
	return t(clave + sufijo, args)
