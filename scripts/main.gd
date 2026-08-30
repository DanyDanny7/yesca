extends Node2D

## Cadena — v4.
##
## Se toca un CÍRCULO, no la pantalla. El círculo tocado explota y su onda
## expansiva contagia a los vecinos, que explotan a su vez. Una barra de tiempo
## baja sola; tocar cuesta tiempo y atrapar lo devuelve. El punto N de una
## cascada vale N, y solo la propagación sube el multiplicador.
## Ver contexto/03-concepto-cadena.md
##
## Dos modos. CAMPAÑA da el cierre: cada nivel tiene un objetivo y se gana o se
## pierde. SIN FIN es la caza del récord. Un juego de pura supervivencia no
## tiene victoria por naturaleza — para que exista un "ganaste" la partida tiene
## que ser finita, y de ahí salen los niveles.
##
## Historial de correcciones en contexto/05, 06 y 07. Las que más marcan este
## código:
##  - el campo es continuo y nunca se borra (v0 iba por rondas y se sentía un
##    bucle cerrado sin avance)
##  - al terminar se congela el mundo entero, o la muerte es invisible
##  - la dificultad manda por reloj, no por puntuación: atarla a la puntuación
##    es una goma elástica que le tapa el techo al buen jugador

# Los parámetros de calibración van como @export para poder moverlos desde el
# inspector con el juego corriendo. Calibrar recompilando es insufrible.

@export_group("Campo")
@export var target_dots: int = 25
@export var dot_speed_min: float = 60.0
@export var dot_speed_max: float = 140.0
## Cuánto se dispersan las rapideces entre círculos. En 0 todos van parecido;
## subiéndolo conviven muy lentos con muy rápidos, y eso cambia la lectura del
## campo más que subir la media.
@export var speed_variance: float = 0.0

## Movimiento con el que probar, ignorando el del nivel. Es la palanca para
## cachear biomas en vivo desde el inspector con el juego corriendo.
@export_group("Pruebas")
@export var forzar_movimiento: bool = false
@export var movimiento_prueba: Dot.Movimiento = Dot.Movimiento.REBOTE

@export_group("Detonación")
## Radio de la detonación del círculo que tocas, mayor que el de las
## detonaciones en cadena: es el valor de haber apuntado bien.
@export var tap_radius: float = 150.0
## Cuánto se perdona la puntería. Un círculo mide 9 px y se mueve; un dedo tapa
## más de 50. La habilidad a premiar es elegir QUÉ círculo, no la precisión.
@export var tap_tolerance: float = 60.0

@export_group("Economía de tiempo")
@export var time_start: float = 10.0
@export var time_max: float = 15.0
## Deliberadamente caro. Con un tap barato la FRECUENCIA compensa la CALIDAD.
@export var tap_cost: float = 2.0
## La mitad del acertado: si costara igual, el margen de fallos sería código
## muerto porque siempre morirías por tiempo antes de agotarlo.
@export var miss_cost: float = 1.0
@export var reward_base: float = 0.4
@export var reward_step: float = 0.18
@export var clear_bonus: float = 3.0

## Manda el RELOJ; la puntuación es solo un acelerador con umbral alto.
@export_group("Escalones")
@export var stage_size: int = 400
@export var stage_seconds: float = 20.0
@export var rest_every: int = 4

@export_subgroup("Presión")
@export var drain_base: float = 0.7
@export var drain_step: float = 0.18

@export_subgroup("Generosidad")
@export var chain_radius_base: float = 105.0
@export var chain_radius_step: float = 3.0
@export var chain_radius_min: float = 75.0

@export_subgroup("Escasez")
@export var respawn_base: float = 0.32
@export var respawn_step: float = 0.03
@export var respawn_max: float = 0.6

@export_subgroup("Legibilidad")
@export var speed_step: float = 8.0

@export_subgroup("Fallos")
@export var fallos_base: int = 5
@export var fallos_step: float = 0.4
@export var fallos_min: int = 3

const SPAWN_MARGIN := 40.0
const WARN_TIME := 3.0
const FLASH_TIME := 1.4
const COMBO_POP_TIME := 0.45
## Caja de la etiqueta flotante de cada cadena.
const COMBO_SIZE := Vector2(240.0, 100.0)
const STAGE_COLOR_TOPE := 10.0
const SAVE_PATH := "user://cadena.cfg"
const NOMBRES_MOV := ["rebote", "abeja", "nieve", "choque", "corriente",
		"enjambre", "huida"]
## Fuerzas de los modos que Main dirige. Bajas a propósito: el movimiento tiene
## que seguir siendo legible, no convertirse en una sopa.
const ENJAMBRE_VISTA := 220.0
const ENJAMBRE_ROCE := 60.0
const ENJAMBRE_ATRACCION := 55.0
const ENJAMBRE_SEPARACION := 110.0
const HUIDA_MARGEN := 120.0
const HUIDA_FUERZA := 420.0

enum State { MENU, SELECT, READY, PLAYING, DEAD, WIN, FINAL }
enum Mode { CAMPANA, SIN_FIN }

@onready var _dots_root: Node2D = $Dots
@onready var _explosions_root: Node2D = $Explosions

@onready var _score_label: Label = $UI/Score
@onready var _best_label: Label = $UI/Best
@onready var _objetivo_label: Label = $UI/Objetivo
@onready var _hint_label: Label = $UI/Hint
@onready var _flash_label: Label = $UI/Flash
@onready var _stage_label: Label = $UI/Stage
@onready var _fallos_label: Label = $UI/Fallos
@onready var _combos_root: Control = $UI/Combos
@onready var _bar_bg: ColorRect = $UI/BarBg
@onready var _bar_fill: ColorRect = $UI/BarBg/BarFill

@onready var _menu_screen: Control = $UI/MenuScreen
@onready var _btn_campana: CircleButton = $UI/MenuScreen/Campana
@onready var _btn_sinfin: CircleButton = $UI/MenuScreen/SinFin
@onready var _menu_best: Label = $UI/MenuScreen/Best

@onready var _select_screen: Control = $UI/SelectScreen
@onready var _sel_bioma: Label = $UI/SelectScreen/Title
@onready var _sel_num: Label = $UI/SelectScreen/Num
@onready var _sel_meta: Label = $UI/SelectScreen/Meta
@onready var _sel_pista: Label = $UI/SelectScreen/Pista
@onready var _btn_prev: CircleButton = $UI/SelectScreen/Prev
@onready var _btn_next: CircleButton = $UI/SelectScreen/Next
@onready var _btn_play: CircleButton = $UI/SelectScreen/Play
@onready var _btn_volver: CircleButton = $UI/SelectScreen/Volver

@onready var _over_screen: Control = $UI/OverScreen
@onready var _over_title: Label = $UI/OverScreen/Title
@onready var _over_score: Label = $UI/OverScreen/Score
@onready var _over_detail: Label = $UI/OverScreen/Detail

@onready var _win_screen: Control = $UI/WinScreen
@onready var _win_title: Label = $UI/WinScreen/Title
@onready var _win_detail: Label = $UI/WinScreen/Detail
@onready var _win_seguir_text: Label = $UI/WinScreen/Seguir/Text

var _hud: Array[Control] = []
var _dots: Array[Dot] = []
var _explosions: Array[Explosion] = []
## Anillos de tap fallado: se dibujan igual pero no contagian, y se llevan
## aparte para que no cuenten como "cascada en curso".
var _effects: Array[Explosion] = []

var _state: State = State.MENU
var _mode: Mode = Mode.SIN_FIN
## Nivel en curso y nivel más alto desbloqueado.
var _nivel: int = 0
var _nivel_max: int = 0
## Escalón de partida que impone el nivel.
var _stage_offset: int = 0

var _time_left: float = 0.0
var _score: int = 0
var _best: int = 0
var _elapsed: float = 0.0
## Cadenas vivas: id -> {"len": int, "pos": Vector2, "pop": float}
##
## Varias a la vez. Cada tap arranca la suya y se propaga por su cuenta con su
## propio multiplicador, así que se puede sembrar una segunda cascada mientras
## la primera todavía se está resolviendo. Con un contador único, encadenar en
## dos sitios daba lo mismo que encadenar en uno.
var _cadenas: Dictionary = {}
var _next_chain: int = 0
## id de cadena -> Label flotante en uso.
var _combo_labels: Dictionary = {}
## Etiquetas libres, listas para reutilizar.
##
## Se reciclan en vez de crearse y liberarse por cadena. Con varias cadenas
## naciendo y muriendo por segundo, instanciar un Label cada vez tiene un coste
## real: cada uno arrastra tema, fuente y layout propios.
var _combo_pool: Array[Label] = []
var _best_cascade: int = 0
var _limpias: int = 0
var _respawn_timer: float = 0.0
var _field_was_empty: bool = false
var _flash_left: float = 0.0
var _record_nuevo: bool = false
var _fallos: int = 0
var _stage_shown: int = 1


func _ready() -> void:
	_hud = [_bar_bg, $UI/BarCaption, _stage_label, _fallos_label, _score_label,
			_best_label, _objetivo_label, _hint_label, _flash_label, _combos_root]
	_cargar()
	_poblar_campo()
	_ir_a(State.MENU)


func _process(delta: float) -> void:
	_explosions = _prune(_explosions)
	_effects = _prune(_effects)

	_prune_cadenas()

	if _state == State.PLAYING:
		_elapsed += delta
		_time_left -= delta * _drain_rate()

	# En MENU y SELECT el campo sigue vivo de fondo: una pantalla de inicio con
	# el juego moviéndose detrás se siente despierta, y además enseña la
	# mecánica antes de que el jugador toque nada.
	if _state != State.DEAD and _state != State.WIN and _state != State.FINAL:
		_mover_dots(delta)
		_check_catches()
		_check_cleared()
		_check_stage()
		_refill_field(delta)

	if _state == State.PLAYING:
		# La victoria se comprueba ANTES que la derrota: si el último eslabón de
		# una cascada cumple el objetivo justo cuando la barra llega a cero,
		# ganas. Es lo justo y además es un final memorable.
		if _mode == Mode.CAMPANA and _objetivo_cumplido():
			_ganar()
		elif _time_left <= 0.0 and _explosions.is_empty():
			# La muerte solo ocurre con el tablero quieto, así que un último tap
			# desesperado todavía puede salvarte si atrapa algo.
			_perder("SE ACABÓ EL TIEMPO")

	if _flash_left > 0.0:
		_flash_left -= delta
	for id in _cadenas:
		_cadenas[id]["pop"] = maxf(0.0, _cadenas[id]["pop"] - delta / COMBO_POP_TIME)

	_update_ui()


func _unhandled_input(event: InputEvent) -> void:
	# Solo se escucha táctil: project.godot tiene emulate_touch_from_mouse, así
	# que el clic del editor entra por aquí igual que el dedo en el teléfono.
	if not (event is InputEventScreenTouch and event.pressed):
		return
	var p: Vector2 = event.position

	match _state:
		State.MENU:
			if _btn_campana.contiene(p):
				_nivel = mini(_nivel_max, Niveles.total() - 1)
				_ir_a(State.SELECT)
			elif _btn_sinfin.contiene(p):
				_mode = Mode.SIN_FIN
				_empezar_partida()
		State.SELECT:
			if _btn_volver.contiene(p):
				_ir_a(State.MENU)
			elif _btn_prev.contiene(p):
				_nivel = maxi(0, _nivel - 1)
			elif _btn_next.contiene(p):
				_nivel = mini(mini(_nivel_max, Niveles.total() - 1), _nivel + 1)
			elif _btn_play.contiene(p):
				_mode = Mode.CAMPANA
				_empezar_partida()
		State.DEAD:
			# Reintento instantáneo tocando donde sea: es lo que sostiene el
			# "una más".
			_empezar_partida()
		State.WIN:
			if _nivel + 1 >= Niveles.total():
				_ir_a(State.FINAL)
			else:
				_nivel += 1
				_empezar_partida()
		State.FINAL:
			_ir_a(State.MENU)
		State.READY:
			_state = State.PLAYING
			_tap(p)
		State.PLAYING:
			_tap(p)


# --- Escalones ------------------------------------------------------------

## El escalón actual: manda lo que llegue antes, la puntuación o el reloj, más
## el escalón de partida que imponga el nivel.
##
## El reloj es la vía principal. Atar los escalones a la puntuación fue un error
## medido: es una goma elástica que persigue al buen jugador y le tapa el techo
## mientras el descuidado granjea el escalón más generoso.
func _stage() -> int:
	var por_puntos := floori(float(_score) / float(stage_size)) + 1
	var por_tiempo := floori(_elapsed / stage_seconds) + 1
	return maxi(por_puntos, por_tiempo) + _stage_offset


func _es_respiro(s: int) -> bool:
	return rest_every > 0 and s % rest_every == 0


## Cuántas veces ha subido la presión hasta este escalón, descontando respiros.
func _pasos_presion(s: int) -> int:
	if rest_every <= 0:
		return s - 1
	return (s - 1) - floori(float(s) / float(rest_every))


func _drain_rate() -> float:
	return drain_base + drain_step * _pasos_presion(_stage())


func _chain_radius() -> float:
	return maxf(chain_radius_min, chain_radius_base - chain_radius_step * (_stage() - 1))


func _respawn_interval() -> float:
	return minf(respawn_max, respawn_base + respawn_step * (_stage() - 1))


func _speed_bonus() -> float:
	return speed_step * (_stage() - 1)


func _fallos_permitidos() -> int:
	return maxi(fallos_min, fallos_base - floori(fallos_step * (_stage() - 1)))


## Las detonaciones se calientan de color con los escalones. No cambia nada del
## balance, solo la percepción — la palanca más barata para que lo difícil se
## SIENTA difícil.
func _stage_color() -> Color:
	var t := clampf(float(_stage() - 1) / STAGE_COLOR_TOPE, 0.0, 1.0)
	return Explosion.COLOR_ACTIVA.lerp(Color("ff2020"), t)


func _check_stage() -> void:
	var s := _stage()
	if s == _stage_shown or _state != State.PLAYING:
		_stage_shown = s
		return
	_stage_shown = s
	_flash("ESCALÓN %d%s" % [s, "   ·   RESPIRO" if _es_respiro(s) else ""])


func _objetivo_cumplido() -> bool:
	return Niveles.cumplido(_nivel, _score, _best_cascade, _limpias, _elapsed)


# --- Partida --------------------------------------------------------------

## El tap acertado cuesta `tap_cost`; el fallado cuesta menos pero suma al
## contador de fallos, que es su castigo principal.
func _tap(pos: Vector2) -> void:
	var objetivo := _dot_mas_cercano(pos)

	if objetivo == null:
		_time_left -= miss_cost
		_spawn_effect(pos)
		_fallos += 1
		if _mode == Mode.CAMPANA and Niveles.exige_limpieza(_nivel):
			_perder("UN FALLO Y SE ACABÓ")
		elif _fallos >= _fallos_permitidos():
			_perder("DEMASIADOS FALLOS")
		else:
			_flash("fallo  %d / %d" % [_fallos, _fallos_permitidos()])
		return

	_time_left -= tap_cost
	_fallos = 0

	# Un tap ARRANCA su propia cadena. No continúa la que hubiera en curso ni la
	# corta: las dos conviven y se propagan en paralelo, cada una con su
	# multiplicador. Así sembrar una segunda cascada mientras la primera se
	# resuelve es una jugada, y no una forma de inflar el mismo contador.
	var donde := objetivo.position
	_dots.erase(objetivo)
	objetivo.queue_free()

	_next_chain += 1
	_cadenas[_next_chain] = {"len": 0, "pos": donde, "pop": 0.0}
	_cobrar_punto(_next_chain, donde)
	_spawn_explosion(donde, tap_radius, _next_chain)


## El círculo más cercano al dedo dentro de la tolerancia, o null si no hay.
func _dot_mas_cercano(pos: Vector2) -> Dot:
	var mejor: Dot = null
	var mejor_dist := tap_tolerance
	for d in _dots:
		var dist := d.position.distance_to(pos)
		if dist <= mejor_dist:
			mejor_dist = dist
			mejor = d
	return mejor


## El punto N de una cascada vale N, no 1.
##
## Solo la PROPAGACIÓN sube el contador: el círculo que tocas siempre vale ×1 y
## a partir de ahí suman los que alcanza la onda. El multiplicador mide la
## cadena, no cuántas veces has pulsado. Es lo que convierte el objetivo en
## encadenar en vez de en pulsar, y lo que impide que la frecuencia compense la
## calidad.
func _cobrar_punto(id: int, pos: Vector2) -> void:
	if not _cadenas.has(id):
		_cadenas[id] = {"len": 0, "pos": pos, "pop": 0.0}
	var c: Dictionary = _cadenas[id]
	c["len"] = int(c["len"]) + 1
	c["pos"] = pos
	c["pop"] = 1.0

	var n: int = c["len"]
	_score += n
	_best_cascade = maxi(_best_cascade, n)
	_time_left = minf(time_max, _time_left + reward_base + reward_step * (n - 1))


## Detección de contagios por distancia, no con Area2D: con ~25 puntos el coste
## es irrelevante y a cambio es determinista y se lee de un vistazo.
func _check_catches() -> void:
	var atrapados: Array[Dictionary] = []
	var survivors: Array[Dot] = []

	for d in _dots:
		# Gana la detonación más CERCANA, no la primera de la lista: cuando dos
		# cadenas se solapan, la que reclama el círculo tiene que ser la que el
		# jugador ve encima de él.
		var mejor: Explosion = null
		var mejor_dist := INF
		for e in _explosions:
			var dist := d.position.distance_to(e.position)
			if dist <= e.radius + d.radius and dist < mejor_dist:
				mejor_dist = dist
				mejor = e
		if mejor != null:
			atrapados.append({"pos": d.position, "cadena": mejor.chain_id})
			d.queue_free()
		else:
			survivors.append(d)

	_dots = survivors

	# Se difiere el spawn respecto al bucle de arriba: añadir a _explosions
	# mientras se itera sobre él haría que un punto se contagie de su propia
	# detonación en el mismo frame.
	for a in atrapados:
		_cobrar_punto(int(a["cadena"]), a["pos"])
		_spawn_explosion(a["pos"], _chain_radius(), int(a["cadena"]))


## Vaciar la pantalla es lo más parecido a ganar que tiene una partida sin fin.
func _check_cleared() -> void:
	var vacio := _dots.is_empty()
	if vacio and not _field_was_empty and _state == State.PLAYING:
		_limpias += 1
		_time_left = minf(time_max, _time_left + clear_bonus)
		_flash("PANTALLA LIMPIA   +%d s" % int(clear_bonus))
	_field_was_empty = vacio


## Los puntos entran desde fuera de la pantalla, nunca aparecen en medio: eso
## rompería la lectura de trayectorias y podría regalar un contagio.
func _refill_field(delta: float) -> void:
	if _dots.size() >= target_dots:
		return

	_respawn_timer -= delta
	if _respawn_timer > 0.0:
		return
	_respawn_timer = _respawn_interval()

	var rect := get_viewport_rect().size
	var d := Dot.new()
	var fuera := d.radius * 2.0
	var modo := _movimiento_actual()

	if modo == Dot.Movimiento.NIEVE:
		# La nieve solo tiene sentido entrando por arriba.
		d.position = Vector2(randf() * rect.x, -fuera)
	else:
		match randi() % 4:
			0: d.position = Vector2(randf() * rect.x, -fuera)
			1: d.position = Vector2(randf() * rect.x, rect.y + fuera)
			2: d.position = Vector2(-fuera, randf() * rect.y)
			_: d.position = Vector2(rect.x + fuera, randf() * rect.y)

	# Apunta al tercio central para que cruce el campo en vez de rozar el borde.
	var objetivo := Vector2(
		randf_range(rect.x * 0.33, rect.x * 0.67),
		randf_range(rect.y * 0.33, rect.y * 0.67))
	_preparar_dot(d, modo, (objetivo - d.position).normalized())

	_dots_root.add_child(d)
	_dots.append(d)


## El movimiento del bioma en curso.
func _movimiento_actual() -> int:
	if forzar_movimiento:
		return movimiento_prueba
	if _mode == Mode.CAMPANA:
		return Niveles.movimiento(_nivel)
	return Dot.Movimiento.REBOTE


## Main dirige el movimiento en vez de que cada círculo lo haga en su _process.
##
## Hay modos que necesitan ver a los demás círculos o a las detonaciones, y
## además así el orden de actualización es determinista: primero las reglas
## globales, después la integración de cada uno, y solo entonces los contagios.
func _mover_dots(delta: float) -> void:
	match _movimiento_actual():
		Dot.Movimiento.CHOQUE:
			_resolver_choques()
		Dot.Movimiento.ENJAMBRE:
			_aplicar_enjambre(delta)
		Dot.Movimiento.HUIDA:
			_aplicar_huida(delta)

	var rect := get_viewport_rect().size
	for d in _dots:
		d.mover(delta, rect)


## Choque elástico entre iguales: se intercambia la componente de la velocidad
## a lo largo de la normal y se separan lo que se hubieran solapado.
func _resolver_choques() -> void:
	for i in range(_dots.size()):
		for j in range(i + 1, _dots.size()):
			var a := _dots[i]
			var b := _dots[j]
			var dif := b.position - a.position
			var dist := dif.length()
			var minima := a.radius + b.radius
			if dist < 0.001 or dist >= minima:
				continue

			var n := dif / dist
			var solape := minima - dist
			a.position -= n * solape * 0.5
			b.position += n * solape * 0.5

			var va := a.velocity.dot(n)
			var vb := b.velocity.dot(n)
			# Si ya se están separando no se toca: evita que dos círculos
			# pegados se queden vibrando el uno contra el otro.
			if va - vb <= 0.0:
				continue
			a.velocity += n * (vb - va)
			b.velocity += n * (va - vb)


## Se buscan entre sí y forman grumos. Cambia el juego más de lo que parece:
## los clusters aparecen solos, así que la habilidad deja de ser encontrarlos y
## pasa a ser elegir el instante.
func _aplicar_enjambre(delta: float) -> void:
	for d in _dots:
		var centro := Vector2.ZERO
		var vecinos := 0
		var roce := Vector2.ZERO
		for o in _dots:
			if o == d:
				continue
			var dif := o.position - d.position
			var dist := dif.length()
			if dist > ENJAMBRE_VISTA or dist < 0.001:
				continue
			centro += o.position
			vecinos += 1
			if dist < ENJAMBRE_ROCE:
				roce -= dif / dist
		if vecinos == 0:
			continue
		var hacia := ((centro / float(vecinos)) - d.position).normalized()
		d.velocity += (hacia * ENJAMBRE_ATRACCION + roce * ENJAMBRE_SEPARACION) * delta
		# Se renormaliza para que juntarse no acelere ni frene a nadie.
		d.velocity = d.velocity.normalized() * d.base_speed


## Se apartan de las detonaciones activas.
##
## Es el primer modo que reacciona a la mecánica en vez de solo desplazarse, y
## le da la vuelta al juego: la onda dispersa al grupo que estabas cazando, así
## que las cadenas largas exigen atrapar a los vecinos antes de que escapen.
func _aplicar_huida(delta: float) -> void:
	if _explosions.is_empty():
		return
	for d in _dots:
		for e in _explosions:
			var dif := d.position - e.position
			var dist := dif.length()
			if dist < 0.001 or dist > e.radius + HUIDA_MARGEN:
				continue
			d.velocity += (dif / dist) * HUIDA_FUERZA * delta
		d.velocity = d.velocity.normalized() * d.base_speed


func _spawn_explosion(pos: Vector2, radius: float, chain_id: int) -> void:
	var e := Explosion.new()
	e.position = pos
	e.max_radius = radius
	e.chain_id = chain_id
	e.color = _stage_color()
	_explosions_root.add_child(e)
	_explosions.append(e)


func _spawn_effect(pos: Vector2) -> void:
	var e := Explosion.new()
	e.position = pos
	e.max_radius = tap_tolerance
	e.color = Explosion.COLOR_FALLO
	e.hold_time = 0.1
	_explosions_root.add_child(e)
	_effects.append(e)


## Una cadena vive mientras le quede alguna detonación en pantalla.
##
## Se poda justo después de las detonaciones y ANTES de los contagios, para que
## _check_catches solo pueda referirse a cadenas vivas.
func _prune_cadenas() -> void:
	var vivas := {}
	for e in _explosions:
		vivas[e.chain_id] = true
	for id in _cadenas.keys():
		if not vivas.has(id):
			_cadenas.erase(id)


## Un contador por cadena, colocado donde acaba de propagarse.
##
## El contador vive junto a su explosión y no en el centro de la pantalla: con
## varias cadenas a la vez, un número centrado no diría a cuál pertenece.
func _sync_combos() -> void:
	for id in _cadenas:
		var c: Dictionary = _cadenas[id]
		if int(c["len"]) < 2:
			continue
		if not _combo_labels.has(id):
			_combo_labels[id] = _tomar_combo_label()
		var lbl: Label = _combo_labels[id]
		lbl.text = "×%d" % int(c["len"])
		lbl.position = Vector2(c["pos"]) - COMBO_SIZE * 0.5
		var pop := float(c["pop"])
		var golpe := 1.0 + 0.5 * pop * pop
		lbl.scale = Vector2(golpe, golpe)
		lbl.modulate = _stage_color()

	for id in _combo_labels.keys():
		if not _cadenas.has(id):
			_soltar_combo_label(id)


func _tomar_combo_label() -> Label:
	if not _combo_pool.is_empty():
		var reciclada: Label = _combo_pool.pop_back()
		reciclada.visible = true
		return reciclada
	var l := Label.new()
	l.size = COMBO_SIZE
	l.pivot_offset = COMBO_SIZE * 0.5
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 76)
	_combos_root.add_child(l)
	return l


func _soltar_combo_label(id: int) -> void:
	var l: Label = _combo_labels[id]
	l.visible = false
	_combo_pool.append(l)
	_combo_labels.erase(id)


func _prune(lista: Array[Explosion]) -> Array[Explosion]:
	var alive: Array[Explosion] = []
	for e in lista:
		if e.finished:
			e.queue_free()
		else:
			alive.append(e)
	return alive


func _flash(texto: String) -> void:
	_flash_label.text = texto
	_flash_left = FLASH_TIME


# --- Fin de partida -------------------------------------------------------

## Al terminar se congela el mundo entero: en DEAD, WIN y FINAL no se llama a
## _mover_dots. Antes solo se detenía la lógica de partida y los círculos
## seguían rebotando por su cuenta, así que la muerte era literalmente
## invisible y el juego parecía continuar.
func _congelar() -> void:
	pass


func _perder(motivo: String) -> void:
	_over_title.text = motivo
	_congelar()
	if _mode == Mode.SIN_FIN:
		_record_nuevo = _score > _best
		if _record_nuevo:
			_best = _score
			_guardar()
	_ir_a(State.DEAD)


func _ganar() -> void:
	_congelar()
	if _nivel + 1 > _nivel_max:
		_nivel_max = mini(_nivel + 1, Niveles.total() - 1)
		_guardar()
	_ir_a(State.WIN)


func _empezar_partida() -> void:
	_stage_offset = int(Niveles.nivel(_nivel)["escalon"]) if _mode == Mode.CAMPANA else 0
	_poblar_campo()

	_time_left = time_start
	_score = 0
	_elapsed = 0.0
	_cadenas.clear()
	_next_chain = 0
	for id in _combo_labels.keys():
		_soltar_combo_label(id)
	_best_cascade = 0
	_limpias = 0
	_fallos = 0
	_respawn_timer = _respawn_interval()
	_field_was_empty = false
	_flash_left = 0.0
	_stage_shown = _stage()
	_ir_a(State.READY)


func _poblar_campo() -> void:
	for d in _dots:
		d.queue_free()
	_dots.clear()
	for e in _explosions:
		e.queue_free()
	_explosions.clear()
	for e in _effects:
		e.queue_free()
	_effects.clear()

	# El campo arranca lleno y repartido; solo las reposiciones entran por los
	# bordes. Verlo llenarse punto a punto sería una espera muerta al empezar.
	var rect := get_viewport_rect().size
	var modo := _movimiento_actual()
	for i in target_dots:
		var d := Dot.new()
		d.position = Vector2(
			randf_range(SPAWN_MARGIN, rect.x - SPAWN_MARGIN),
			randf_range(SPAWN_MARGIN, rect.y - SPAWN_MARGIN))
		_preparar_dot(d, modo, Vector2.from_angle(randf() * TAU))
		_dots_root.add_child(d)
		_dots.append(d)


## Modo, rumbo y rapidez de un círculo recién nacido.
##
## La rapidez base se guarda aparte de la velocidad porque los modos que
## reorientan el vector (enjambre, huida, abeja) la necesitan para no acelerar
## ni frenar sin querer al cambiar de dirección.
func _preparar_dot(d: Dot, modo: int, rumbo: Vector2) -> void:
	d.modo = modo
	var bonus := _speed_bonus()
	var rapidez := randf_range(dot_speed_min + bonus, dot_speed_max + bonus)
	if speed_variance > 0.0:
		rapidez *= randf_range(1.0 - speed_variance, 1.0 + speed_variance)
	d.base_speed = maxf(10.0, rapidez)
	d.velocity = rumbo * d.base_speed


# --- Pantallas ------------------------------------------------------------

func _ir_a(s: State) -> void:
	_state = s
	_menu_screen.visible = s == State.MENU
	_select_screen.visible = s == State.SELECT
	_over_screen.visible = s == State.DEAD
	_win_screen.visible = s == State.WIN or s == State.FINAL
	var jugando := s == State.READY or s == State.PLAYING
	for nodo in _hud:
		nodo.visible = jugando

	if s == State.WIN:
		_win_title.text = "NIVEL %d SUPERADO" % (_nivel + 1)
		_win_detail.text = "%d puntos  ·  mejor cadena ×%d" % [_score, _best_cascade]
		_win_seguir_text.text = "SIGUE"
	elif s == State.FINAL:
		_win_title.text = "CAMPAÑA COMPLETA"
		_win_detail.text = "terminaste los %d niveles de Campo abierto.\nel modo sin fin te espera." % Niveles.total()
		_win_seguir_text.text = "FIN"
	elif s == State.DEAD:
		_over_score.text = str(_score)
		var m := int(_elapsed) / 60
		var seg := int(_elapsed) % 60
		if _mode == Mode.CAMPANA:
			_over_detail.text = "%s\nnivel %d  ·  toca para reintentar" % [
				Niveles.describir(_nivel), _nivel + 1]
		elif _record_nuevo:
			_over_detail.text = "¡NUEVO RÉCORD!\ncadena ×%d  ·  %d:%02d" % [_best_cascade, m, seg]
		else:
			_over_detail.text = "mejor  %d\ncadena ×%d  ·  %d:%02d" % [_best, _best_cascade, m, seg]


func _cargar() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	_best = int(cfg.get_value("progreso", "mejor", 0))
	_nivel_max = clampi(int(cfg.get_value("progreso", "nivel_max", 0)), 0, Niveles.total() - 1)


func _guardar() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progreso", "mejor", _best)
	cfg.set_value("progreso", "nivel_max", _nivel_max)
	cfg.save(SAVE_PATH)


func _update_ui() -> void:
	_menu_best.text = "mejor sin fin  %d" % _best

	if _state == State.SELECT:
		_sel_bioma.text = str(Niveles.nivel(_nivel)["bioma"]).to_upper()
		_sel_num.text = "NIVEL %d" % (_nivel + 1)
		_sel_meta.text = Niveles.describir(_nivel)
		_sel_pista.text = str(Niveles.nivel(_nivel)["pista"])
		_btn_prev.modulate.a = 1.0 if _nivel > 0 else 0.25
		_btn_next.modulate.a = 1.0 if _nivel < mini(_nivel_max, Niveles.total() - 1) else 0.25
		return

	if _state != State.READY and _state != State.PLAYING:
		return

	_score_label.text = str(_score)
	_hint_label.visible = _state == State.READY

	if _mode == Mode.CAMPANA:
		_best_label.text = "nivel %d" % (_nivel + 1)
		_objetivo_label.text = "%s   —   %s" % [
			Niveles.describir(_nivel),
			Niveles.progreso(_nivel, _score, _best_cascade, _limpias, _elapsed)]
	else:
		_best_label.text = "mejor  %d" % _best
		_objetivo_label.text = ""

	var s := _stage()
	_stage_label.text = "escalón %d  ·  %s" % [s, NOMBRES_MOV[_movimiento_actual()]]
	_fallos_label.text = "fallos  %d / %d" % [_fallos, _fallos_permitidos()]
	_fallos_label.modulate = Color("ff5470") if _fallos > 0 else Color(0.45, 0.45, 0.55)

	var frac := clampf(_time_left / time_max, 0.0, 1.0)
	_bar_fill.size = Vector2(_bar_bg.size.x * frac, _bar_bg.size.y)
	_bar_fill.color = Color("ff5470") if _time_left < WARN_TIME else Color("6de3a0")

	# El multiplicador solo existe mientras la cascada está viva.
	_sync_combos()

	_flash_label.modulate.a = clampf(_flash_left / (FLASH_TIME * 0.5), 0.0, 1.0)
