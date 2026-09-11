class_name Grafo
extends RefCounted

## El hueco de un escenario reducido a nodos y aristas.
##
## Existe porque hay biomas cuyo fondo NO es decorado: el nido de Hormigas tiene
## cámaras y galerías dibujadas, y un target que las ignora y cruza la tierra
## maciza rompe la ficción más de lo que la aporta el dibujo. Con esto, el
## movimiento puede preguntar por dónde se puede pasar.
##
## Va aparte del bioma a propósito. El mismo caminante sirve para Circuito —las
## pistas SON un grafo— y para Ciudad de papel si sus targets llegan a pisar la
## calle; meterlo dentro de Hormigas obligaría a copiarlo dos veces.
##
## Las coordenadas son las del lienzo de la pieza rígida del bioma —para
## Hormigas, 208 x 500 anclado abajo—, así que se transforman EXACTAMENTE igual
## que el telón. Si una tanda futura redibuja el nido hay que volver a medir el
## grafo: el dibujo manda, no al revés.

## Clase de nodo. Un cruce es un paso; una cámara es un sitio donde estar.
enum Clase { CRUCE, CAMARA }

var ancho: float = 0.0
var alto: float = 0.0
## Un diccionario por nodo: pos (Vector2, en unidades), clase, cupo.
var nodos: Array[Dictionary] = []
## Vecinos de cada nodo, por índice. Paralelo a `nodos`.
var vecinos: Array[PackedInt32Array] = []
## Puertas al exterior: pos (fuera del lienzo) y el nodo al que llevan.
var entradas: Array[Dictionary] = []


## Carga un grafo de su JSON. Devuelve null si el fichero falta o viene roto.
##
## Se lee con FileAccess y no como recurso importado: es un dato de diseño que
## se entrega y se vuelve a medir, no un asset, y así se puede sustituir sin
## pasar por el importador.
static func cargar(ruta: String) -> Grafo:
	if not FileAccess.file_exists(ruta):
		push_warning("Grafo: no existe %s" % ruta)
		return null
	var crudo := FileAccess.get_file_as_string(ruta)
	var datos = JSON.parse_string(crudo)
	if typeof(datos) != TYPE_DICTIONARY:
		push_warning("Grafo: %s no es un objeto JSON" % ruta)
		return null

	var g := Grafo.new()
	var lienzo: Dictionary = datos.get("lienzo", {})
	g.ancho = float(lienzo.get("ancho", 0.0))
	g.alto = float(lienzo.get("alto", 0.0))

	for n in datos.get("nodos", []):
		g.nodos.append({
			"pos": Vector2(float(n.get("x", 0.0)), float(n.get("y", 0.0))),
			"clase": Clase.CAMARA if str(n.get("clase", "")) == "camara" else Clase.CRUCE,
			"cupo": maxi(1, int(n.get("cupo", 1))),
		})
		g.vecinos.append(PackedInt32Array())

	# Las aristas vienen como pares y se guardan en los DOS sentidos: el grafo es
	# no dirigido —una galería se recorre para los dos lados— y tenerlo resuelto
	# aquí evita que cada consulta tenga que mirar la lista entera.
	for a in datos.get("aristas", []):
		if typeof(a) != TYPE_ARRAY or a.size() < 2:
			continue
		var i := int(a[0])
		var j := int(a[1])
		if i < 0 or j < 0 or i >= g.nodos.size() or j >= g.nodos.size():
			continue
		if not g.vecinos[i].has(j):
			g.vecinos[i].append(j)
		if not g.vecinos[j].has(i):
			g.vecinos[j].append(i)

	for e in datos.get("entradas", []):
		g.entradas.append({
			"pos": Vector2(float(e.get("x", 0.0)), float(e.get("y", 0.0))),
			"nodo": int(e.get("nodo", 0)),
		})

	return g


func total() -> int:
	return nodos.size()


func pos(i: int) -> Vector2:
	return nodos[i]["pos"]


func es_camara(i: int) -> bool:
	return int(nodos[i]["clase"]) == Clase.CAMARA


func cupo(i: int) -> int:
	return int(nodos[i]["cupo"])


## De unidades del lienzo a píxeles de pantalla.
##
## Repite la transformación del telón en vez de preguntarle: el fondo se dibuja
## en otro nodo y pedirle la matriz acoplaría el movimiento al dibujo. Lo que
## comparten es el contrato —ancho completo, anclado abajo—, y ese no cambia.
func a_pantalla(p: Vector2, pantalla: Vector2) -> Vector2:
	var por_unidad := pantalla.x / ancho
	return Vector2(p.x * por_unidad, pantalla.y - (alto - p.y) * por_unidad)


## Cuántos píxeles mide una unidad del lienzo en esta pantalla.
func escala(pantalla: Vector2) -> float:
	return pantalla.x / ancho
