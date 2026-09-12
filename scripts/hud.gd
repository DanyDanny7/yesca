class_name Hud
extends Control

## Todo lo que hay en pantalla que no es juego.
##
## No es un asset: se dibuja con tipografía y formas. Lo único que se importa es
## la fuente.
##
## Está separado de Main porque el HUD tiene su propia unidad de medida. El juego
## piensa en píxeles de pantalla —el radio de contagio, la tolerancia del toque—
## y el HUD piensa en units de un lienzo de 1080 x 1920 que se escalan al
## dispositivo. Mezclar las dos en el mismo fichero es cómo acaban apareciendo
## medidas en píxeles de móvil, que es justo lo que rompe esto en la tableta.

const RUTA_FUENTE := "res://fuentes/Fredoka[wdth,wght].ttf"
const RUTA_COLORES := "res://datos/hud_colores.json"

## El lienzo de diseño. Todas las medidas de la especificación van aquí dentro.
const LIENZO := Vector2(1080.0, 1920.0)
## Suelo de legibilidad para lo secundario y techo para todo.
const K_MIN_SECUNDARIO := 0.75
const K_MAX := 1.6

## Arco del tiempo.
const ARCO_RADIO := 408.0
const ARCO_GROSOR := 21.0
const ARCO_CENTRO := Vector2(540.0, 456.0)
## Fracción de tiempo por debajo de la cual el arco pulsa, y cada cuánto.
const CRITICO_UMBRAL := 0.15
const CRITICO_PULSO := 0.5

## El velo bajo el arco. No es decoración: sin él el HUD claro no aguanta sobre
## Hormigas ni Río, que tienen la mitad de arriba clara.
const VELO_ALTO := 384.0
const VELO_DE := 0.9
const VELO_MEDIO := 0.62
const VELO_A := 0.0
## El velo se pinta con una textura de degradado estirada, no a bandas.
##
## Con veinticuatro franjas de draw_rect el salto de opacidad entre dos es de
## tres centésimas, y sobre el lecho claro de Hormigas se leen como rayas. La
## textura la interpola la GPU y no hay saltos.

## Opacidades de la especificación.
const OP_PRINCIPAL := 1.0
const OP_SECUNDARIO := 0.82
const OP_TENUE := 0.72
const OP_PISTA := 0.2
const OP_PILDORA := 0.18

## Medidas de cada pieza, en units del lienzo. Todas salen de la especificación.
const MARCADOR_TAM := 132.0
const MARCADOR_Y := 186.0
const MARCADOR_INTER := -4.0
const RECORD_TAM := 30.0
const RECORD_Y := 336.0
const RECORD_INTER := 4.5
const PILDORA_TAM := 54.0
const PILDORA_Y := 396.0
const PILDORA_AIRE := Vector2(30.0, 9.0)
const PILDORA_RADIO := 60.0
const CADENA_TAM := 27.0
const CADENA_MARGEN := 42.0
const VIDA_DIAMETRO := 21.0
const VIDA_SEPARACION := 12.0
const VIDA_CONTORNO := 3.6
const VIDA_GASTADA_ALFA := 0.45
## El botón de pausa. Se DIBUJA a 78 pero el toque mide 132: en el pulgar, un
## objetivo de 78 units en la esquina superior se falla más de lo que parece, y
## fallar la pausa en un juego con reloj cuesta la partida.
const PAUSA_TAM := 78.0
const PAUSA_TOQUE := 132.0
const PAUSA_Y := 54.0
const PAUSA_DERECHA := 42.0

const FLOTANTE_TAM := 72.0
const FLOTANTE_SUBE := 78.0
const FLOTANTE_VIDA := 1.1
const FLOTANTE_REBOTE := 1.12
## El golpe del marcador al sumar: no se anima la cifra contando hacia arriba,
## el número salta y el golpe es el que cuenta la subida.
const MARCADOR_GOLPE := 1.14
const MARCADOR_GOLPE_SUBE := 0.07
const MARCADOR_GOLPE_BAJA := 0.2

## La pausa. El diseño solo trae SEGUIR y SALIR; las cuatro opciones que ya
## existían se quedan, pero degradadas a una fila de fichas por debajo del
## enlace. Quitarlas habría sido perder función por seguir una maqueta, y
## dejarlas como botones grandes habría roto la jerarquía: en esta pantalla lo
## único importante es volver al juego.
const FONDO_PAUSA := 0.68
const BOTON_TAM := 63.0
const BOTON_ALTO := 96.0
const BOTON_RADIO := 48.0
const BOTON_AIRE := Vector2(42.0, 12.0)
## Las fichas son círculos con un icono dentro, no etiquetas de texto.
##
## Un icono se reconoce de un vistazo y no hay que leerlo, que es lo que quieres
## en una pantalla de pausa: se entra a ella para salir cuanto antes. Y el
## círculo es la forma que ya usa todo el juego —los targets, el botón de
## pausa—, así que la pausa no introduce un vocabulario nuevo.
const FICHA_DIAMETRO := 96.0
const FICHA_SEPARACION := 36.0
## Lo que tarda una ficha en pasar de apagada a encendida, en segundos.
##
## 0,18 es lo mismo que tarda el morro de una hormiga en girar y lo que tarda el
## xN en asentarse. Que todo lo que cambia en pantalla tarde lo mismo es lo que
## hace que el juego se sienta de una pieza y no de varias.
##
## No lleva ademas un golpe de escala a propósito: la especificación dice tres
## animaciones y ni una más, y las tres ya están cogidas por los puntos
## flotantes, el marcador y el xN.
const OPCION_TRANSICION := 0.18

## Segmentos por esquina redondeada. Con menos se ven las facetas.
const ESQUINA_PASOS := 6

## La barra que cruza el icono cuando está apagado. Un icono atenuado se lee
## como «deshabilitado»; la barra dice «apagado», que no es lo mismo.
const ICONO_BARRA := 5.0
## Cuánto del círculo ocupa el dibujo. El resto es aire: un icono pegado al
## borde de su ficha se lee como una mancha, no como un símbolo.
const ICONO_CAJA := 0.62


## Las pantallas que interrumpen. El fondo se apaga por debajo y el contenido se
## centra en el eje vertical: lo que interrumpe se centra, lo que acompaña se
## queda arriba.
const FONDO_INICIO := 0.62
const FONDO_FIN := 0.74
const TITULO_TAM := 171.0
const TOCA_TAM := 63.0
const TOCA_INTER := 4.5
const OBJETIVO_TAM := 108.0
const PIE_TAM := 63.0
const PIE_MARGEN := 36.0
const FIN_MARCADOR_TAM := 366.0
const FIN_MARCADOR_INTER := -2.5
const NOTICIA_TAM := 63.0

## Los tres pesos. Se piden por número: la fuente es variable y trae los ejes
## dentro, así que no hay tres ficheros.
const PESO_MEDIO := 500
const PESO_SEMI := 600
const PESO_NEGRITA := 700

## Colores del bioma en curso.
var onda := Color("ffd694")
var paleta := Color("070b16")
var claro := Color("fff6ea")

## Los cuatro iconos de la pausa, en el orden en que los pide Main.
enum { ICONO_SONIDO, ICONO_MUSICA, ICONO_VIBRA, ICONO_SACUDIDA, ICONO_PAUSA }

## En qué pantalla está el juego. El HUD dibuja distinto en cada una.
## OCULTO es el menú, el selector y el registro: esas pantallas son de la
## interfaz vieja y el HUD no debe pintar nada encima.
enum Estado { OCULTO, JUEGO, INICIO, PAUSA, FIN }

var estado: Estado = Estado.JUEGO
## Textos de las pantallas que interrumpen. Los pone Main.
var titulo := ""
var objetivo := ""
var pie := ""
var fin_titulo := ""
var fin_noticia := ""
## Las opciones de la pausa: [{icono, encendida}]. Las pone Main.
var opciones: Array[Dictionary] = []
## Cuánto lleva encendida cada ficha, de 0 a 1. Es lo que se interpola.
var _opcion_t: Array[float] = []

## Dónde quedaron los toques de la pausa, en píxeles. Los calcula el dibujo y
## los consulta Main: quien pinta un botón es quien sabe dónde está.
var _r_seguir := Rect2()
var _r_salir := Rect2()
var _r_opciones: Array[Rect2] = []

## Lo que el HUD necesita saber de la partida. Lo pone Main.
var frac_tiempo: float = 1.0
var corriendo: bool = false
var puntos: int = 0
var record: int = 0
var multiplicador: int = 0
var cadena: int = 0
var vidas: int = 0
var vidas_gastadas: int = 0

## Los flotantes vivos. Cada uno es {texto, origen, t}.
var _flotantes: Array[Dictionary] = []
var _golpe: float = 0.0

## Los iconos de la pausa, por su número de ICONO_*.
var _iconos := {}
var _velo: GradientTexture2D = null
var _fuentes := {}
var _tabla := {}
var _pulso: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_cargar_fuentes()
	_cargar_tabla()
	_cargar_iconos()
	_rehacer_velo()


## Una FontVariation por peso, creadas una vez.
##
## OJO con la clave del diccionario: tiene que ser el TAG ENTERO, no el nombre.
## Con `{"wght": 700}` Godot no se queja y no aplica nada —se queda en el peso
## por defecto, que en Fredoka es 300—. Medido: la misma cadena a 120 px pinta
## 5.059 píxeles de tinta con la clave de texto y 13.471 con el tag. El ejemplo
## del LEEME de la entrega usa la forma que no funciona.
func _cargar_fuentes() -> void:
	var base := load(RUTA_FUENTE)
	if base == null:
		push_warning("HUD: no encuentro la fuente en %s" % RUTA_FUENTE)
		return
	var ts := TextServerManager.get_primary_interface()
	var tag_peso := ts.name_to_tag("wght")
	var tag_ancho := ts.name_to_tag("wdth")
	for peso in [PESO_MEDIO, PESO_SEMI, PESO_NEGRITA]:
		var f := FontVariation.new()
		f.base_font = base
		# El eje de ancho se queda en 100 en todo el HUD. No se usa; está ahí
		# porque la fuente lo trae.
		f.variation_opentype = {tag_peso: peso, tag_ancho: 100}
		_fuentes[peso] = f


func _cargar_iconos() -> void:
	var nombres := {
		ICONO_SONIDO: "sonido",
		ICONO_MUSICA: "musica",
		ICONO_VIBRA: "vibra",
		ICONO_SACUDIDA: "sacudida",
		ICONO_PAUSA: "pausa",
	}
	for cual in nombres:
		var ruta: String = "res://arte/iconos/%s.svg" % nombres[cual]
		if ResourceLoader.exists(ruta):
			_iconos[cual] = load(ruta)
		else:
			push_warning("HUD: falta el icono %s" % ruta)


func _cargar_tabla() -> void:
	if not FileAccess.file_exists(RUTA_COLORES):
		return
	var datos = JSON.parse_string(FileAccess.get_file_as_string(RUTA_COLORES))
	if typeof(datos) == TYPE_DICTIONARY:
		_tabla = datos.get("biomas", {})


func fuente(peso: int) -> Font:
	return _fuentes.get(peso)


## El rectángulo de referencia.
##
## Se pregunta al viewport y no a `size`: este Control lo crea Main por código y
## dentro de un CanvasLayer, así que su `size` es cero hasta que el layout se
## asienta, y con cero el arco se dibujaba centrado en el borde izquierdo. El
## viewport ya sabe cuánto mide desde el primer fotograma.
func pantalla() -> Vector2:
	return get_viewport_rect().size


## El factor de escala del dispositivo.
##
## El MÍNIMO de los dos, no solo el ancho: en tableta 4:3 el ancho da 1,42 y el
## alto 1,07, y escalando por ancho el marcador se comería la guarda de arriba y
## el arco se saldría por los lados.
func k() -> float:
	var r := pantalla()
	if r.x <= 0.0 or r.y <= 0.0:
		return 1.0
	return clampf(minf(r.x / LIENZO.x, r.y / LIENZO.y), 0.0, K_MAX)


## Como k(), pero con suelo para lo secundario: antes de perder el récord,
## preferimos que ocupe algo más de lo previsto.
func k_secundario() -> float:
	return maxf(k(), K_MIN_SECUNDARIO)


## De units del lienzo a píxeles, con el ancla arriba: el arco y el marcador
## cuelgan del borde superior y el lienzo se centra en horizontal.
func punto(u: Vector2) -> Vector2:
	var f := k()
	return Vector2(pantalla().x * 0.5 + (u.x - LIENZO.x * 0.5) * f, u.y * f)


func medida(u: float) -> float:
	return u * k()


## Los tres colores del bioma. Los cinco trabajados vienen de la tabla de la
## entrega; el resto sale de su paleta, que para eso ya tiene onda y fondo.
func configurar(bioma: String, pal: Dictionary) -> void:
	var clave := Arte.slug(bioma)
	if _tabla.has(clave):
		var t: Dictionary = _tabla[clave]
		onda = Color(str(t.get("onda", "#ffd694")))
		paleta = Color(str(t.get("paleta", "#070b16")))
		claro = Color(str(t.get("claro", "#fff6ea")))
	else:
		onda = Color(str(pal.get("onda", "e8e8f0")))
		paleta = Color(str(pal.get("fondo", "0d0d12")))
		# Sin entrada propia, el claro sale de aclarar la onda hasta casi blanco:
		# es lo que hace la tabla en los cinco que sí están.
		claro = onda.lerp(Color.WHITE, 0.82)
	_rehacer_velo()
	queue_redraw()


## El paso del HUD. En pausa NO se llama, igual que a los círculos: el pulso del
## arco se queda donde esté, que es lo que hace el resto del mundo.
func actualizar(delta: float, fraccion: float, reloj_corriendo: bool,
		congelado := false) -> void:
	frac_tiempo = clampf(fraccion, 0.0, 1.0)
	corriendo = reloj_corriendo
	# En pausa no avanza NADA del mundo: el flotante se queda a medio subir y el
	# pulso del arco se detiene donde esté, igual que los círculos. Lo único que
	# sigue vivo es la transición de las fichas, que es de la propia pantalla de
	# pausa y no del juego que hay debajo.
	if not congelado:
		if frac_tiempo <= CRITICO_UMBRAL:
			_pulso = fposmod(_pulso + delta, CRITICO_PULSO)
		else:
			_pulso = 0.0
		if _golpe > 0.0:
			_golpe += delta
			if _golpe > MARCADOR_GOLPE_SUBE + MARCADOR_GOLPE_BAJA:
				_golpe = 0.0
	while _opcion_t.size() < opciones.size():
		_opcion_t.append(0.0)
	for i in opciones.size():
		var meta := 1.0 if bool(opciones[i]["encendida"]) else 0.0
		_opcion_t[i] = move_toward(_opcion_t[i], meta, delta / OPCION_TRANSICION)

	if not congelado:
		var vivos: Array[Dictionary] = []
		for fl in _flotantes:
			fl["t"] = float(fl["t"]) + delta
			if float(fl["t"]) < FLOTANTE_VIDA:
				vivos.append(fl)
		_flotantes = vivos
	queue_redraw()


## Pone la lista de opciones y las deja YA en su sitio, sin transición.
##
## Al abrir la pausa no hay nada que animar: el jugador acaba de llegar y las
## cuatro fichas tienen que estar como las dejó. Animarlas aquí se vería como si
## el juego estuviera encendiéndolas solo.
func poner_opciones(lista: Array[Dictionary]) -> void:
	opciones = lista
	_opcion_t.clear()
	for o in lista:
		_opcion_t.append(1.0 if bool(o["encendida"]) else 0.0)
	queue_redraw()


## Cambia una opción, y esta SÍ se anima: es respuesta a un toque.
func cambiar_opcion(i: int, encendida: bool) -> void:
	if i < 0 or i >= opciones.size():
		return
	opciones[i]["encendida"] = encendida
	queue_redraw()


## Un punto de premio, que nace donde se tocó.
func flotante(texto: String, donde: Vector2) -> void:
	_flotantes.append({"texto": texto, "origen": donde, "t": 0.0})


## El marcador acaba de subir: pega el golpe.
func golpe() -> void:
	_golpe = 0.0001


func _draw() -> void:
	if estado == Estado.OCULTO:
		return
	_dibujar_velo()
	if corriendo:
		_dibujar_arco()
	elif estado == Estado.INICIO:
		# En inicio se ve la pista del arco sin relleno: enseña dónde va a estar
		# el tiempo antes de que empiece a correr.
		_dibujar_pista()
	if estado == Estado.INICIO:
		_dibujar_inicio()
		return
	if estado == Estado.PAUSA:
		_dibujar_pausa()
		return
	if estado == Estado.FIN:
		_dibujar_fin()
		return
	_dibujar_marcador()
	_dibujar_record()
	_dibujar_pildora()
	_dibujar_cadena()
	_dibujar_vidas()
	_dibujar_flotantes()
	_dibujar_boton_pausa()


## El botón de pausa, arriba a la derecha.
func _dibujar_boton_pausa() -> void:
	var tex: Texture2D = _iconos.get(ICONO_PAUSA)
	if tex == null:
		return
	var c := _centro_pausa()
	var d := medida(PAUSA_TAM)
	draw_circle(c, d * 0.5, Color(onda, OP_PILDORA))
	var lado := d * ICONO_CAJA
	draw_texture_rect(tex, Rect2(c - Vector2(lado, lado) * 0.5,
			Vector2(lado, lado)), false, Color(onda, OP_SECUNDARIO))


func _centro_pausa() -> Vector2:
	var d := medida(PAUSA_TAM)
	return Vector2(pantalla().x - medida(PAUSA_DERECHA) - d * 0.5,
			medida(PAUSA_Y) + d * 0.5)


## Dónde se puede tocar para pausar. Más grande que el dibujo, a propósito.
func rect_pausa() -> Rect2:
	var t := medida(PAUSA_TOQUE)
	return Rect2(_centro_pausa() - Vector2(t, t) * 0.5, Vector2(t, t))


## El fondo apagado de las pantallas que interrumpen.
func _apagar(a: float) -> void:
	var r := pantalla()
	draw_rect(Rect2(Vector2.ZERO, r), Color(paleta, a), true)


## La pantalla de inicio: el bioma, la invitación, el objetivo y el pie.
##
## El bloque de título e invitación se centra en el eje vertical como un todo, y
## no cada pieza por su cuenta: centradas por separado, un bioma de nombre largo
## empujaba la invitación fuera de sitio.
func _dibujar_inicio() -> void:
	_apagar(FONDO_INICIO)
	var alto_titulo := medida(TITULO_TAM)
	var alto_toca := medida(TOCA_TAM)
	var hueco := alto_toca * 0.9
	var bloque := alto_titulo + hueco + alto_toca
	var arriba := pantalla().y * 0.5 - bloque * 0.5
	_texto_centrado_px(titulo, arriba, TITULO_TAM, PESO_SEMI,
			Color(claro, OP_PRINCIPAL))
	var y_toca := arriba + alto_titulo + hueco
	_texto_centrado_px("TOCA PARA EMPEZAR", y_toca, TOCA_TAM, PESO_MEDIO,
			Color(onda, OP_SECUNDARIO), TOCA_INTER)

	# El objetivo se centra en SU BANDA, no a una altura fija: con una altura
	# fija, dos líneas lo bajan y cuatro lo pegan al borde.
	var banda_de := y_toca + alto_toca
	var banda_a := pantalla().y - medida(PIE_MARGEN) - medida(PIE_TAM)
	if not objetivo.is_empty() and banda_a > banda_de:
		var alto_obj := medida(OBJETIVO_TAM)
		_texto_centrado_px(objetivo, (banda_de + banda_a) * 0.5 - alto_obj * 0.5,
				OBJETIVO_TAM, PESO_SEMI, Color(onda, OP_PRINCIPAL))

	if not pie.is_empty():
		_texto_centrado_px(pie, pantalla().y - medida(PIE_MARGEN) - medida(PIE_TAM),
				PIE_TAM, PESO_MEDIO, Color(onda, OP_TENUE))


## Dónde cae cada toque de la pausa. Vacíos fuera de ella.
func rect_seguir() -> Rect2:
	return _r_seguir


func rect_salir() -> Rect2:
	return _r_salir


func rect_opcion(i: int) -> Rect2:
	if i < 0 or i >= _r_opciones.size():
		return Rect2()
	return _r_opciones[i]


## La pausa: volver al juego es lo único importante, y por eso es lo único que
## lleva fondo lleno.
func _dibujar_pausa() -> void:
	_apagar(FONDO_PAUSA)
	var alto_t := medida(TOCA_TAM)
	var alto_m := medida(MARCADOR_TAM)
	var alto_b := medida(BOTON_ALTO)
	var alto_s := medida(BOTON_TAM)
	var hueco := alto_t * 0.6
	var bloque := alto_t + hueco + alto_m + hueco + alto_b + hueco + alto_s
	var arriba := pantalla().y * 0.5 - bloque * 0.5

	_texto_centrado_px("PAUSA", arriba, TOCA_TAM, PESO_MEDIO,
			Color(onda, OP_SECUNDARIO), TOCA_INTER)
	var y := arriba + alto_t + hueco
	_texto_centrado_px(str(puntos), y, MARCADOR_TAM, PESO_SEMI,
			Color(onda, OP_PRINCIPAL), MARCADOR_INTER)

	y += alto_m + hueco
	_r_seguir = _boton("SEGUIR", y)
	y += alto_b + hueco
	_r_salir = _enlace("SALIR", y)

	# Las fichas van al pie, lejos del botón: son ajustes, no la salida.
	_r_opciones.clear()
	if opciones.is_empty():
		return
	var d := medida(FICHA_DIAMETRO)
	var sep := medida(FICHA_SEPARACION)
	var total := d * float(opciones.size()) + sep * float(opciones.size() - 1)
	var x := pantalla().x * 0.5 - total * 0.5
	var y_f := pantalla().y - medida(PIE_MARGEN) - d
	for i in opciones.size():
		var caja := Rect2(Vector2(x, y_f), Vector2(d, d))
		var centro := caja.position + caja.size * 0.5
		var t: float = _opcion_t[i] if i < _opcion_t.size() else 0.0
		# Suavizado en los dos extremos: una interpolación recta arranca y frena
		# de golpe, y a 0,18 s eso se nota como un parpadeo.
		var e := t * t * (3.0 - 2.0 * t)
		draw_circle(centro, d * 0.5, Color(onda, lerpf(OP_PILDORA, OP_PRINCIPAL, e)))
		# El icono cruza del tono tenue sobre el hueco al color de la paleta
		# sobre el relleno, que es el mismo camino que hace el fondo.
		var tinta := Color(onda, OP_TENUE).lerp(paleta, e)
		_icono(int(opciones[i]["icono"]), centro, d * 0.5, tinta)
		if e < 1.0:
			# La barra no se desvanece: se RETIRA hacia su esquina. Desvanecerla
			# la dejaba un instante medio puesta encima del icono ya encendido,
			# que es justo el estado que no existe.
			var largo := (1.0 - e) * 0.55 * d
			var dir := Vector2(0.7071, -0.7071)
			var ini := centro - dir * 0.55 * d * 0.5
			draw_line(ini, ini + dir * largo, tinta, medida(ICONO_BARRA), true)
		_r_opciones.append(caja)
		x += d + sep


## Los cuatro iconos de la pausa. Van dibujados y no como imagen: el juego
## entero se dibuja, y un PNG aquí sería la única pieza que habría que redibujar
## cada vez que cambie el tono de un bioma.
## Los cuatro iconos de la pausa, teñidos con el color del bioma.
##
## Son Material Symbols en su variante ROUNDED, no dibujo propio. Dibujarlos a
## mano con líneas y arcos salía tosco a cuarenta y ocho píxeles: los contornos
## sin suavizar se dentaban y cada icono tenía el peso de trazo que le tocara,
## porque no hay forma de afinar cuatro dibujos a ojo hasta que pesen igual. Un
## juego de iconos hecho por tipógrafos ya viene con esa consistencia dentro.
##
## Y se eligió la variante Rounded porque Fredoka es redondeada: con la Outlined
## el icono se leía como de otra familia que el texto de al lado.
##
## El SVG viene en negro y se dibuja MODULADO, así que el mismo fichero sirve
## para los diecisiete biomas sin una copia por color.
func _icono(cual: int, c: Vector2, r: float, col: Color) -> void:
	var tex: Texture2D = _iconos.get(cual)
	if tex == null:
		return
	var lado := r * 2.0 * ICONO_CAJA
	draw_texture_rect(tex, Rect2(c - Vector2(lado, lado) * 0.5,
			Vector2(lado, lado)), false, col)


## Botón lleno: fondo en la onda y texto en la paleta, que es el contraste
## máximo que tiene el bioma sin traer un color de fuera.
func _boton(txt: String, y_px: float) -> Rect2:
	var f: Font = fuente(PESO_SEMI)
	if f == null:
		return Rect2()
	var tam := int(round(medida(BOTON_TAM)))
	var aire := Vector2(medida(BOTON_AIRE.x), medida(BOTON_AIRE.y))
	var ancho := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x + aire.x * 2.0
	var alto := medida(BOTON_ALTO)
	var caja := Rect2(Vector2(pantalla().x * 0.5 - ancho * 0.5, y_px),
			Vector2(ancho, alto))
	_caja_redonda(caja, medida(BOTON_RADIO), Color(onda, OP_PRINCIPAL))
	_texto_en(f, txt, Vector2(caja.position.x + aire.x,
			y_px + alto * 0.5 + float(tam) * 0.36), tam, paleta)
	return caja


## Un rectángulo de esquinas redondeadas, macizo.
##
## draw_rect no sabe redondear, así que se arma el contorno y se rellena como
## polígono. El borde se repasa con una polilínea del mismo color y suavizada:
## un polígono suelto sale con el filo dentado, que es lo mismo que afeaba los
## iconos antes de traerlos hechos.
func _caja_redonda(caja: Rect2, radio: float, col: Color) -> void:
	var pts := _contorno_redondo(caja, radio)
	if pts.size() < 3:
		return
	draw_colored_polygon(pts, col)
	draw_polyline(pts + PackedVector2Array([pts[0]]), col, 1.0, true)


func _contorno_redondo(caja: Rect2, radio: float) -> PackedVector2Array:
	var rr := minf(radio, minf(caja.size.x, caja.size.y) * 0.5)
	var pts := PackedVector2Array()
	var esquinas := [
		[caja.position + Vector2(caja.size.x - rr, caja.size.y - rr), 0.0],
		[caja.position + Vector2(rr, caja.size.y - rr), PI * 0.5],
		[caja.position + Vector2(rr, rr), PI],
		[caja.position + Vector2(caja.size.x - rr, rr), PI * 1.5]]
	for e in esquinas:
		var centro: Vector2 = e[0]
		var desde: float = float(e[1])
		for i in ESQUINA_PASOS + 1:
			var a := desde + PI * 0.5 * float(i) / float(ESQUINA_PASOS)
			pts.append(centro + Vector2(cos(a), sin(a)) * rr)
	return pts


## Enlace secundario: sin fondo, al 72%. Lo que no es la acción principal no
## puede parecerse a un botón.
func _enlace(txt: String, y_px: float) -> Rect2:
	var f: Font = fuente(PESO_MEDIO)
	if f == null:
		return Rect2()
	var tam := int(round(medida(BOTON_TAM)))
	var inter := medida(TOCA_INTER)
	var base := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
	var ancho := base + inter * float(maxi(0, txt.length() - 1))
	var x := pantalla().x * 0.5 - ancho * 0.5
	_texto_en(f, txt, Vector2(x, y_px + float(tam) * 0.8), tam,
			Color(onda, OP_TENUE), inter)
	# El toque es más alto que la letra: un enlace de 63 units con el área justa
	# se falla con el pulgar.
	return Rect2(Vector2(x - medida(BOTON_AIRE.x), y_px - medida(BOTON_AIRE.y)),
			Vector2(ancho + medida(BOTON_AIRE.x) * 2.0, float(tam) + medida(BOTON_AIRE.y) * 2.0))


## La pantalla de fin: la cifra es la noticia, y el récord batido la remata.
func _dibujar_fin() -> void:
	_apagar(FONDO_FIN)
	var alto_t := medida(TOCA_TAM)
	var alto_m := medida(FIN_MARCADOR_TAM)
	var alto_n := medida(NOTICIA_TAM)
	var hueco := alto_t * 0.5
	var bloque := alto_t + hueco + alto_m
	if not fin_noticia.is_empty():
		bloque += hueco + alto_n
	var arriba := pantalla().y * 0.5 - bloque * 0.5
	_texto_centrado_px(fin_titulo, arriba, TOCA_TAM, PESO_MEDIO,
			Color(onda, OP_SECUNDARIO), TOCA_INTER)
	var y_m := arriba + alto_t + hueco
	_texto_centrado_px(str(puntos), y_m, FIN_MARCADOR_TAM, PESO_SEMI,
			Color(onda, OP_PRINCIPAL), FIN_MARCADOR_INTER)
	if not fin_noticia.is_empty():
		_texto_centrado_px(fin_noticia, y_m + alto_m + hueco, NOTICIA_TAM,
				PESO_SEMI, Color(onda, OP_PRINCIPAL), TOCA_INTER)


## Como _texto_centrado, pero con la Y ya en píxeles: las pantallas que se
## centran no pueden expresar su altura en units del lienzo, porque dependen de
## lo que mida la pantalla de verdad.
func _texto_centrado_px(txt: String, y_px: float, u_tam: float, peso: int,
		col: Color, u_inter: float = 0.0) -> void:
	var f: Font = fuente(peso)
	if f == null or txt.is_empty():
		return
	var tam := int(round(medida(u_tam)))
	if tam <= 0:
		return
	var inter := medida(u_inter)
	var base := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
	var ancho := base + inter * float(maxi(0, txt.length() - 1))
	_texto_en(f, txt, Vector2(pantalla().x * 0.5 - ancho * 0.5, y_px + float(tam) * 0.8),
			tam, col, inter)


## Solo la pista del arco, sin el tramo lleno.
func _dibujar_pista() -> void:
	var radio := medida(ARCO_RADIO)
	if radio <= 0.0:
		return
	draw_arc(punto(ARCO_CENTRO), radio, PI, TAU, 96,
			Color(onda, OP_PISTA), medida(ARCO_GROSOR), true)


## Texto centrado en X sobre una Y del lienzo, con su interletrado.
##
## El interletrado escala con todo lo demás: uno fijo sobre una letra escalada se
## abre o se cierra según el móvil, que es el mismo error que medir en píxeles de
## dispositivo.
func _texto_centrado(txt: String, u_y: float, u_tam: float, peso: int,
		col: Color, u_inter: float = 0.0, escala: float = 1.0) -> void:
	var f: Font = fuente(peso)
	if f == null or txt.is_empty():
		return
	var tam := int(round(medida(u_tam) * escala))
	if tam <= 0:
		return
	var inter := medida(u_inter) * escala
	var base := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
	var ancho := base + inter * float(maxi(0, txt.length() - 1))
	var x := pantalla().x * 0.5 - ancho * 0.5
	var y := medida(u_y) + float(tam) * 0.5
	_texto_en(f, txt, Vector2(x, y), tam, col, inter)


## Dibuja letra a letra cuando hay interletrado; de una vez cuando no.
##
## Godot no tiene interletrado en draw_string, así que hay que repartirlo a mano.
## Sin él, las cifras redondas de Fredoka se separan demasiado y el marcador
## parece deletreado.
func _texto_en(f: Font, txt: String, pos: Vector2, tam: int, col: Color,
		inter: float = 0.0) -> void:
	if is_zero_approx(inter):
		f.draw_string(get_canvas_item(), pos, txt,
				HORIZONTAL_ALIGNMENT_LEFT, -1, tam, col)
		return
	var x := pos.x
	for i in txt.length():
		var c := txt[i]
		f.draw_string(get_canvas_item(), Vector2(x, pos.y), c,
				HORIZONTAL_ALIGNMENT_LEFT, -1, tam, col)
		x += f.get_string_size(c, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x + inter


func _dibujar_marcador() -> void:
	var escala := 1.0
	if _golpe > 0.0:
		# Sube en 0,07 s y baja en 0,2 s. Subir y bajar en el mismo tiempo hacía
		# que el golpe se leyera como un temblor en vez de como un empujón.
		if _golpe <= MARCADOR_GOLPE_SUBE:
			escala = lerpf(1.0, MARCADOR_GOLPE, _golpe / MARCADOR_GOLPE_SUBE)
		else:
			var u := (_golpe - MARCADOR_GOLPE_SUBE) / MARCADOR_GOLPE_BAJA
			escala = lerpf(MARCADOR_GOLPE, 1.0, clampf(u, 0.0, 1.0))
	_texto_centrado(str(puntos), MARCADOR_Y, MARCADOR_TAM, PESO_SEMI,
			Color(onda, OP_PRINCIPAL), MARCADOR_INTER, escala)


func _dibujar_record() -> void:
	if record <= 0:
		return
	_texto_centrado("RÉCORD %d" % record, RECORD_Y, RECORD_TAM, PESO_MEDIO,
			Color(onda, OP_SECUNDARIO), RECORD_INTER)


## El multiplicador solo existe mientras la cascada está viva.
func _dibujar_pildora() -> void:
	if multiplicador < 2:
		return
	var f: Font = fuente(PESO_SEMI)
	if f == null:
		return
	var txt := "×%d" % multiplicador
	var tam := int(round(medida(PILDORA_TAM)))
	var med := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, tam)
	var aire := Vector2(medida(PILDORA_AIRE.x), medida(PILDORA_AIRE.y))
	var caja := Vector2(med.x + aire.x * 2.0, float(tam) + aire.y * 2.0)
	var esquina := Vector2(pantalla().x * 0.5 - caja.x * 0.5, medida(PILDORA_Y))
	_caja_redonda(Rect2(esquina, caja), medida(PILDORA_RADIO), Color(onda, OP_PILDORA))
	_texto_en(f, txt,
			Vector2(esquina.x + aire.x, esquina.y + aire.y + float(tam) * 0.78),
			tam, Color(onda, OP_PRINCIPAL))


func _dibujar_cadena() -> void:
	if cadena <= 0:
		return
	var f: Font = fuente(PESO_MEDIO)
	if f == null:
		return
	var tam := int(round(CADENA_TAM * k_secundario()))
	var m := medida(CADENA_MARGEN)
	_texto_en(f, "CADENA %d" % cadena, Vector2(m, m + float(tam)), tam,
			Color(onda, OP_TENUE), medida(RECORD_INTER))


## Las vidas, bajo la cadena. Las gastadas se quedan en contorno: enseñar solo
## las que quedan esconde cuántas había, que es la mitad de la información.
func _dibujar_vidas() -> void:
	if vidas <= 0:
		return
	var d := medida(VIDA_DIAMETRO)
	var sep := medida(VIDA_SEPARACION)
	var m := medida(CADENA_MARGEN)
	var y := m + CADENA_TAM * k_secundario() + sep + d * 0.5
	for i in vidas:
		var c := Vector2(m + d * 0.5 + float(i) * (d + sep), y)
		if i < vidas - vidas_gastadas:
			draw_circle(c, d * 0.5, Color(onda, OP_SECUNDARIO))
		else:
			draw_arc(c, d * 0.5, 0.0, TAU, 24,
					Color(onda, VIDA_GASTADA_ALFA), medida(VIDA_CONTORNO), true)


## Los puntos flotantes son el premio: nacen donde se tocó, rebotan y suben.
func _dibujar_flotantes() -> void:
	var f: Font = fuente(PESO_NEGRITA)
	if f == null:
		return
	for fl in _flotantes:
		var t: float = float(fl["t"]) / FLOTANTE_VIDA
		# Entra al 80% y alfa 0; en 0,2 s llega al 112% y baja al 100%.
		var e := 1.0
		var a := 1.0
		if t < 0.18:
			var u := t / 0.18
			e = lerpf(0.8, FLOTANTE_REBOTE, u)
			a = u
		elif t < 0.32:
			e = lerpf(FLOTANTE_REBOTE, 1.0, (t - 0.18) / 0.14)
		if t > 0.7:
			a = 1.0 - (t - 0.7) / 0.3
		var origen: Vector2 = fl["origen"]
		var pos := origen - Vector2(0.0, medida(FLOTANTE_SUBE) * t)
		var tam := int(round(medida(FLOTANTE_TAM) * e))
		if tam <= 0:
			continue
		var txt: String = fl["texto"]
		var ancho := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
		_texto_en(f, txt, Vector2(pos.x - ancho * 0.5, pos.y), tam,
				Color(onda, clampf(a, 0.0, 1.0)))


## Degradado de la paleta bajo el arco, por encima del telón y por debajo del
## HUD. Va a bandas porque _draw no tiene degradados.
func _dibujar_velo() -> void:
	var alto := medida(VELO_ALTO)
	if alto <= 0.0 or _velo == null:
		return
	draw_texture_rect(_velo, Rect2(0.0, 0.0, pantalla().x, alto), false)


## Rehace la textura del velo con el color del bioma.
##
## Tres paradas y no dos: del 90% al 62% en la primera mitad y de ahí al 0%. Una
## recta del 90 al 0 dejaba el borde de abajo demasiado presente justo donde
## empieza el campo de juego.
func _rehacer_velo() -> void:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	g.colors = PackedColorArray([
		Color(paleta, VELO_DE), Color(paleta, VELO_MEDIO), Color(paleta, VELO_A)])
	_velo = GradientTexture2D.new()
	_velo.gradient = g
	_velo.width = 1
	_velo.height = 256
	_velo.fill_from = Vector2(0.0, 0.0)
	_velo.fill_to = Vector2(0.0, 1.0)


## El arco del tiempo: semicírculo que solo se acorta, nunca se mueve.
##
## Se dibuja SIEMPRE la pista entera por debajo y encima el tramo que queda. Sin
## la pista, un arco corto no se lee como «queda poco» sino como «hay un arco
## pequeño»: hace falta ver el hueco para saber lo que se ha ido.
func _dibujar_arco() -> void:
	var centro := punto(ARCO_CENTRO)
	var radio := medida(ARCO_RADIO)
	var grosor := medida(ARCO_GROSOR)
	if radio <= 0.0:
		return
	# De PI a TAU: el semicírculo de arriba, que en Godot —con la Y hacia
	# abajo— va del extremo izquierdo, por encima, al derecho.
	draw_arc(centro, radio, PI, TAU, 96, Color(onda, OP_PISTA), grosor, true)
	if frac_tiempo <= 0.0:
		return
	var alfa := OP_PRINCIPAL
	if frac_tiempo <= CRITICO_UMBRAL:
		# En tiempo crítico pulsa el tramo que queda. Nada más de la pantalla
		# pulsa: si el marcador también latiera, el jugador no sabría qué corre
		# peligro.
		var f := 0.5 - 0.5 * cos(TAU * _pulso / CRITICO_PULSO)
		alfa = lerpf(0.35, 1.0, f)
	draw_arc(centro, radio, PI, PI + PI * frac_tiempo, 96,
			Color(onda, alfa), grosor, true)
