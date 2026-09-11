class_name Hormiguero
extends RefCounted

## Las hormigas caminan por dentro del nido, de cámara en cámara.
##
## Antes usaban el movimiento genérico —rumbo libre por todo el campo— y eso es
## lo que rompía la ficción: el nido está dibujado con cámaras y galerías, y las
## hormigas lo ignoraban, cruzaban la tierra maciza y se paraban en medio de
## nada.
##
## La consecuencia buena es de juego, no de dibujo: el jugador deja de perseguir
## puntos sueltos y empieza a ver TRÁFICO —por dónde viene la fila, qué cruce se
## va a llenar—, que es lo que hace que treinta y cuatro objetivos lentos sean
## una situación y no un enjambre.
##
## Todo el paseo se calcula en UNIDADES del lienzo del nido y solo se convierte a
## píxeles al posar cada hormiga. Así el recorrido no cambia con la resolución:
## en una pantalla más ancha se ve más nido, no un nido distinto.

const RUTA_GRAFO := "res://movimientos/hormigas_grafo.json"

## Peso de darse la vuelta por donde se vino. No es cero: una hormiga que JAMÁS
## retrocede se queda dando vueltas al mismo circuito para siempre.
const PESO_RETROCESO := 0.05
## Cuánto se prefiere seguir recto, y a partir de qué alineación cuenta como
## recto. Es lo que convierte una caminata aleatoria en una fila que va a algún
## sitio.
const PESO_RECTO := 2.6
const COS_RECTO := 0.6
## Lo que se retrasa la hormiga que nace, por detrás del nodo, en unidades.
## Aparece caminando, no de golpe.
const NACE_DETRAS := 9.0

var grafo: Grafo = null

# --- Parámetros. Los pone Main desde sus @export ---------------------------
var vel: float = 34.0
var vel_dispersion := Vector2(0.85, 1.15)
var siembra: int = 12
var entrada_cada: float = 0.35
var giro: float = 0.18
var media_vuelta: float = 0.25
var pausa_camara: float = 0.12
var pausa: Vector2 = Vector2(0.3, 0.9)
var espera_max: float = 1.2
var reentrada := Vector2(0.5, 1.5)
var objetivo: int = 34
var reaparece_cada: float = 0.45
var nodo_descanso: float = 2.5
var margen_detonacion: float = 3.0

# --- Estado ---------------------------------------------------------------
## Una entrada por hormiga viva: el Dot como clave y su paseo como valor.
var _paseo := {}
## Cuántas hormigas tienen cogido cada nodo. Una hormiga reserva SIEMPRE un
## nodo y solo uno —al que va—, así que el que acaba de dejar queda libre al
## instante para la de detrás. Es lo que permite que se formen filas sin
## escribir ninguna regla de fila.
var _reservas := PackedInt32Array()
## Reloj del último parto de cada nodo, para que no escupa hormigas seguidas.
var _parto := PackedFloat32Array()

var _reloj: float = 0.0
## Las que faltan por entrar caminando desde la superficie al empezar.
var _por_entrar: int = 0
var _entrada_t: float = 0.0
var _lado: int = 0
var _reaparece_t: float = 0.0
var _detonacion := Vector2.ZERO
var _hay_detonacion := false
var _radio_contagio: float = 9.0


## Deja el hormiguero listo. Devuelve false si el grafo no se pudo cargar, y
## entonces quien llama debe seguir con el movimiento genérico: es preferible
## una hormiga que cruza la tierra a un bioma que no se puede jugar.
func preparar(radio_contagio: float) -> bool:
	grafo = Grafo.cargar(RUTA_GRAFO)
	if grafo == null or grafo.total() == 0:
		return false
	_radio_contagio = maxf(1.0, radio_contagio)
	_paseo.clear()
	_reservas.resize(grafo.total())
	_parto.resize(grafo.total())
	for i in grafo.total():
		_reservas[i] = 0
		# Arranca en negativo para que la siembra no tenga que esperar el
		# descanso del nodo: al empezar la partida no hay nada que disimular.
		_parto[i] = -nodo_descanso
	_reloj = 0.0
	_entrada_t = 0.0
	_reaparece_t = 0.0
	_lado = 0
	_hay_detonacion = false
	_por_entrar = 0
	return true


## Cuántas hormigas hay ahora mismo, contando las que están fuera del lienzo.
func vivas() -> int:
	return _paseo.size()


## Le dice al hormiguero dónde acaba de estallar algo.
##
## No es para que las hormigas huyan —no huyen, ver la entrega— sino para no
## repoblar dentro del anillo mientras la cadena sigue corriendo.
func detonacion(pos_pantalla: Vector2, pantalla: Vector2) -> void:
	if grafo == null:
		return
	var e := grafo.escala(pantalla)
	if e <= 0.0:
		return
	_detonacion = Vector2(pos_pantalla.x / e,
			grafo.alto - (pantalla.y - pos_pantalla.y) / e)
	_hay_detonacion = true


## Una hormiga se fue: suelta su nodo.
func baja(d: Dot) -> void:
	if not _paseo.has(d):
		return
	_soltar(int(_paseo[d]["reserva"]))
	_paseo.erase(d)


## Siembra inicial: unas cuantas repartidas por el nido y el resto entrando.
##
## El nido no se llena de golpe a propósito: la primera media docena de segundos
## se ve LLEGAR la colonia, que es la mejor manera de enseñar por dónde se entra
## y por dónde se sale sin un solo cartel.
##
## Las sembradas van solo en cámaras y solo de `y >= 180` hacia abajo: en tableta
## 4:3 la galería de superficie queda fuera del recorte, y sembrar ahí sería
## empezar la partida con objetivos que el jugador no puede ver ni tocar.
func sembrar(pantalla: Vector2, crear: Callable) -> void:
	if grafo == null:
		return
	var candidatos: Array[int] = []
	for i in grafo.total():
		if grafo.es_camara(i) and grafo.pos(i).y >= 180.0:
			candidatos.append(i)
	candidatos.shuffle()

	var puestas := 0
	for i in candidatos:
		if puestas >= siembra:
			break
		if _reservas[i] >= grafo.cupo(i):
			continue
		var d: Dot = crear.call()
		if d == null:
			return
		_alta(d, i, pantalla)
		puestas += 1

	_por_entrar = maxi(0, objetivo - puestas)
	_entrada_t = 0.0


## El paso de todas las hormigas. Main la llama en vez de mover los Dots.
func actualizar(delta: float, pantalla: Vector2, crear: Callable) -> void:
	if grafo == null:
		return
	_reloj += delta
	_barrer()
	_tick_entrada(delta, pantalla, crear)
	_tick_reaparicion(delta, pantalla, crear)
	for d in _paseo.keys():
		if is_instance_valid(d):
			_andar(d, _paseo[d], delta, pantalla)


# --- Altas -----------------------------------------------------------------

## Pone una hormiga en un nodo, ya caminando hacia un vecino libre.
func _alta(d: Dot, nodo: int, pantalla: Vector2) -> void:
	var p := {
		"nodo": nodo,
		"prev": -1,
		"sig": -1,
		"reserva": nodo,
		"desde": grafo.pos(nodo),
		"hasta": grafo.pos(nodo),
		"t": 1.0,
		"vel": randf_range(vel_dispersion.x, vel_dispersion.y),
		"pausa": 0.0,
		"espera": 0.0,
		"fuera": 0.0,
		"dir": Vector2.RIGHT,
		"giro_de": Vector2.RIGHT,
		"giro_a": Vector2.RIGHT,
		"giro_t": 1.0,
		"giro_dur": giro,
	}
	_reservas[nodo] += 1
	_parto[nodo] = _reloj
	_paseo[d] = p
	d.position = grafo.a_pantalla(grafo.pos(nodo), pantalla)
	_elegir(p, pantalla)
	# Nace nueve unidades por detrás del nodo, dentro de la arista de la que
	# viene, con el morro ya puesto: aparecer clavada en el nodo se lee como un
	# objeto que se materializa, y este bioma no desvanece nada.
	if int(p["sig"]) >= 0:
		var dir: Vector2 = p["dir"]
		var atras: Vector2 = grafo.pos(nodo) - dir * NACE_DETRAS
		p["desde"] = atras
		var meta: Vector2 = p["hasta"]
		var largo := (meta - atras).length()
		p["t"] = 0.0 if largo <= 0.0 else clampf(NACE_DETRAS / largo, 0.0, 0.9)
	_posar(d, p, pantalla)


# --- El paseo --------------------------------------------------------------

func _andar(d: Dot, p: Dictionary, delta: float, pantalla: Vector2) -> void:
	# Fuera del lienzo: se ha ido por un extremo de la superficie y vuelve por el
	# otro. No hay rebote ni envoltura; el nido tiene dos puertas y son esas.
	if float(p["fuera"]) > 0.0:
		p["fuera"] = float(p["fuera"]) - delta
		if float(p["fuera"]) <= 0.0:
			_reentrar(d, p, pantalla)
		return

	_girar(p, delta)

	if float(p["pausa"]) > 0.0:
		p["pausa"] = float(p["pausa"]) - delta
		_posar(d, p, pantalla)
		return

	if int(p["sig"]) < 0:
		# Sin arista elegida: espera a que se libere y, pasado el tope, pasa
		# igual. Un atasco permanente es un objetivo que el jugador no puede
		# leer, y eso es peor que dos hormigas rozándose en un cruce.
		p["espera"] = float(p["espera"]) + delta
		_elegir(p, pantalla, float(p["espera"]) >= espera_max)
		_posar(d, p, pantalla)
		return

	var desde: Vector2 = p["desde"]
	var hasta: Vector2 = p["hasta"]
	var largo := (hasta - desde).length()
	if largo <= 0.001:
		p["t"] = 1.0
	else:
		p["t"] = float(p["t"]) + (vel * float(p["vel"]) * delta) / largo

	if float(p["t"]) < 1.0:
		_posar(d, p, pantalla)
		return

	# Llegó. Suelta el nodo que dejó atrás y se queda con este.
	p["t"] = 1.0
	p["prev"] = int(p["nodo"])
	p["nodo"] = int(p["sig"])
	p["sig"] = -1
	p["espera"] = 0.0

	if int(p["nodo"]) == -2:
		# El -2 es la puerta: sale del lienzo y vuelve por el otro lado.
		_salir(d, p)
		return

	# En cámara se para de vez en cuando. Es lo que separa una hormiga de un
	# coche: una hormiga llega a un sitio y se queda un momento.
	if grafo.es_camara(int(p["nodo"])) and randf() < pausa_camara:
		p["pausa"] = randf_range(pausa.x, pausa.y)

	_elegir(p, pantalla)
	_posar(d, p, pantalla)


## Elige la siguiente arista por peso y sortea. Sin memoria de ruta ni destino:
## el recorrido sale del grafo, no de una lista.
func _elegir(p: Dictionary, pantalla: Vector2, forzar := false) -> void:
	var nodo := int(p["nodo"])
	if nodo < 0:
		return
	var actual: Vector2 = p["dir"]
	var opciones: Array[int] = []
	var pesos: Array[float] = []
	var suma := 0.0

	for v in grafo.vecinos[nodo]:
		var peso := 1.0
		if v == int(p["prev"]):
			peso = PESO_RETROCESO
		var dir := (grafo.pos(v) - grafo.pos(nodo)).normalized()
		if actual.dot(dir) > COS_RECTO:
			peso *= PESO_RECTO
		if not forzar and _reservas[v] >= grafo.cupo(v):
			peso = 0.0
		if peso > 0.0:
			opciones.append(v)
			pesos.append(peso)
			suma += peso

	# La puerta cuenta como una salida más, solo desde los nodos que la tienen.
	# Sin esto los extremos de la galería de superficie serían callejones y las
	# hormigas rebotarían contra el borde del lienzo en vez de irse.
	for e in grafo.entradas:
		if int(e["nodo"]) == nodo:
			opciones.append(-2)
			pesos.append(1.0)
			suma += 1.0

	if opciones.is_empty():
		# Callejón de verdad: media vuelta, girando sobre sí misma.
		if grafo.vecinos[nodo].size() == 1 and not forzar:
			var unico := grafo.vecinos[nodo][0]
			if _reservas[unico] < grafo.cupo(unico):
				_tomar(p, unico, pantalla, media_vuelta)
		return

	var tirada := randf() * suma
	var elegido := opciones[opciones.size() - 1]
	for i in opciones.size():
		tirada -= pesos[i]
		if tirada <= 0.0:
			elegido = opciones[i]
			break

	if elegido == -2:
		_tomar_puerta(p, nodo)
		return
	_tomar(p, elegido, pantalla, giro)


## Se compromete con una arista: reserva el nodo de destino y suelta el anterior.
func _tomar(p: Dictionary, v: int, _pantalla: Vector2, dur_giro: float) -> void:
	_soltar(int(p["reserva"]))
	_reservas[v] += 1
	p["reserva"] = v
	p["sig"] = v
	p["desde"] = grafo.pos(int(p["nodo"]))
	p["hasta"] = grafo.pos(v)
	p["t"] = 0.0
	p["espera"] = 0.0
	var nueva := (grafo.pos(v) - grafo.pos(int(p["nodo"]))).normalized()
	p["giro_de"] = p["dir"]
	p["giro_a"] = nueva
	p["giro_t"] = 0.0
	p["giro_dur"] = maxf(0.01, dur_giro)


## Se va por la puerta: camina hasta fuera del lienzo y desaparece un rato.
func _tomar_puerta(p: Dictionary, nodo: int) -> void:
	for e in grafo.entradas:
		if int(e["nodo"]) != nodo:
			continue
		_soltar(int(p["reserva"]))
		p["reserva"] = -1
		p["sig"] = -2
		p["desde"] = grafo.pos(nodo)
		p["hasta"] = e["pos"]
		p["t"] = 0.0
		var epos: Vector2 = e["pos"]
		var nueva := (epos - grafo.pos(nodo)).normalized()
		p["giro_de"] = p["dir"]
		p["giro_a"] = nueva
		p["giro_t"] = 0.0
		p["giro_dur"] = maxf(0.01, giro)
		return


func _salir(_d: Dot, p: Dictionary) -> void:
	p["fuera"] = randf_range(reentrada.x, reentrada.y)
	p["nodo"] = -1
	p["prev"] = -1


## Vuelve por el extremo contrario al que salió.
func _reentrar(d: Dot, p: Dictionary, pantalla: Vector2) -> void:
	if grafo.entradas.is_empty():
		return
	var e: Dictionary = grafo.entradas[randi() % grafo.entradas.size()]
	var nodo := int(e["nodo"])
	if _reservas[nodo] >= grafo.cupo(nodo):
		# Ocupada la puerta: espera un poco más en vez de empujar.
		p["fuera"] = 0.25
		return
	_reservas[nodo] += 1
	p["reserva"] = nodo
	p["nodo"] = -1
	p["prev"] = -1
	p["sig"] = nodo
	p["desde"] = e["pos"]
	p["hasta"] = grafo.pos(nodo)
	p["t"] = 0.0
	var epos: Vector2 = e["pos"]
	var dir := (grafo.pos(nodo) - epos).normalized()
	p["dir"] = dir
	p["giro_de"] = dir
	p["giro_a"] = dir
	p["giro_t"] = 1.0
	# El nodo al que llega hay que dejarlo como "nodo" cuando aterrice; hasta
	# entonces camina con nodo = -1, que _andar resuelve al pasar t de 1.
	p["nodo"] = -1
	_posar(d, p, pantalla)


# --- Entrada y reaparición -------------------------------------------------

## Las que faltan por llegar al empezar, una cada tanto y alternando lado.
func _tick_entrada(delta: float, pantalla: Vector2, crear: Callable) -> void:
	if _por_entrar <= 0:
		return
	# El tope es de población, no de cola. Sin esto la cola inicial entregaba
	# sus veintidós aunque el repoblado ya hubiera llenado el nido por su
	# cuenta, y la colonia se iba a cuarenta y una hormigas: medido, doce
	# sembradas más veinte entradas más nueve reapariciones.
	if vivas() >= objetivo:
		return
	_entrada_t -= delta
	if _entrada_t > 0.0:
		return
	_entrada_t = entrada_cada
	if grafo.entradas.is_empty():
		_por_entrar = 0
		return
	var e: Dictionary = grafo.entradas[_lado % grafo.entradas.size()]
	_lado += 1
	var nodo := int(e["nodo"])
	if _reservas[nodo] >= grafo.cupo(nodo):
		return
	var d: Dot = crear.call()
	if d == null:
		return
	_por_entrar -= 1
	_alta(d, nodo, pantalla)
	# Se coloca fuera del lienzo y entra caminando hacia su nodo.
	_paseo[d]["desde"] = e["pos"]
	_paseo[d]["hasta"] = grafo.pos(nodo)
	_paseo[d]["sig"] = nodo
	_paseo[d]["nodo"] = -1
	_paseo[d]["t"] = 0.0
	var epos2: Vector2 = e["pos"]
	var dir := (grafo.pos(nodo) - epos2).normalized()
	_paseo[d]["dir"] = dir
	_paseo[d]["giro_de"] = dir
	_paseo[d]["giro_a"] = dir
	_paseo[d]["giro_t"] = 1.0
	_posar(d, _paseo[d], pantalla)


## Cualquier nodo puede parir una hormiga cuando la cadena vacía el nido.
##
## La condición de vecindario es la que hace que no se note: una hormiga no
## aparece nunca en un tramo que el jugador esté mirando, porque si lo está
## mirando es que hay tráfico, y si hay tráfico el nodo no está vacío. Y la
## distancia a la detonación evita lo peor, que es repoblar dentro del anillo
## mientras la cadena sigue corriendo.
func _tick_reaparicion(delta: float, pantalla: Vector2, crear: Callable) -> void:
	if vivas() >= objetivo:
		return
	_reaparece_t -= delta
	if _reaparece_t > 0.0:
		return
	_reaparece_t = reaparece_cada

	var margen := margen_detonacion * _radio_contagio
	var mejor := -1
	var mejor_dist := -1.0
	for i in grafo.total():
		if _reservas[i] > 0:
			continue
		if _reloj - _parto[i] < nodo_descanso:
			continue
		var libre := true
		for v in grafo.vecinos[i]:
			if _reservas[v] > 0:
				libre = false
				break
		if not libre:
			continue
		var dist := 1.0e9 if not _hay_detonacion else grafo.pos(i).distance_to(_detonacion)
		if _hay_detonacion and dist <= margen:
			continue
		# De los que valen, el más lejos de donde acaba de estallar.
		if dist > mejor_dist:
			mejor_dist = dist
			mejor = i

	if mejor < 0:
		return
	var d: Dot = crear.call()
	if d == null:
		return
	_alta(d, mejor, pantalla)


# --- Auxiliares ------------------------------------------------------------

## Tira las hormigas que ya no existen y suelta sus nodos.
##
## Main avisa con baja() cuando detona una, pero un objetivo puede irse por
## otros caminos —el campo se vacía al cambiar de nivel, la celebración se lleva
## los que quedan— y cada uno de esos sitios es una llamada que se puede olvidar
## al tocar código años después. Medido: con solo el aviso explícito, el nido se
## quedaba con treinta y seis paseos vivos y dieciséis hormigas de verdad, y como
## el repoblado mira ese número, dejaba de nacer nadie. Barrer aquí lo arregla
## pase lo que pase fuera.
func _barrer() -> void:
	var muertas: Array = []
	for d in _paseo:
		if not is_instance_valid(d):
			muertas.append(d)
	for d in muertas:
		_soltar(int(_paseo[d]["reserva"]))
		_paseo.erase(d)


func _soltar(nodo: int) -> void:
	if nodo >= 0 and nodo < _reservas.size():
		_reservas[nodo] = maxi(0, _reservas[nodo] - 1)


## El morro llega al ángulo nuevo en un momento, no de golpe: así el giro se ve
## pero no se nota el codo.
func _girar(p: Dictionary, delta: float) -> void:
	if float(p["giro_t"]) >= 1.0:
		p["dir"] = p["giro_a"]
		return
	p["giro_t"] = minf(1.0, float(p["giro_t"]) + delta / float(p["giro_dur"]))
	var de: Vector2 = p["giro_de"]
	var a: Vector2 = p["giro_a"]
	p["dir"] = de.slerp(a, float(p["giro_t"])) if de.length() > 0.0 else a


## Posa la hormiga en pantalla y le deja el rumbo en `velocity`.
##
## La posición sale del recorrido, no de integrar la velocidad. `velocity` se
## usa solo para orientarla —Giro.RUMBO lee su ángulo— y por eso lleva la
## dirección SUAVIZADA y no la de la arista: durante el giro el morro va un poco
## por delante del camino, que es justo lo que se quiere ver.
func _posar(d: Dot, p: Dictionary, pantalla: Vector2) -> void:
	var desde: Vector2 = p["desde"]
	var hasta: Vector2 = p["hasta"]
	var u := desde.lerp(hasta, clampf(float(p["t"]), 0.0, 1.0))
	d.position = grafo.a_pantalla(u, pantalla)
	var dir: Vector2 = p["dir"]
	if dir.length_squared() > 0.0:
		d.velocity = dir * maxf(2.0, vel * grafo.escala(pantalla))
