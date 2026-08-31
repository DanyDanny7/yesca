class_name Diagnostico
extends RefCounted

## Caja negra del juego.
##
## Existe porque hay un cierre que solo ocurre en el teléfono, donde no hay
## consola a la vista. Escribe migas de pan a un fichero **volcando en cada
## línea**, de forma que si el proceso muere de golpe lo escrito sobrevive. Al
## arrancar, el registro de la sesión anterior se guarda aparte y se puede leer
## desde el propio juego.
##
## El volcado por línea es caro y por eso las instantáneas van espaciadas: lo que
## importa no es el detalle continuo sino las últimas líneas antes del corte.

const RUTA_ACTUAL := "user://sesion.log"
const RUTA_PREVIA := "user://sesion_anterior.log"
## Marca que se escribe al cerrar bien.
const MARCA_CIERRE := "CIERRE LIMPIO"
## Marca de que la aplicación se fue al fondo.
##
## En Android, mandar la app al segundo plano o cerrarla desde el sistema no
## siempre dispara el cierre limpio: el proceso puede morir después sin avisar.
## Sin esta marca, salirse del juego contaba como si hubiera reventado, que es
## exactamente el falso positivo que hace inútil un detector de fallos.
const MARCA_PAUSA := "EN SEGUNDO PLANO"

## Contenido de la sesión anterior, para enseñarlo en pantalla.
var informe_previo: String = ""
## Si la sesión anterior terminó sin la marca de cierre.
var hubo_cierre_brusco: bool = false

var _f: FileAccess
var _t0: int = 0


func _init() -> void:
	_t0 = Time.get_ticks_msec()

	if FileAccess.file_exists(RUTA_ACTUAL):
		var previo := FileAccess.open(RUTA_ACTUAL, FileAccess.READ)
		if previo:
			informe_previo = previo.get_as_text()
			previo.close()
			hubo_cierre_brusco = _acabo_mal(informe_previo)
			var copia := FileAccess.open(RUTA_PREVIA, FileAccess.WRITE)
			if copia:
				copia.store_string(informe_previo)
				copia.close()

	_f = FileAccess.open(RUTA_ACTUAL, FileAccess.WRITE)
	evento("--- sesion nueva ---")
	evento("modelo=%s  android=%s" % [OS.get_model_name(), OS.get_version()])
	evento("gpu=%s  driver=%s" % [
		RenderingServer.get_video_adapter_name(),
		RenderingServer.get_video_adapter_api_version()])
	# El renderizador se anota porque fue la causa del primer cierre: la GPU
	# Xclipse del telefono de pruebas no tiene OpenGL nativo y Android servia
	# una traduccion por ANGLE que se caia sola.
	evento("renderizador=%s  procesadores=%d" % [
		ProjectSettings.get_setting("rendering/renderer/rendering_method.mobile", "?"),
		OS.get_processor_count()])


## Una sesión acabó mal si su ÚLTIMA línea no es una despedida.
##
## Mirar si la marca aparece en cualquier parte del texto no sirve: una sesión
## que se va al fondo, vuelve y luego revienta tendría la marca en medio y
## pasaría por buena.
static func _acabo_mal(texto: String) -> bool:
	var lineas := texto.strip_edges().split("\n", false)
	if lineas.is_empty():
		return false
	var ultima: String = lineas[lineas.size() - 1]
	return not (ultima.contains(MARCA_CIERRE) or ultima.contains(MARCA_PAUSA))


func al_fondo() -> void:
	evento(MARCA_PAUSA)


func vuelve() -> void:
	evento("vuelve del segundo plano")


func evento(texto: String) -> void:
	if _f == null:
		return
	_f.store_line("%7.2f  %s" % [float(Time.get_ticks_msec() - _t0) / 1000.0, texto])
	# Volcar en cada línea es lo único que garantiza que sobreviva a un cierre
	# brusco. Sin esto el buffer se pierde justo cuando más falta hace.
	_f.flush()


## Foto del estado. Los nombres van cortos para que quepan en pantalla.
func instantanea(datos: Dictionary) -> void:
	var partes: Array[String] = []
	for clave in datos:
		partes.append("%s=%s" % [clave, datos[clave]])
	evento(" ".join(partes))


func cerrar_limpio() -> void:
	evento(MARCA_CIERRE)
	if _f:
		_f.close()
		_f = null


## Errores que haya registrado el propio motor.
##
## Es la mitad que falta: `Diagnostico` solo ve lo que el juego decide anotar,
## mientras que aquí caen los errores de script y del motor, que son los que
## suelen tumbar el proceso. Se filtra porque el registro completo son cientos
## de líneas de arranque que no dicen nada.
func errores_del_motor(n: int) -> String:
	var ruta := "user://logs/godot.log"
	if not FileAccess.file_exists(ruta):
		return ""
	var f := FileAccess.open(ruta, FileAccess.READ)
	if f == null:
		return ""
	var texto := f.get_as_text()
	f.close()

	var interesantes: Array[String] = []
	for linea in texto.split("\n", false):
		var l := linea.strip_edges()
		var interesa := l.begins_with("ERROR") or l.begins_with("SCRIPT ERROR")
		interesa = interesa or l.begins_with("WARNING") or l.begins_with("at:")
		interesa = interesa or l.contains("Cannot") or l.contains("Invalid")
		if interesa:
			interesantes.append(l)
	if interesantes.is_empty():
		return ""
	var desde := maxi(0, interesantes.size() - n)
	return "\n".join(interesantes.slice(desde))


## Las últimas líneas, que son las que importan: lo que pasó justo antes del
## corte.
func ultimas_lineas(n: int) -> String:
	if informe_previo.is_empty():
		return "no hay registro de una sesion anterior."
	var lineas := informe_previo.split("\n", false)
	var desde := maxi(0, lineas.size() - n)
	var salida: Array[String] = []
	for i in range(desde, lineas.size()):
		salida.append(lineas[i])
	return "\n".join(salida)
