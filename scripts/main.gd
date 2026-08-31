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
## El game feel no es maquillaje: es donde vive lo pegajoso. Dos juegos con la
## misma mecánica, uno adictivo y otro muerto, se diferencian solo aquí.
@export_group("Game feel")
## Sacudida que añade cada eslabón, y tope para que una cascada larga no
## convierta la pantalla en una batidora.
@export var shake_por_eslabon: float = 3.0
@export var shake_max: float = 20.0
@export var shake_amortiguacion: float = 9.0
## Congelación en el impacto, en segundos. Es lo que se lee como "golpe": sin
## ella la cascada se ve fluida y blanda.
##
## El valor tiene un suelo que no es negociable: por debajo de un frame no
## existe. La primera versión usaba 0.010 s, que a 60 fps es menos de un frame
## (16.7 ms), así que se consumía entera antes de dibujar nada y no congelaba
## absolutamente nada. Lo habitual son 2-4 frames por impacto, de ahí 0.035.
@export var hitstop_por_eslabon: float = 0.035
@export var hitstop_max: float = 0.10
@export var sonido: bool = true
@export var musica: bool = true
## Apagada de momento: es el principal sospechoso de un cierre que solo ocurre
## en el teléfono. El interruptor sigue en la pausa para poder volver a probarla.
@export var vibracion: bool = false
@export var volumen_musica: float = -13.0

@export_group("Pruebas")
@export var forzar_movimiento: bool = false
@export var movimiento_prueba: Dot.Movimiento = Dot.Movimiento.REBOTE

@export_group("Detonación")
## Radio de la detonación del círculo que tocas, mayor que el de las
## detonaciones en cadena: es el valor de haber apuntado bien.
@export var tap_radius: float = 150.0
## Cuánto se perdona la puntería.
##
## Empezó en 60 px, calculado para que el dedo no fuera el enemigo. Probado en
## un teléfono real resultó demasiado indulgente: acertabas sin mirar. A 30 px
## sigue siendo mayor que el círculo (9 px de radio) pero ya exige apuntar, y
## el margen de fallos deja de ser decorativo.
@export var tap_tolerance: float = 30.0

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
## Umbrales de la barra. Tres estados y no dos: con solo verde y rojo, el aviso
## llega de golpe y ya no da tiempo a reaccionar. El amarillo es el que dice
## "empieza a buscar un buen grupo".
const WARN_TIME := 3.0
const ALERTA_TIME := 6.0
const COLOR_BARRA_OK := Color("6de3a0")
const COLOR_BARRA_ALERTA := Color("ffd166")
const COLOR_BARRA_PELIGRO := Color("ff5470")
## Separación entre pitidos de alarma: se acorta según se acaba el tiempo.
const ALARMA_LENTA := 0.60
const ALARMA_RAPIDA := 0.22
## Cuánto tarda en apagarse el fogonazo de victoria.
const DESTELLO_CAIDA := 1.5
## Opacidad máxima del fogonazo. Un blanco pleno taparía el campo justo cuando
## el jugador quiere ver qué acaba de conseguir.
const DESTELLO_MAX := 0.5
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

const SND_POP := preload("res://audio/pop.wav")
const SND_FALLO := preload("res://audio/fallo.wav")
const SND_CADENA := preload("res://audio/cadena.wav")
const SND_FIN := preload("res://audio/fin.wav")
const SND_ALARMA := preload("res://audio/alarma.wav")
const SND_EXITO := preload("res://audio/exito.wav")
const MUS_CAMPO := preload("res://audio/musica_campo.wav")
## Voces de audio. Una sola cortaría el sonido anterior en cada eslabón, que es
## justo lo contrario de lo que se quiere en una cascada.
const VOCES := 8
## Cada cuántos eslabones suena el premio y vibra el teléfono. Hacerlo en todos
## sería un zumbido continuo.
const HITO_CADENA := 5
## Separación mínima entre vibraciones, en segundos.
const VIBRA_INTERVALO_MIN := 0.12
## Cada cuánto se anota una foto del estado en la caja negra.
const INSTANTANEA_CADA := 1.0
## Cuántas líneas del registro anterior se enseñan.
const LOG_LINEAS := 34
## El último movimiento de una partida se ve a cámara lenta.
##
## Es el momento que el jugador quiere entender, por qué ganó o por qué murió, y
## a velocidad normal se lo pierde. Cortar de golpe a la pantalla de resultado le
## roba justo la información que necesita para volver a intentarlo.
const SLOWMO_FACTOR := 0.3
## La victoria dura más que la derrota. Al ganar hay algo que mirar — la cadena
## cerrándose — mientras que al perder por tiempo el campo está casi quieto y
## alargarlo solo aburre.
const SLOWMO_DUR_VICTORIA := 1.3
const SLOWMO_DUR_DERROTA := 0.8

## Anticipación: la cámara lenta arranca ANTES de ganar, no después.
##
## Al cerrar una cadena objetivo, para cuando el juego detecta la victoria el
## momento bueno ya pasó y la cámara lenta solo enseña la cola. Sabiendo que
## falta un eslabón se puede frenar el tiempo justo antes, que es cuando hay
## algo que ver.
##
## Es más suave que la del final a propósito: así al ganar de verdad hay un
## segundo frenazo que se nota.
const ANTICIPA_FACTOR := 0.5
## Tope para que una falsa alarma no deje el juego a medio gas.
const ANTICIPA_MAX := 2.0

## PAUSA va al FINAL a propósito. Insertar un estado en medio desplaza los
## índices y rompe tools/simulacion.gd, que ya se quedó girando en vacío una vez
## justo por eso.
enum State { MENU, SELECT, READY, PLAYING, DEAD, WIN, FINAL, PAUSA, LOG, BRIEFING }
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
@onready var _destello_rect: ColorRect = $UI/Destello
@onready var _btn_pausa: CircleButton = $UI/Pausa

@onready var _pause_screen: Control = $UI/PauseScreen
@onready var _btn_seguir: CircleButton = $UI/PauseScreen/Seguir
@onready var _btn_menu: CircleButton = $UI/PauseScreen/Menu
@onready var _opt_sonido: CircleButton = $UI/PauseScreen/OptSonido
@onready var _opt_musica: CircleButton = $UI/PauseScreen/OptMusica
@onready var _opt_vibra: CircleButton = $UI/PauseScreen/OptVibra
@onready var _bar_bg: ColorRect = $UI/BarBg
@onready var _bar_fill: ColorRect = $UI/BarBg/BarFill

@onready var _menu_screen: Control = $UI/MenuScreen
@onready var _btn_campana: CircleButton = $UI/MenuScreen/Campana
@onready var _btn_sinfin: CircleButton = $UI/MenuScreen/SinFin
@onready var _menu_best: Label = $UI/MenuScreen/Best
@onready var _btn_log: CircleButton = $UI/MenuScreen/Log

@onready var _brief_screen: Control = $UI/BriefingScreen
@onready var _brief_bioma: Label = $UI/BriefingScreen/Bioma
@onready var _brief_num: Label = $UI/BriefingScreen/Num
@onready var _brief_meta: Label = $UI/BriefingScreen/Meta
@onready var _brief_pista: Label = $UI/BriefingScreen/Pista

@onready var _log_screen: Control = $UI/LogScreen
@onready var _log_estado: Label = $UI/LogScreen/Estado
@onready var _log_texto: Label = $UI/LogScreen/Texto
@onready var _btn_log_volver: CircleButton = $UI/LogScreen/Volver

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
var _shake: float = 0.0
## Congelación pendiente, en segundos.
var _hitstop: float = 0.0
var _explosiones_pausadas: bool = false
var _score_pop: float = 0.0
var _audio: Array[AudioStreamPlayer] = []
var _voz: int = 0
var _musica_player: AudioStreamPlayer
var _ultima_vibracion: float = 0.0
var _diag: Diagnostico
## Contadores desde la última instantánea, para ver si algo se dispara.
var _n_sonidos: int = 0
var _n_vibras: int = 0
var _t_instantanea: float = 0.0
## Escala de tiempo normal, capturada al arrancar para no pisar la que imponga
## una herramienta externa como el simulador.
var _ts_base: float = 1.0
## Estado al que se irá cuando acabe la cámara lenta, o -1 si no hay final en
## curso.
var _final_pendiente: int = -1
var _slowmo_hasta: int = 0
## Cámara lenta anticipada, aún sin haber ganado.
var _anticipando: bool = false
var _anticipa_hasta: int = 0
## Marca de dónde se perdió, para que quede visible bajo el mensaje.
var _marca_muerte: Explosion
## Cuenta atrás para el próximo pitido de alarma.
var _t_alarma: float = 0.0
## Fogonazo de victoria, de 1 a 0.
var _destello: float = 0.0
## Estado al que se vuelve al despausar.
var _antes_de_pausar: State = State.PLAYING


func _ready() -> void:
	_hud = [_bar_bg, $UI/BarCaption, _stage_label, _fallos_label, _score_label,
			_best_label, _objetivo_label, _hint_label, _flash_label, _combos_root,
			_btn_pausa]
	for i in VOCES:
		var voz := AudioStreamPlayer.new()
		add_child(voz)
		_audio.append(voz)
	_musica_player = AudioStreamPlayer.new()
	add_child(_musica_player)
	_ts_base = Engine.time_scale
	_diag = Diagnostico.new()
	_cargar()
	_diag.evento("opciones sonido=%s musica=%s vibra=%s" % [sonido, musica, vibracion])
	_sonar_musica()
	_poblar_campo()
	_ir_a(State.MENU)


## Al cerrar hay que parar el audio a mano.
##
## Una reproducción en curso mantiene viva la pista y Godot avisa de instancias
## filtradas al salir. No es un fallo real, pero un log ruidoso esconde los que
## sí lo son, y este proyecto ha cazado varios errores justo porque el log
## estaba limpio.
func _exit_tree() -> void:
	if _diag:
		_diag.cerrar_limpio()
	if _musica_player:
		_musica_player.stop()
	for voz in _audio:
		voz.stop()


func _process(delta: float) -> void:
	_explosions = _prune(_explosions)
	_effects = _prune(_effects)

	_prune_cadenas()

	# El reloj sigue corriendo durante el hit stop. Congelarlo también parecía
	# lo natural, pero convertía un recurso visual en una mecánica: cada cascada
	# larga regalaba tiempo y la supervivencia del jugador descuidado subía de
	# 98 s a 135 s. Sesenta milisegundos de desagüe son imperceptibles; el regalo
	# no lo era.
	if _state == State.PLAYING:
		_elapsed += delta
		_time_left -= delta * _drain_rate()

	# En MENU y SELECT el campo sigue vivo de fondo: una pantalla de inicio con
	# el juego moviéndose detrás se siente despierta, y además enseña la
	# mecánica antes de que el jugador toque nada.
	# El hit stop congela el mundo unos frames en el impacto. Se pausan también
	# las detonaciones, o seguirían creciendo durante la congelación y el golpe
	# se perdería.
	if _hitstop > 0.0:
		_hitstop -= delta
	_sincronizar_congelacion()

	# En pausa el mundo se congela igual que al morir: no se llama a _mover_dots.
	if _mundo_activo() and _hitstop <= 0.0:
		_mover_dots(delta)
		_check_catches()
		_check_cleared()
		_check_stage()
		_refill_field(delta)

	if _final_pendiente >= 0 and Time.get_ticks_msec() >= _slowmo_hasta:
		_rematar()

	_actualizar_anticipacion()

	if _state == State.PLAYING and _final_pendiente < 0:
		# La victoria se comprueba ANTES que la derrota: si el último eslabón de
		# una cascada cumple el objetivo justo cuando la barra llega a cero,
		# ganas. Es lo justo y además es un final memorable.
		if _mode == Mode.CAMPANA and _objetivo_cumplido():
			_ganar()
		elif _time_left <= 0.0 and _explosions.is_empty():
			# La muerte solo ocurre con el tablero quieto, así que un último tap
			# desesperado todavía puede salvarte si atrapa algo.
			_perder("SE ACABÓ EL TIEMPO")

	_alarma_tiempo(delta)
	_destello = maxf(0.0, _destello - delta * DESTELLO_CAIDA)
	# Un velo verde muy tenue mientras se anticipa: sin él, el frenazo se siente
	# como que el juego se ha atascado en vez de como que algo va a pasar.
	var velo := 0.12 if _anticipando else 0.0
	_destello_rect.color.a = maxf(_destello * DESTELLO_MAX, velo)
	_registrar(delta)
	_aplicar_shake(delta)
	_score_pop = maxf(0.0, _score_pop - delta * 4.0)

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
	# Durante la cámara lenta del final no se acepta nada: la partida ya acabó y
	# un tap suelto solo serviría para confundir.
	if _final_pendiente >= 0:
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
			elif _btn_log.contiene(p):
				_ir_a(State.LOG)
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
		State.LOG:
			_ir_a(State.MENU)
		State.BRIEFING:
			# El tap que cierra la tarjeta NO detona: solo arranca la partida.
			_ir_a(State.READY)
		State.PAUSA:
			if _btn_seguir.contiene(p):
				_ir_a(_antes_de_pausar)
			elif _btn_menu.contiene(p):
				_ir_a(State.MENU)
			elif _opt_sonido.contiene(p):
				sonido = not sonido
				_guardar()
			elif _opt_musica.contiene(p):
				musica = not musica
				_sonar_musica()
				_guardar()
			elif _opt_vibra.contiene(p):
				vibracion = not vibracion
				_vibrar(40)
				_guardar()
		State.READY:
			if _btn_pausa.contiene(p):
				_pausar()
			else:
				_state = State.PLAYING
				_tap(p)
		State.PLAYING:
			if _btn_pausa.contiene(p):
				_pausar()
			else:
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
	_diag.evento("escalon %d  desague=%.2f radio=%.0f repo=%.2f" % [
		s, _drain_rate(), _chain_radius(), _respawn_interval()])
	_flash("ESCALÓN %d%s" % [s, "   ·   RESPIRO" if _es_respiro(s) else ""])


func _objetivo_cumplido() -> bool:
	return Niveles.cumplido(_nivel, _score, _best_cascade, _limpias, _elapsed)


# --- Partida --------------------------------------------------------------

## El tap acertado cuesta `tap_cost`; el fallado cuesta menos pero suma al
## contador de fallos, que es su castigo principal.
func _tap(pos: Vector2) -> void:
	# El campo se desplaza con la sacudida, así que el dedo hay que llevarlo al
	# mismo sistema de coordenadas. Sin esto, en plena cascada fallarías taps
	# que visualmente eran buenos.
	var mundo := pos - _dots_root.position
	var objetivo := _dot_mas_cercano(mundo)

	if objetivo == null:
		_time_left -= miss_cost
		_spawn_effect(mundo)
		_sonar(SND_FALLO)
		_vibrar(45)
		_fallos += 1
		if _mode == Mode.CAMPANA and Niveles.exige_limpieza(_nivel):
			_marcar_muerte(mundo)
			_perder("FALLASTE EL TOQUE")
		elif _fallos >= _fallos_permitidos():
			_marcar_muerte(mundo)
			_perder("DEMASIADOS FALLOS")
		else:
			_flash("fallo  %d / %d" % [_fallos, _fallos_permitidos()])
		return

	_time_left -= tap_cost
	_fallos = 0
	_vibrar(12)

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

	_shake = minf(shake_max, _shake + shake_por_eslabon)
	_hitstop = minf(hitstop_max, _hitstop + hitstop_por_eslabon)
	_score_pop = 1.0
	# El tono sube con cada eslabón. Es el truco más viejo del género y sigue
	# siendo el que más se nota: convierte una ráfaga de clics en una escala que
	# va subiendo, y da ganas de alargarla solo por oírla.
	_sonar(SND_POP, clampf(0.85 + 0.075 * float(n - 1), 0.85, 2.4))
	if n % HITO_CADENA == 0:
		_sonar(SND_CADENA, 1.0, -4.0)
		_vibrar(30)


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


## Deja clavado en el campo el sitio exacto del toque que costó la partida.
##
## El mensaje dice POR QUÉ perdiste; esto dice DÓNDE. Sin ello el jugador lee
## que falló el toque y se queda sin saber por cuánto.
func _marcar_muerte(pos: Vector2) -> void:
	if _marca_muerte and is_instance_valid(_marca_muerte):
		_marca_muerte.queue_free()
	var e := Explosion.new()
	e.position = pos
	e.max_radius = tap_tolerance
	e.color = Explosion.COLOR_FALLO
	e.grow_time = 0.12
	e.hold_time = 9999.0
	e.decay_time = 0.3
	_explosions_root.add_child(e)
	_marca_muerte = e


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


## La sacudida se aplica moviendo los contenedores del campo, no una cámara.
##
## Así el HUD se queda quieto, que es lo correcto: sacudir los números los hace
## ilegibles justo en el momento en que el jugador quiere leerlos.
func _aplicar_shake(delta: float) -> void:
	_shake = maxf(0.0, _shake - _shake * shake_amortiguacion * delta - 0.4 * delta)
	var off := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake
	_dots_root.position = off
	_explosions_root.position = off


func _sincronizar_congelacion() -> void:
	var congelado := _hitstop > 0.0
	if congelado == _explosiones_pausadas:
		return
	_explosiones_pausadas = congelado
	_explosions_root.process_mode = Node.PROCESS_MODE_DISABLED if congelado 		else Node.PROCESS_MODE_INHERIT


## Reparte los sonidos entre varias voces por turnos. Con una sola, cada eslabón
## cortaría al anterior y la cascada sonaría a un único clic en vez de a una
## ráfaga.
func _sonar(stream: AudioStream, pitch: float = 1.0, volumen: float = 0.0) -> void:
	if not sonido or _audio.is_empty():
		return
	var voz := _audio[_voz]
	_voz = (_voz + 1) % _audio.size()
	voz.stream = stream
	voz.pitch_scale = pitch
	voz.volume_db = volumen
	voz.play()
	_n_sonidos += 1


## El bucle se activa AQUÍ y no en el .import.
##
## `edit/loop_mode=1` en el archivo de importación no llega al recurso en esta
## versión de Godot: el .import lo dice y el AudioStreamWAV cargado sigue
## reportando 0. Ponerlo en código es explícito y además deja el motivo escrito.
## Requiere que la pista se importe sin comprimir, o `data` no sería PCM plano y
## la cuenta de fotogramas no saldría.
func _preparar_bucle(pista: AudioStreamWAV) -> void:
	if pista.loop_mode == AudioStreamWAV.LOOP_FORWARD:
		return
	pista.loop_mode = AudioStreamWAV.LOOP_FORWARD
	pista.loop_begin = 0
	pista.loop_end = pista.data.size() / 2  # 16 bits mono: 2 bytes por muestra


## Pista por bioma. De momento una sola.
##
## Va como match y no como diccionario constante: un `const Dictionary` con
## recursos precargados dentro hace que Godot los libere tarde y suelte avisos
## de fuga al cerrar. Cuando cada bioma tenga su pista, se añaden ramas aquí y
## funciones en tools/generar_audio.py.
func _musica_de_bioma(bioma: String) -> AudioStreamWAV:
	match bioma:
		_:
			return MUS_CAMPO


func _sonar_musica() -> void:
	if not musica:
		_musica_player.stop()
		return
	var bioma := "Campo abierto"
	if _mode == Mode.CAMPANA:
		bioma = str(Niveles.nivel(_nivel)["bioma"])
	var pista := _musica_de_bioma(bioma)
	_preparar_bucle(pista)
	_musica_player.volume_db = volumen_musica
	if _musica_player.stream != pista or not _musica_player.playing:
		_diag.evento("musica %s  %.1f s  hz=%d" % [bioma, pista.get_length(), pista.mix_rate])
		_musica_player.stream = pista
		_musica_player.play()


## Vibración con freno de frecuencia.
##
## En una cascada larga esto se llamaba decenas de veces por segundo, y cada
## llamada cruza al servicio de vibración de Android. En PC no se nota porque
## ahí es un no-op. El tope deja pasar unas ocho por segundo, que es más de lo
## que el motor háptico puede distinguir de todas formas.
func _vibrar(ms: int) -> void:
	if not vibracion:
		return
	var ahora := float(Time.get_ticks_msec()) / 1000.0
	if ahora - _ultima_vibracion < VIBRA_INTERVALO_MIN:
		return
	_ultima_vibracion = ahora
	_n_vibras += 1
	Input.vibrate_handheld(ms)


## Foto periódica del estado a la caja negra.
##
## Solo mientras se juega: en los menús no pasa nada que valga la pena anotar, y
## cada línea implica un volcado a disco.
func _registrar(delta: float) -> void:
	if _state != State.PLAYING:
		return
	_t_instantanea += delta
	if _t_instantanea < INSTANTANEA_CADA:
		return
	_t_instantanea = 0.0
	_diag.instantanea({
		"pts": _score,
		"esc": _stage(),
		"mov": NOMBRES_MOV[_movimiento_actual()],
		"dots": _dots.size(),
		"exp": _explosions.size(),
		"cad": _cadenas.size(),
		"lbl": _combo_labels.size(),
		"pool": _combo_pool.size(),
		"snd": _n_sonidos,
		"vib": _n_vibras,
		"fps": Engine.get_frames_per_second(),
		"nodos": Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
		"memMB": "%.1f" % (Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0),
	})
	_n_sonidos = 0
	_n_vibras = 0


## Pitido de tiempo bajo, cada vez más seguido.
##
## Solo suena en rojo y se calla solo al volver a ámbar o verde: no hay nada que
## parar porque no es un bucle, sino pitidos sueltos que dejan de programarse.
## El intervalo se acorta según baja la barra, que es lo que convierte el aviso
## en presión en vez de en un ruido de fondo.
func _alarma_tiempo(delta: float) -> void:
	var en_peligro := _state == State.PLAYING and _final_pendiente < 0 \
		and _time_left > 0.0 and _time_left < WARN_TIME
	if not en_peligro:
		_t_alarma = 0.0
		return
	_t_alarma -= delta
	if _t_alarma > 0.0:
		return
	var margen := clampf(_time_left / WARN_TIME, 0.0, 1.0)
	_t_alarma = lerpf(ALARMA_RAPIDA, ALARMA_LENTA, margen)
	_sonar(SND_ALARMA, lerpf(1.3, 1.0, margen), -7.0)


## Fogonazo, anillos por toda la pantalla y fanfarria.
##
## Se lanza al ganar y coincide con la cámara lenta, así que la celebración se
## ve entera antes de que aparezca la pantalla de resultado. Los anillos se
## registran como efectos y no como detonaciones: adornan, no contagian.
func _celebrar() -> void:
	_destello = 1.0
	var rect := get_viewport_rect().size
	for i in 9:
		var e := Explosion.new()
		e.position = Vector2(randf() * rect.x, randf() * rect.y)
		e.max_radius = randf_range(80.0, 190.0)
		e.color = COLOR_BARRA_OK
		e.grow_time = randf_range(0.25, 0.6)
		e.hold_time = 0.25
		e.decay_time = 0.5
		_explosions_root.add_child(e)
		_effects.append(e)
	_sonar(SND_EXITO)


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
	_diag.evento("DERROTA %s  pts=%d esc=%d cadena=%d" % [motivo, _score, _stage(), _best_cascade])
	_sonar(SND_FIN)
	_vibrar(160)
	_shake = shake_max
	_over_title.text = motivo
	_terminar(State.DEAD)


## Arranca la cámara lenta y aplaza el cambio de pantalla.
##
## El mundo sigue moviéndose mientras tanto, así que la última cascada o el
## último fallo se ven con calma antes de que aparezca el resultado.
func _terminar(estado: State) -> void:
	_final_pendiente = estado
	_anticipando = false
	var dur := SLOWMO_DUR_VICTORIA if estado == State.WIN else SLOWMO_DUR_DERROTA
	_slowmo_hasta = Time.get_ticks_msec() + int(dur * 1000.0)
	Engine.time_scale = _ts_base * SLOWMO_FACTOR


## Frena el tiempo cuando falta un movimiento para ganar.
##
## Si la jugada se tuerce y ya no está cerca, se restaura la velocidad: la
## anticipación no puede castigar al que estuvo a punto y no lo consiguió.
func _actualizar_anticipacion() -> void:
	if _final_pendiente >= 0:
		return
	if _state != State.PLAYING or _mode != Mode.CAMPANA:
		if _anticipando:
			_fin_anticipacion()
		return

	var cerca := _a_punto_de_ganar()
	if cerca and not _anticipando:
		_anticipando = true
		_anticipa_hasta = Time.get_ticks_msec() + int(ANTICIPA_MAX * 1000.0)
		Engine.time_scale = _ts_base * ANTICIPA_FACTOR
		_diag.evento("anticipacion pts=%d cadena=%d" % [_score, _best_cascade])
	elif _anticipando and (not cerca or Time.get_ticks_msec() >= _anticipa_hasta):
		_fin_anticipacion()


func _fin_anticipacion() -> void:
	_anticipando = false
	Engine.time_scale = _ts_base


## Si el objetivo se puede cumplir con el siguiente movimiento.
##
## Cada meta se mira de una forma: la cadena es exacta porque se sabe cuántos
## eslabones faltan; en puntos hay que estimar, y solo cuenta si hay una cascada
## viva capaz de rematar.
func _a_punto_de_ganar() -> bool:
	var n := Niveles.nivel(_nivel)
	var v: int = n["valor"]
	match int(n["meta"]):
		Niveles.Meta.CADENA:
			for id in _cadenas:
				if int(_cadenas[id]["len"]) >= v - 1:
					return true
			return false
		Niveles.Meta.PUNTOS, Niveles.Meta.PUNTOS_LIMPIOS:
			return not _explosions.is_empty() and float(_score) >= float(v) * 0.88
		Niveles.Meta.SEGUNDOS:
			return _elapsed >= float(v) - 1.2
	return false


func _rematar() -> void:
	Engine.time_scale = _ts_base
	var estado := _final_pendiente
	_final_pendiente = -1
	# El récord se decide AQUÍ y no al arrancar la cámara lenta: durante ella la
	# cascada puede seguir sumando puntos, y cuentan.
	if estado == State.DEAD and _mode == Mode.SIN_FIN:
		_record_nuevo = _score > _best
		if _record_nuevo:
			_best = _score
			_guardar()
	_ir_a(estado)


func _ganar() -> void:
	_diag.evento("VICTORIA nivel=%d pts=%d" % [_nivel + 1, _score])
	_celebrar()
	_vibrar(60)
	if _nivel + 1 > _nivel_max:
		_nivel_max = mini(_nivel + 1, Niveles.total() - 1)
		_guardar()
	_terminar(State.WIN)


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
	_shake = 0.0
	_hitstop = 0.0
	_score_pop = 0.0
	_t_alarma = 0.0
	_destello = 0.0
	_anticipando = false
	Engine.time_scale = _ts_base
	_stage_shown = _stage()
	_diag.evento("PARTIDA modo=%s nivel=%d mov=%s" % [
		"campana" if _mode == Mode.CAMPANA else "sinfin",
		_nivel + 1, NOMBRES_MOV[_movimiento_actual()]])
	_sonar_musica()
	# En campaña se lee el objetivo antes de empezar. Es lo que faltaba al
	# encadenar niveles: tras "SIGUE" caías dentro sin saber qué te pedían.
	_ir_a(State.BRIEFING if _mode == Mode.CAMPANA else State.READY)


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
	if _marca_muerte and is_instance_valid(_marca_muerte):
		_marca_muerte.queue_free()
		_marca_muerte = null

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

## Estados en los que el campo sigue vivo. MENU y SELECT incluidos: una pantalla
## con el juego moviéndose detrás se siente despierta y enseña la mecánica antes
## de que el jugador toque nada.
func _mundo_activo() -> bool:
	return _state == State.MENU or _state == State.SELECT 		or _state == State.BRIEFING or _state == State.READY 		or _state == State.PLAYING


func _pausar() -> void:
	_antes_de_pausar = _state
	_ir_a(State.PAUSA)


func _ir_a(s: State) -> void:
	_state = s
	_menu_screen.visible = s == State.MENU
	_select_screen.visible = s == State.SELECT
	_over_screen.visible = s == State.DEAD
	_win_screen.visible = s == State.WIN or s == State.FINAL
	_pause_screen.visible = s == State.PAUSA
	_brief_screen.visible = s == State.BRIEFING
	if s == State.BRIEFING:
		_brief_bioma.text = str(Niveles.nivel(_nivel)["bioma"]).to_upper()
		_brief_num.text = "NIVEL %d" % (_nivel + 1)
		_brief_meta.text = Niveles.describir(_nivel)
		_brief_pista.text = str(Niveles.nivel(_nivel)["pista"])
	_log_screen.visible = s == State.LOG
	if s == State.LOG:
		_log_estado.text = "la sesión anterior se cerró SOLA" if _diag.hubo_cierre_brusco 			else "la sesión anterior cerró con normalidad"
		var motor := _diag.errores_del_motor(10)
		if motor.is_empty():
			_log_texto.text = _diag.ultimas_lineas(LOG_LINEAS)
		else:
			# Si el motor registró errores, van ARRIBA: pesan más que cualquier
			# instantánea del juego para saber qué tumbó el proceso.
			_log_texto.text = "-- ERRORES DEL MOTOR --\n%s\n\n-- ESTADO --\n%s" % [
				motor, _diag.ultimas_lineas(LOG_LINEAS - 12)]
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
	sonido = bool(cfg.get_value("opciones", "sonido", true))
	musica = bool(cfg.get_value("opciones", "musica", true))
	# La vibración se fuerza a apagada una vez, aunque el jugador la tuviera
	# encendida de antes: es sospechosa de tumbar la app y no vale dejarla
	# encendida solo porque estaba guardada así.
	if int(cfg.get_value("opciones", "version", 1)) < 2:
		vibracion = false
		_guardar()
	else:
		vibracion = bool(cfg.get_value("opciones", "vibracion", false))


func _guardar() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progreso", "mejor", _best)
	cfg.set_value("progreso", "nivel_max", _nivel_max)
	cfg.set_value("opciones", "sonido", sonido)
	cfg.set_value("opciones", "musica", musica)
	cfg.set_value("opciones", "vibracion", vibracion)
	cfg.set_value("opciones", "version", 2)
	cfg.save(SAVE_PATH)


func _update_ui() -> void:
	_menu_best.text = "mejor sin fin  %d" % _best
	# El botón se pone en rojo si la sesión anterior murió sin avisar: si no, el
	# registro estaría ahí y nadie lo miraría nunca.
	_btn_log.color = Color("ff5470") if _diag != null and _diag.hubo_cierre_brusco 		else Color(0.25, 0.25, 0.32)

	if _state == State.PAUSA:
		# Apagado = apagado a la vista: el círculo se atenúa. Un interruptor que
		# no dice en qué estado está no es un interruptor.
		_opt_sonido.modulate.a = 1.0 if sonido else 0.28
		_opt_musica.modulate.a = 1.0 if musica else 0.28
		_opt_vibra.modulate.a = 1.0 if vibracion else 0.28
		return

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
	# El marcador da un golpe de escala en cada punto. Es lo que hace que subir
	# se sienta como algo que pasa, y no como un número que cambia.
	_score_label.pivot_offset = _score_label.size * 0.5
	var punch := 1.0 + 0.18 * _score_pop * _score_pop
	_score_label.scale = Vector2(punch, punch)
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
	# En los niveles que se pierden al primer fallo, un contador 0 / 5 sería
	# mentira: no hay margen que gastar.
	if _mode == Mode.CAMPANA and Niveles.exige_limpieza(_nivel):
		_fallos_label.text = "sin fallos permitidos"
		_fallos_label.modulate = Color("ff5470")
	else:
		_fallos_label.text = "fallos  %d / %d" % [_fallos, _fallos_permitidos()]
		_fallos_label.modulate = Color("ff5470") if _fallos > 0 else Color(0.45, 0.45, 0.55)

	var frac := clampf(_time_left / time_max, 0.0, 1.0)
	_bar_fill.size = Vector2(_bar_bg.size.x * frac, _bar_bg.size.y)
	if _time_left < WARN_TIME:
		_bar_fill.color = COLOR_BARRA_PELIGRO
	elif _time_left < ALERTA_TIME:
		_bar_fill.color = COLOR_BARRA_ALERTA
	else:
		_bar_fill.color = COLOR_BARRA_OK

	# El multiplicador solo existe mientras la cascada está viva.
	_sync_combos()

	_flash_label.modulate.a = clampf(_flash_left / (FLASH_TIME * 0.5), 0.0, 1.0)
