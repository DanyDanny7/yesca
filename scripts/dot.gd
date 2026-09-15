class_name Dot
extends Node2D

## Un círculo del campo.
##
## Se dibuja a sí mismo con _draw(): para formas geométricas no hace falta ni
## sprite ni escena propia, se instancia con Dot.new().
##
## No mueve su posición en un _process propio. Lo hace Main llamando a mover(),
## y por dos motivos: hay modos que necesitan ver a los demás círculos o a las
## detonaciones (choque, enjambre, huida), y con Main al mando el orden de
## actualización es determinista en vez de depender del árbol de nodos.

## Cómo se desplaza el círculo. Es la base de los biomas: un bioma no es una
## paleta, es una regla de movimiento y de interacción con las explosiones.
enum Movimiento {
	REBOTE,     ## línea recta, rebota en los bordes
	ABEJA,      ## tirones, pausas y giros bruscos
	NIEVE,      ## cae despacio con vaivén lateral, y reaparece arriba
	CHOQUE,     ## como rebote, pero también chocan entre ellos
	CORRIENTE,  ## arrastrados por un río, salen por un lado y vuelven por el otro
	ENJAMBRE,   ## se buscan entre sí y forman grumos
	HUIDA,      ## se apartan de las detonaciones activas
	BRASA,      ## suben y se renuevan por abajo
	CIRCUITO,   ## solo en horizontal y vertical, con giros de 90 grados
	PLANEO,     ## viran suave y cabecean, como algo que se deja caer en el aire
	MISIL,      ## aceleran en su rumbo hasta un tope
	BOMBARDEO,  ## caen de arriba abajo zigzagueando, y no deben llegar al suelo
	METEORO,    ## rumbo fijo hacia el planeta, acelerando; tampoco debe llegar
	PATRULLA,   ## tramos rectos, se para en seco y sale en otra dirección
	HORMIGA,    ## avanza sin parar con el rumbo girando poco a poco
	FUGAZ,      ## cruza la pantalla en recta con una curvatura leve y se va
	GLOBO,      ## sube con una ese suave y se va por arriba; no rebota ni choca
	BILLAR,     ## vive dentro de la mesa: rueda, roza, rebota en las bandas
}

## Qué se dibuja. Un bioma con copos de nieve o abejas se explica solo; con
## círculos hay que explicarlo con un texto.
##
## Todas las formas caben en el mismo radio y se dibujan a mano: a nueve píxeles
## no hay sitio para detalle, así que lo que las distingue es la silueta.
enum Forma { CIRCULO, COPO, ABEJA, HOJA, BOLA, DRON, CHISPA, CHIP, AVION, MISIL,
		PEZ, ESTRELLA, LLAMA, BURBUJA, GLOBO, METEORO, ROBOT,
		HORMIGA, FUGAZ }

## Cómo se orienta una forma respecto a su rumbo.
##
## Hasta ahora era una lista de excepciones dentro de `mover()`, y estaba mal en
## dos sitios que se ven a simple vista: la abeja y el pez se dibujan de PERFIL,
## así que al girar hacia un rumbo que va a la izquierda volaban y nadaban boca
## arriba. Nadie mira un pez del revés y piensa "va hacia allá"; piensa que está
## muerto.
##
## La regla que ordena la tabla: **una forma solo puede dar la vuelta entera si
## se dibujó vista desde arriba.** El dron y el meteoro sí; la abeja, el pez y
## el avión, no.
enum Giro {
	FIJO,     ## nunca gira. Lo que tiene peso o cuelga: bolas, globos, robots
	RUMBO,    ## gira hasta apuntar a donde va. Solo vistas cenitales
	ESPEJO,   ## no gira: se refleja al ir hacia la izquierda
	CABECEO,  ## se refleja Y se inclina un poco hacia donde va. Perfiles vivos
	NORIA,    ## gira por su cuenta, sin relación con el rumbo. Hojas cayendo
	DERIVA,   ## gira despacio y cada uno a su ritmo. Copos en el aire
	BALANCEO, ## se mece poco y acotado, sobre un eje que no es el centro
}

## Cuánto se inclina como mucho una forma con CABECEO, en radianes.
##
## Corto a propósito: pasado este ángulo un pez deja de leerse como que baja y
## empieza a leerse como que se cae.
const INCLINACION_MAX := 0.55
## Vueltas por segundo de una forma con NORIA.
const NORIA_VUELTAS := 0.9
## Muestras del anillo de la estela del meteoro.
##
## Veinticuatro y no las cuarenta de la fugaz: la fugaz es un acontecimiento y
## hay una; aquí hay un campo entero de rocas, así que la estela tiene que ser
## más corta y más barata. Son tres polígonos de cincuenta vértices por meteoro.
const MUESTRAS_ESTELA := 24
## Semiancho máximo de la estela, en radios de dibujo.
const ANCHO_ESTELA := 0.22
## A partir de cuántos radios de separación entre dos muestras se considera que
## el meteoro se ha teletransportado y hay que vaciar el anillo.
const SALTO_ESTELA := 4.0

## Entre qué velocidades gira una forma con DERIVA, en radianes por segundo.
##
## Lento y desigual a propósito. Un copo no cae recto: la inercia y el roce del
## aire lo hacen voltear, y cada uno lo hace a su aire porque cada uno tiene su
## masa y su forma. Con una sola velocidad para todos, veinticinco copos girando
## igual se leen como un engranaje.
##
## El máximo da una vuelta completa en once segundos y el mínimo en cuarenta y
## dos. Más rápido dejaría de parecer deriva y empezaría a parecer un molinillo.
const DERIVA_MIN := 0.15
const DERIVA_MAX := 0.55

## Cuánto se mece como mucho una forma con BALANCEO, en radianes.
##
## Cinco grados. Más y el globo deja de mecerse y empieza a cabecear, que es lo
## que hace algo empujado y no algo que flota.
const BALANCEO_MAX := 0.0873
## Dónde está el eje del balanceo, en fracción del alto del sprite desde el
## centro y hacia abajo.
##
## No es el centro: un globo pende del nudo, así que es el nudo el que se queda
## quieto y el cuerpo el que se inclina. Girando por el centro, el nudo describe
## un arco y el globo se lee como si lo llevara alguien de la mano.
const BALANCEO_PIVOTE := 0.34

## A qué fracción de su rapidez sube un globo.
##
## La entrega pide 54 px/s. Sale de la rapidez del círculo y no de un número
## fijo para que el escalón de dificultad siga contando: con 60-140 de rapidez
## base, la mitad son 30-70 y el centro cae justo en los 54 pedidos. Un bioma
## que ignorase la dificultad sería el único del juego que no se endurece.
const GLOBO_SUBE := 0.54
## Radio del disco de la bola, en fracción del lado del lienzo del target.
##
## Medido sobre el PNG: el disco ocupa 202 px de 512. Sale de ahí y no de la
## escala interna del SVG porque esa ignora el grosor del contorno, y con el
## valor teórico —18,5%— el recorte se come un poco de borde en toda la vuelta.
##
## El mismo radio manda en dos sitios: es el círculo al que se recorta la marca y
## es la `r` de `d = r · sin(phi)`. Tienen que ser el mismo o el número se sale.
const BOLA_RADIO := 0.197
## Vértices del círculo de recorte de la marca.
##
## Veinticuatro: a tamaño de juego una bola mide unos 25 px de ancho, así que
## cada lado del polígono mide tres píxeles y el borde ya no se distingue de una
## circunferencia. Más vértices es más trabajo por bola y por fotograma.
const BOLA_LADOS := 24
## Por debajo de este achatamiento la marca no se dibuja.
##
## Es el canto del disco visto de perfil: no se ve nada, y la matriz que lo
## deforma se vuelve singular —su determinante ES el achatamiento—, así que
## invertirla para calcular las UV daría infinitos.
const BOLA_MARCA_MINIMA := 0.02

## Cuánto frena el tapete, por segundo.
##
## La entrega lo da por fotograma a 60 fps (×0,985); elevado a 60 son los 0,4 que
## van aquí. Por fotograma, el bioma frenaría distinto en un móvil a 30 fps que
## en uno a 120, y sería el único del juego que depende de la tasa de refresco.
const BILLAR_ROZAMIENTO := 0.4
## Por debajo de qué rapidez deja de frenar una bola, en units/s.
##
## Es lo que mantiene el bioma vivo: con solo rozamiento las bolas acabarían
## quietas y esto sería un cuadro. Una bola que frena hasta pararse es más real y
## peor de jugar.
##
## En units y no como fracción de la rapidez del círculo, que es lo que se probó
## primero: la fracción dejaba el suelo por debajo de lo pedido —medido, 28 px/s
## donde tocaban 36— porque la rapidez base del juego es menor que la que supone
## la entrega. Esto no es dificultad, es el mínimo para que la mesa no se congele,
## así que va atado al tamaño del dibujo y no al escalón.
const BILLAR_MINIMA := 14.0
## Cuánto se queda la banda en cada rebote. Uno perfecto se lee como goma.
const BILLAR_REBOTE := 0.88
## Grosor del marco de madera, en units del lienzo de arte.
##
## Sale del SVG entregado, donde las cuatro bandas miden 14. Ojo: la entrega lo
## describe como 8 en dos sitios, pero el dibujo dice 14 y es el dibujo el que
## manda —la regla es que la bola no pise la madera, y la madera está donde está.
const BILLAR_MARCO := 14.0

## Amplitud de la ese, en píxeles. Sutil: se nota, no marea.
const GLOBO_AMPLITUD := Vector2(7.0, 15.0)
## Cada cuánto completa un vaivén, en segundos.
const GLOBO_PERIODO := Vector2(2.7, 4.1)

## La política de giro de cada forma, EN EL ORDEN DEL ENUM Forma.
##
## Si se añade una forma y no se añade aquí, el juego revienta al entrar a su
## bioma: se indexa con el valor del enum. Es el mismo contrato que NOMBRES_MOV
## en main.gd, y ya se rompió una vez por olvidarlo.
const GIRO_DE_FORMA := [
	Giro.FIJO,     ## circulo
	Giro.DERIVA,   ## copo: lo voltea el aire, no el rumbo
	Giro.CABECEO,  ## abeja: de perfil, no puede ir boca arriba
	Giro.NORIA,    ## hoja: cae dando vueltas
	Giro.FIJO,     ## bola
	Giro.RUMBO,    ## dron: visto desde arriba, puede girar entero
	Giro.FIJO,     ## chispa
	Giro.FIJO,     ## chip
	Giro.CABECEO,  ## avion: de perfil, y planeando conviene que cabecee
	Giro.RUMBO,    ## misil: apunta a donde va, es lo suyo
	Giro.CABECEO,  ## pez: de perfil, jamás del revés
	Giro.FIJO,     ## estrella
	Giro.FIJO,     ## llama: el fuego sube, dé igual hacia dónde vaya
	Giro.FIJO,     ## burbuja
	Giro.BALANCEO, ## globo: se mece sobre el nudo y el cordel barre una ese
	Giro.FIJO,     ## meteoro: una roca no tiene morro; la dirección la da su estela
	Giro.FIJO,     ## robot: uno ladeado se lee como averiado
	Giro.RUMBO,    ## hormiga: vista desde arriba
	Giro.FIJO,     ## fugaz: un destello no tiene "delante"
]

## Cuánto vale este objetivo respecto a uno normal.
##
## Vive en el objetivo y no en el bioma a propósito: es el enganche para todo lo
## que venga después —objetivos que valen más, power-ups, misiones que piden
## cazar algo concreto—. Un multiplicador que solo supiera de estrellas fugaces
## habría que reescribirlo entero al añadir el segundo caso.
var valor_mult: float = 1.0
## Cuánto más grande es la detonación que provoca al reventar.
##
## No es solo estética: la onda es el radio de contagio, así que un objetivo con
## onda mayor encadena más lejos. Es la primera cosa del juego que se parece a un
## power-up.
var onda_mult: float = 1.0

## Rastro de posiciones recientes, en coordenadas del mundo.
##
## Se guarda el mundo y no lo local porque el nodo gira: al dibujar se convierte
## cada punto con to_local(), que ya descuenta posición, giro y escala. Guardando
## desplazamientos locales habría que rotarlos a mano en cada fotograma y la
## estela se retorcería con el objetivo en vez de quedarse quieta detrás.
var _estela: PackedVector2Array = PackedVector2Array()

## Color y tamaño los fija el bioma al nacer el círculo, no una constante: es
## lo que permite que la ventisca se vea de nieve y el panal de miel sin tocar
## una línea de la lógica.
var color: Color = Color("e8e8f0")
var forma: Forma = Forma.CIRCULO
## Número de la bola, del 1 al 15. Cero en el resto de biomas.
var numero: int = 0

## Colores de globo. Se elige uno por globo con el mismo campo que numera las
## bolas de billar: dos biomas que necesitan variedad por instancia, un solo
## mecanismo.
const COLOR_GLOBO := [
	Color("ff5f7e"), Color("ffd23f"), Color("5fd1ff"), Color("8affa0"),
	Color("c98bff"), Color("ff9d54"), Color("ff7ee0"), Color("7ee8d0"),
]

## Colores de billar. Ninguno es el negro real de la bola 8: sobre un tapete
## oscuro sería invisible, y la legibilidad manda sobre el realismo.
const COLOR_BOLA := [
	Color("ffd23f"), Color("5b9bff"), Color("ff6060"), Color("c184ff"),
	Color("ff9d54"), Color("4fe39a"), Color("dd8259"), Color("b3bacb"),
]

@export var radius: float = 9.0

var modo: Movimiento = Movimiento.REBOTE
var velocity: Vector2 = Vector2.ZERO
## Rapidez de referencia. Los modos que reorientan el vector (enjambre, huida)
## la usan para no acelerar ni frenar sin querer al cambiar de dirección.
var base_speed: float = 100.0

## Entrada en escena, de 0 a 1.
##
## El círculo se dibuja pequeño y crece hasta su tamaño: se lee como que venía
## de lejos y se acerca. Es puro telégrafo — se puede tocar y contagiar desde el
## primer frame, con su radio completo. Un círculo que parece más pequeño de lo
## que se puede tocar es generoso; al revés sería una trampa.
var _entrada: float = 1.0
## Cuánto más grandes se ven los targets de lo que miden para el juego.
##
## Dos subidas del 25% acumuladas. Ojo con seguir tirando de aquí: cuanto más se
## separa el dibujo de la lógica, más ancha es la franja en la que una onda
## parece rozar un target y no lo contagia. A 1.56 esa franja es de 4 a 6 px
## según el bioma; el día que se note como injusto, la solución es subir el
## radio de lógica y recalibrar, no seguir agrandando el dibujo.
## A qué tamaño se dibuja el objetivo, en píxeles de radio.
##
## Lo fija Main a partir del radio de toque, y es **el mismo en los diecisiete
## biomas**. No sale de `radius` ni de la escala del bioma: si saliera de ahí,
## cada bioma dibujaría de un tamaño distinto y el jugador tendría que reaprender
## dónde acaba un objetivo en cada nivel.
##
## Se dibuja algo MÁS PEQUEÑO de lo que se puede tocar, y esa holgura es margen a
## favor del jugador: tocas un poco al lado del dibujo y aún cuenta. Nunca al
## revés — un objetivo que se ve más grande de lo que responde se siente roto.
##
## La variedad de bioma no se pierde: sigue en la silueta, en la paleta, en el
## movimiento y en `radius`, que es el que gobierna los contagios.
var radio_dibujo: float = 24.0
## Cuánto dura una vuelta completa de una forma animada, en segundos.
const CICLO_TARGET := 1.1
## Multiplicador propio del bioma. YA NO AFECTA AL DIBUJO.
##
## Se quedó sin trabajo cuando el tamaño de dibujo pasó a salir del radio de
## toque, igual para todos. Se conserva por si algún día hace falta una excepción,
## pero hoy no lo lee nadie.
##
## Lo de abajo es la explicación de cuando sí se usaba.
##
##
## Sale de la paleta y solo afecta al DIBUJO. `radius` no se toca: gobierna los
## contagios y el toque, así que subirlo cambiaría el balance del bioma por un
## motivo estético.
##
## Ahora mismo NINGÚN bioma lo usa, y es lo correcto: existió mientras el dibujo
## salía a menos de la mitad del radio de toque y había que agrandar unos cuantos
## a mano. Con el dibujo derivado del radio de toque, el sitio para cambiar el
## tamaño de todos es `dibujo_del_toque` en main.gd.
var escala: float = 1.0
const ENTRADA_DUR := 0.55
const ENTRADA_MIN := 0.28

var _fase: float = 0.0
## La ese del globo: columna sobre la que oscila, rapidez, amplitud y periodo.
##
## Se sortean en el PRIMER movimiento y no al nacer porque quien prepara el
## círculo corre antes que _ready, y entonces la semilla todavía no existe. Ya
## pasó con los misiles: el primer fotograma los teletransportaba.
## Ángulo rodado por la bola, en radianes, y dónde estaba en el fotograma
## anterior para poder medir cuánto ha rodado.
##
## Se acopla a la DISTANCIA y no al tiempo: es lo que hace que se lea como rodar.
## Si la bola frena, el giro frena con ella; si se para, el número se queda
## quieto donde estaba. Con un giro por tiempo la bola parece un motor.
var _bola_phi := 0.0
var _bola_antes := Vector2.ZERO
var _bola_listo := false
var _globo_listo := false
var _globo_x := 0.0
var _globo_sube := 0.0
var _globo_amplitud := 0.0
var _globo_periodo := 1.0
var _globo_fase := 0.0
## Cuánto está inclinado ahora mismo un globo. Lo pone _orientar y lo usa _draw
## para girar el dibujo sobre el nudo.
var _balanceo := 0.0
## Desfase propio, para que dos círculos con el mismo modo no se muevan
## sincronizados como un coro.
## Las cuatro maneras de caer de un misil de Asedio. Se sortea UNA al nacer y se
## conserva toda la vida: un misil que el jugador venía siguiendo no cambia de
## carácter a mitad de caída.
## Tres, no cuatro. Hubo un cuarto —remolino, un bucle a mitad de caída— y se
## retiró: para que el bucle se lea como un círculo, la caída durante la vuelta
## tiene que ser pequeña frente a su diámetro, y con una caída de 70 a 140 px/s
## eso pedía o un círculo enorme o frenar tanto el misil que parecía colgado.
## Está en el historial por si algún día la caída se ralentiza y vuelve a caber.
enum Misil { RECTA, ESE, QUIEBRO }

## La trayectoria de este misil y sus parámetros, todos sorteados al nacer.
var misil_tray: Misil = Misil.RECTA
var misil_deriva: float = 0.0
var misil_amplitud: float = 0.0
var misil_periodo: float = 2.0
var misil_quiebro: float = 1.0
var misil_tangente: float = 0.0
## La vertical alrededor de la que serpentea, y dónde nació.
var _misil_x: float = 0.0
var _misil_y0: float = 0.0
## El desplazamiento que tenía en su primer fotograma, que se resta siempre.
##
## Sin esto el misil SALTA de lado nada más nacer: la ese arranca en sin(semilla),
## que no es cero, así que la primera x calculada estaba hasta 78 px a un lado de
## donde había nacido. Medido antes de arreglarlo: picos de 3690 px/s de
## velocidad lateral, que no es velocidad sino un teletransporte.
##
## Y se ancla al MOVERSE, no al sortear la trayectoria. Main prepara el misil
## antes de meterlo en el árbol, así que en ese momento _semilla todavía vale
## cero —la sortea _ready— y el desfase salía calculado con una semilla que no
## era la suya. Anclando en el primer paso, la cuenta es la buena venga de donde
## venga el misil.
var _misil_dx0: float = 0.0
var _misil_anclado := false
## La vertical que cae sola. La posición es esta más el desplazamiento, no una
## integración: así el bucle del remolino puede subir sin deshacer la caída.
var _misil_y: float = 0.0

var _semilla: float = 0.0
## Lo que gira por segundo una forma con DERIVA. Propio de cada instancia.
var _deriva: float = 0.0

## El anillo de la estela del meteoro, muestreado POR DISTANCIA.
##
## Por distancia y no por tiempo: por tiempo la estela cambiaría de largo con la
## rapidez del meteoro, y dos rocas a distinta velocidad llevarían colas
## distintas sin motivo. Por distancia mide siempre lo mismo.
var _anillo: PackedVector2Array = PackedVector2Array()
## Cuánto mide la estela, en radios de dibujo. Se sortea al nacer.
##
## Con un largo único, un campo de ocho meteoros se lee como un peine.
var _estela_largo: float = 3.5
var _giro: float = 0.0
## Cuánto vira por segundo el planeo, hasta el próximo cambio de rumbo.
var _vira: float = 0.0
## Segundos que le quedan a la patrulla parada antes de arrancar de nuevo.
var _pausa: float = 0.0


func _ready() -> void:
	_semilla = randf() * TAU
	# Se sortea UNA vez, al nacer, y no en cada fotograma: un giro que cambiara
	# de ritmo se vería como un tirón, no como deriva. El signo decide hacia
	# dónde voltea, que también es cosa del aire y no del copo.
	_deriva = randf_range(DERIVA_MIN, DERIVA_MAX) * (1.0 if randf() < 0.5 else -1.0)
	_giro = randf_range(0.2, 0.6)


func _draw() -> void:
	# Ojo: _draw() dibuja en espacio LOCAL y lo que cambia es la transform del
	# nodo, así que solo hace falta queue_redraw() mientras el círculo crece.
	# El radio de DIBUJO no es el de lógica.
	#
	# `radius` gobierna los contagios, así que agrandarlo cambiaría el balance
	# del juego entero por un motivo puramente estético. La escala se aplica
	# solo aquí: los targets se ven un 25% más grandes y no encadenan ni un
	# píxel más lejos. El radio de toque es aparte y tampoco se toca.
	var r := radio_dibujo * lerpf(ENTRADA_MIN, 1.0, _entrada)
	
	# La estela va antes del asset y se dibuja pase lo que pase.
	#
	# Sale de la trayectoria real, así que NO se puede meter en una imagen fija:
	# si dependiera del dibujo por código, entregar un `fugaz.png` la borraría sin
	# avisar y la curvatura dejaría de verse. Lo que un asset sustituye es la
	# cabeza; el rastro lo pone siempre el juego.
	if not _estela.is_empty():
		_dibujar_estela(r)

	# Una bola de billar se dibuja en tres capas para poder rodar. Manda sobre
	# el sprite entero, que sigue existiendo para donde la bola esté quieta.
	if forma == Forma.BOLA and _dibujar_bola(r):
		return

	# Si hay un asset para esta forma, manda el asset. El dibujo de
	# abajo pasa a ser el respaldo: cubre las formas sin fichero y
	# mantiene el juego jugable si un asset falta o viene roto.
	var asset := Arte.target_tira(forma, numero)
	var tex: Texture2D = asset["tex"]
	if tex != null:
		var lado := r * Arte.LIENZO_EN_RADIOS
		var destino := Rect2(Vector2(-lado, -lado) * 0.5, Vector2(lado, lado))
		# El balanceo no puede ir en `rotation` del nodo: eso gira sobre la
		# posición, que es el centro del sprite. Aquí se pone el eje donde está
		# el nudo y se dibuja descontándolo, que es girar alrededor de un punto
		# cualquiera. No hace falta deshacerlo: Godot reinicia la transformación
		# del lienzo en cada _draw, y las dos ramas de abajo devuelven el control
		# inmediatamente después de dibujar.
		if _balanceo != 0.0:
			var pivote := Vector2(0.0, lado * BALANCEO_PIVOTE)
			draw_set_transform(pivote, _balanceo, Vector2.ONE)
			destino.position -= pivote
		var n: int = asset["fotogramas"]
		# Sin tinte: el color de la paleta manda sobre las formas de
		# código, pero un asset lo pinta quien lo dibuja.
		if n <= 1:
			draw_texture_rect(tex, destino, false)
			return
		# En bucle, y con el desfase propio de cada círculo: sin él, todo el
		# banco batiría la cola a la vez y se vería la cuadrícula.
		var t := fposmod((_fase + _semilla) / CICLO_TARGET, 1.0)
		var i := clampi(int(t * float(n)), 0, n - 1)
		var ancho := tex.get_width() / n
		draw_texture_rect_region(tex, destino,
				Rect2(float(i * ancho), 0.0, float(ancho), float(tex.get_height())))
		return
	
	match forma:
		Forma.COPO: _copo(r)
		Forma.ABEJA: _abeja(r)
		Forma.HOJA: _hoja(r)
		Forma.BOLA: _bola(r)
		Forma.DRON: _dron(r)
		Forma.CHISPA: _chispa(r)
		Forma.CHIP: _chip(r)
		Forma.AVION: _avion(r)
		Forma.MISIL: _misil(r)
		Forma.PEZ: _pez(r)
		Forma.ESTRELLA: _estrella(r)
		Forma.LLAMA: _llama(r)
		Forma.BURBUJA: _burbuja(r)
		Forma.GLOBO: _globo(r)
		Forma.METEORO: _meteoro(r)
		Forma.ROBOT: _robot(r)
		Forma.HORMIGA: _hormiga(r)
		Forma.FUGAZ: _fugaz(r)
		_: draw_circle(Vector2.ZERO, r, color)


## Seis brazos con ramitas. A este tamaño el detalle real es imposible, pero la
## silueta radial se lee como copo al instante.
func _copo(r: float) -> void:
	var grueso := maxf(1.4, r * 0.2)
	var fino := maxf(1.0, r * 0.13)
	for i in 6:
		var dir := Vector2.from_angle(TAU * float(i) / 6.0)
		draw_line(-dir * r * 0.12, dir * r, color, grueso, true)
		var nudo := dir * r * 0.58
		draw_line(nudo, nudo + Vector2.from_angle(dir.angle() + 0.95) * r * 0.36, color, fino, true)
		draw_line(nudo, nudo + Vector2.from_angle(dir.angle() - 0.95) * r * 0.36, color, fino, true)


## Abeja: cuerpo ovalado con franjas, dos alas y aguijón. Mira hacia donde vuela.
##
## Las alas van DETRÁS del cuerpo y translúcidas, batiendo con la fase propia del
## círculo: es lo que la separa de una pelota a rayas. El aguijón asoma por la
## cola y remata la silueta.
func _abeja(r: float) -> void:
	var bat := 0.55 + 0.45 * absf(sin(_fase * 26.0 + _semilla))
	var ala := Color(1.0, 1.0, 1.0, 0.42)
	# Ala trasera y delantera, abiertas hacia arriba y hacia atrás.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-r * 0.1, -r * 0.25),
		Vector2(-r * 1.0, -r * (0.35 + 0.75 * bat)),
		Vector2(-r * 0.15, -r * 0.9)]), ala)
	draw_colored_polygon(PackedVector2Array([
		Vector2(r * 0.15, -r * 0.25),
		Vector2(r * 0.75, -r * (0.3 + 0.7 * bat)),
		Vector2(-r * 0.05, -r * 0.85)]), ala)

	# Aguijón: triangulito en la cola.
	var oscuro := Color(0.09, 0.06, 0.02, 0.95)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-r * 1.45, 0.0),
		Vector2(-r * 0.95, r * 0.16),
		Vector2(-r * 0.95, -r * 0.16)]), oscuro)

	# Cuerpo ovalado apuntando a +x.
	var cuerpo := PackedVector2Array()
	var n := 14
	for i in n:
		var a := TAU * float(i) / float(n)
		cuerpo.append(Vector2(cos(a) * r * 1.05, sin(a) * r * 0.72))
	draw_colored_polygon(cuerpo, color)

	# Franjas perpendiculares al vuelo, más cortas hacia la cola.
	for k in 3:
		var x := -r * 0.55 + float(k) * r * 0.5
		var alto := r * 0.66 * sqrt(maxf(0.0, 1.0 - pow(x / (r * 1.05), 2.0)))
		draw_line(Vector2(x, -alto), Vector2(x, alto), oscuro, maxf(1.2, r * 0.24))

	# Cabeza.
	draw_circle(Vector2(r * 0.85, 0.0), r * 0.34, oscuro)


## Óvalo apuntado con nervadura. La forma sale de un seno, así que es simétrica
## y puntiaguda en los dos extremos sin tener que listar vértices a mano.
func _hoja(r: float) -> void:
	var pts := PackedVector2Array()
	var n := 9
	for i in n + 1:
		var t := float(i) / float(n)
		pts.append(Vector2(r * 0.64 * sin(PI * t), lerpf(-r, r, t)))
	for i in range(n, -1, -1):
		var t := float(i) / float(n)
		pts.append(Vector2(-r * 0.64 * sin(PI * t), lerpf(-r, r, t)))
	draw_colored_polygon(pts, color)
	draw_line(Vector2(0, -r * 0.9), Vector2(0, r * 0.9), Color(0, 0, 0, 0.3), maxf(1.0, r * 0.15), true)


## Bola de billar: lisa o a rayas, con su número y su brillo.
##
## El círculo blanco del centro no es decoración: es lo que garantiza que la
## bola se vea sobre el tapete pase lo que pase con el color del cuerpo. Sin él,
## las oscuras se perderían en el paño verde.
func _bola(r: float) -> void:
	if numero <= 0:
		draw_circle(Vector2.ZERO, r, color)
		draw_circle(Vector2(-r * 0.32, -r * 0.32), r * 0.26, Color(1.0, 1.0, 1.0, 0.5))
		return

	var tinte: Color = COLOR_BOLA[(numero - 1) % COLOR_BOLA.size()]
	var rayada := numero > 8

	if rayada:
		# A rayas: cuerpo claro con una franja de color por el ecuador.
		draw_circle(Vector2.ZERO, r, Color("f2ede0"))
		draw_colored_polygon(_franja(r, r * 0.62), tinte)
	else:
		draw_circle(Vector2.ZERO, r, tinte)

	# Disco blanco y número encima.
	draw_circle(Vector2.ZERO, r * 0.56, Color("fbf7ee"))
	var fuente := ThemeDB.fallback_font
	if fuente != null:
		var tam := int(maxf(8.0, r * 1.05))
		draw_string(fuente, Vector2(-r, r * 0.36), str(numero),
				HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, tam, Color(0.08, 0.08, 0.1))

	draw_circle(Vector2(-r * 0.4, -r * 0.42), r * 0.2, Color(1.0, 1.0, 1.0, 0.45))


## Franja horizontal recortada al círculo, para las bolas a rayas. Se calcula
## con la ecuación del círculo en vez de dibujar un rectángulo, que se saldría
## por los lados.
func _franja(r: float, alto: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var n := 8
	for i in n + 1:
		var y := lerpf(-alto, alto, float(i) / float(n))
		pts.append(Vector2(sqrt(maxf(0.0, r * r - y * y)), y))
	for i in range(n, -1, -1):
		var y := lerpf(-alto, alto, float(i) / float(n))
		pts.append(Vector2(-sqrt(maxf(0.0, r * r - y * y)), y))
	return pts


## Triángulo orientado al rumbo. Mirar hacia donde va delata su trayectoria
## antes de moverse, que es lo que hace legible un bioma que huye.
func _dron(r: float) -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(r * 1.15, 0.0), Vector2(-r * 0.7, r * 0.72), Vector2(-r * 0.7, -r * 0.72)]), color)


## Pavesa: núcleo pequeño y halo. El halo hace que parezca que emite luz sin
## necesidad de ningún efecto.
func _chispa(r: float) -> void:
	draw_circle(Vector2.ZERO, r * 1.4, Color(color, 0.18))
	draw_circle(Vector2.ZERO, r * 0.72, color)


## Rombo con una traza. Geometría dura, que es lo que distingue lo fabricado de
## lo orgánico de un vistazo.
func _chip(r: float) -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, -r), Vector2(r, 0.0), Vector2(0.0, r), Vector2(-r, 0.0)]), color)
	draw_line(Vector2(-r * 0.55, 0.0), Vector2(r * 0.55, 0.0), Color(0, 0, 0, 0.35), maxf(1.0, r * 0.18))


## Arranca la entrada en escena. Los del reparto inicial no la usan: ver el
## campo materializarse al empezar la partida sería una espera muerta.
func entrar_creciendo() -> void:
	_entrada = 0.0
	queue_redraw()


## Todo movimiento va multiplicado por delta. Si no, el juego corre a distinta
## velocidad en cada dispositivo según sus FPS.
##
## El área NO es la pantalla entera: empieza por debajo de la barra de tiempo.
## En los biomas que van de arriba abajo se formaban cadenas en la franja del
## HUD, donde el jugador no puede ver lo que pasa aunque esté pasando.
func mover(delta: float, area: Rect2) -> void:
	_fase += delta
	if _entrada < 1.0:
		_entrada = minf(1.0, _entrada + delta / ENTRADA_DUR)
		queue_redraw()
	elif Arte.target_tira(forma, numero)["fotogramas"] > 1:
		# Una forma con tira se redibuja siempre: la animación es suya, no del
		# movimiento, y si no se pide redibujado se queda en el primer cuadro.
		queue_redraw()
	elif forma in [Forma.ABEJA, Forma.PEZ, Forma.ESTRELLA, Forma.LLAMA,
			Forma.GLOBO, Forma.HORMIGA, Forma.ROBOT]:
		# Estas tres se mueven por dentro —alas, cola, titileo— así que hay que
		# redibujarlas aunque el nodo no cambie de sitio.
		queue_redraw()

	# Las formas con orientación la actualizan aquí: el dron mira hacia donde
	# va, la hoja voltea despacio como si cayera.
	_orientar(delta)
	# Un objetivo GUIADO recibe la posición desde fuera: el hormiguero la calcula
	# sobre el grafo del nido y la posa él. Aquí solo se anima y se orienta, que
	# es lo que no sabe hacer quien lo guía.
	if guiado:
		return
	match modo:
		Movimiento.ABEJA:
			_mover_abeja(delta, area)
		Movimiento.NIEVE:
			_mover_nieve(delta, area)
		Movimiento.CORRIENTE:
			_mover_corriente(delta, area)
		Movimiento.BRASA:
			_mover_brasa(delta, area)
		Movimiento.CIRCUITO:
			_mover_circuito(delta, area)
		Movimiento.PLANEO:
			_mover_planeo(delta, area)
		Movimiento.MISIL:
			_mover_misil(delta, area)
		Movimiento.BOMBARDEO:
			_mover_bombardeo(delta, area)
		Movimiento.METEORO:
			_mover_meteoro(delta, area)
			_muestrear_estela()
		Movimiento.PATRULLA:
			_mover_patrulla(delta, area)
		Movimiento.HORMIGA:
			_mover_hormiga(delta, area)
		Movimiento.FUGAZ:
			_mover_fugaz(delta, area)
		Movimiento.GLOBO:
			_mover_globo(delta)
		Movimiento.BILLAR:
			_mover_billar(delta, area)
		_:
			# REBOTE, CHOQUE, ENJAMBRE y HUIDA comparten integración recta; lo
			# que los distingue lo aplica Main antes de llamar aquí.
			position += velocity * delta
			_rebotar(area)


## Estrella fugaz: recta con una curvatura leve, y no rebota.
##
## La curvatura es lo que la separa de una bala. Una fugaz de verdad no traza una
## recta perfecta: la trayectoria se arquea muy poco, lo justo para que el ojo la
## lea como algo que cae y no como algo disparado.
##
## No rebota y no se envuelve: entra, cruza y se va. Main la retira cuando sale.
func _mover_fugaz(delta: float, area: Rect2) -> void:
	velocity = velocity.rotated(curva_fugaz * delta)
	position += velocity * delta
	_estela.append(global_position)
	while _estela.size() > largo_estela:
		_estela.remove_at(0)
	queue_redraw()


## Meteoro: rumbo fijo, acelerando poco a poco. No rebota nunca.
##
## Rebotar sería lo peor que podría hacer: el bioma entero se sostiene sobre la
## promesa de que todos van al planeta. Un meteoro que rebota en un borde y se
## va rompe la lectura de la amenaza.
func _mover_meteoro(delta: float, area: Rect2) -> void:
	velocity += velocity.normalized() * base_speed * 0.18 * delta
	position += velocity * delta


## Patrulla: tramos rectos, parada en seco y salida en otra dirección.
##
## La parada es la pieza importante. Sin ella, un robot que cambia de rumbo cada
## segundo se caza por suerte y no por puntería; ese cuarto de segundo quieto es
## la ventana que convierte el bioma en una cacería y no en una lotería.
func _mover_patrulla(delta: float, area: Rect2) -> void:
	if _pausa > 0.0:
		_pausa -= delta
		return
	_vira -= delta
	if _vira <= 0.0:
		_vira = randf_range(0.75, 1.7)
		_pausa = 0.26
		velocity = Vector2.from_angle(randf() * TAU) * base_speed * randf_range(0.8, 1.25)
		return
	position += velocity * delta
	_rebotar(area)


## Hormiga: avanza sin parar y el rumbo gira despacio.
##
## Dos ondas de periodo distinto, no una: con una sola el recorrido se cierra en
## círculos y se nota el truco enseguida.
func _mover_hormiga(delta: float, area: Rect2) -> void:
	var giro := (sin(_fase * 1.7 + _semilla) * 0.9
			+ sin(_fase * 4.3 + _semilla * 2.1) * 0.4) * delta
	velocity = velocity.rotated(giro)
	position += velocity * delta
	_rebotar(area)


## Aplica la política de giro de la forma.
##
## El espejo se hace con `scale.x`, no rotando 180 grados. Girado, un pez nada
## panza arriba; reflejado, nada hacia el otro lado, que es lo que hace de
## verdad. La diferencia no se ve en una hoja de contactos porque ahí está
## quieto, y por eso hay que decidirla aquí y no al dibujar.
func _orientar(delta: float) -> void:
	var politica: int = GIRO_DE_FORMA[forma] if forma < GIRO_DE_FORMA.size() else Giro.FIJO
	if politica == Giro.NORIA:
		rotation += delta * NORIA_VUELTAS
		return
	if politica == Giro.DERIVA:
		# Antes del corte por velocidad: un copo casi parado sigue volteando, y
		# es justo ahí donde más se nota que el aire lo mueve.
		rotation += delta * _deriva
		queue_redraw()
		return
	if politica == Giro.BALANCEO:
		# Acoplado a la MISMA fase de la ese, no a un reloj propio. Es lo que
		# hace que el globo se incline hacia dentro de la curva en vez de
		# mecerse por su cuenta, y lo que el cordel acaba dibujando por debajo.
		_balanceo = -BALANCEO_MAX * sin(_globo_fase)
		queue_redraw()
		return
	if politica == Giro.FIJO or velocity.length_squared() < 1.0:
		return

	if politica == Giro.RUMBO:
		rotation = velocity.angle()
		return

	# ESPEJO y CABECEO comparten el reflejo; solo cambia si además se inclina.
	var a_la_izquierda := velocity.x < 0.0
	scale.x = -1.0 if a_la_izquierda else 1.0
	if politica == Giro.ESPEJO:
		rotation = 0.0
		return

	var inclina := clampf(velocity.y / maxf(1.0, base_speed), -1.0, 1.0) * INCLINACION_MAX
	# Con el dibujo reflejado, el mismo ángulo se ve al revés: hay que negarlo
	# para que el morro siga apuntando hacia donde de verdad baja.
	rotation = -inclina if a_la_izquierda else inclina


## Tirones y pausas: la abeja mantiene un rumbo un instante, lo cambia de golpe
## y varía mucho de rapidez. Lo que la hace difícil de leer no es la velocidad
## media sino lo poco que dura cada tramo recto.
func _mover_abeja(delta: float, area: Rect2) -> void:
	_giro -= delta
	if _giro <= 0.0:
		_giro = randf_range(0.15, 0.5)
		var rumbo := velocity.angle() + randf_range(-1.2, 1.2)
		velocity = Vector2.from_angle(rumbo) * base_speed * randf_range(0.35, 1.7)
	position += velocity * delta
	_rebotar(area)


## Caída lenta con vaivén. No rebota: sale por abajo y vuelve a entrar por
## arriba en otra columna, así el campo se renueva sin saltos.
func _mover_nieve(delta: float, area: Rect2) -> void:
	var vaiven := sin(_fase * 1.7 + _semilla) * base_speed * 0.75
	position += Vector2(vaiven, base_speed * 0.55) * delta

	if position.y > area.end.y + radius:
		position = Vector2(area.position.x + randf() * area.size.x,
				area.position.y - radius)
	if position.x < area.position.x - radius:
		position.x = area.end.x + radius
	elif position.x > area.end.x + radius:
		position.x = area.position.x - radius


## Río: todos arrastrados en la misma dirección, con una ondulación suave.
## Salen por un lado y reaparecen por el otro.
##
## El sentido lo fija quien crea el círculo, no el rumbo hacia el centro: antes
## los que entraban por la derecha iban hacia la izquierda y los de la izquierda
## hacia la derecha, así que el "río" corría en dos sentidos a la vez y la pista
## del nivel mentía.
func _mover_corriente(delta: float, area: Rect2) -> void:
	var onda := cos(_fase * 1.1 + _semilla) * base_speed * 0.35
	position += Vector2(velocity.x, onda) * delta

	if position.x < area.position.x - radius:
		position.x = area.end.x + radius
	elif position.x > area.end.x + radius:
		position.x = area.position.x - radius
	position.y = clampf(position.y, area.position.y + radius, area.end.y - radius)


## Avión de papel: delta con muesca trasera y pliegue central. La muesca es lo
## que lo separa de un triángulo cualquiera y lo hace leer como papel doblado.
func _avion(r: float) -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(r * 1.25, 0.0),
		Vector2(-r * 0.85, r * 0.8),
		Vector2(-r * 0.3, 0.0),
		Vector2(-r * 0.85, -r * 0.8)]), color)
	draw_line(Vector2(-r * 0.3, 0.0), Vector2(r * 1.2, 0.0),
			Color(0, 0, 0, 0.25), maxf(1.0, r * 0.14), true)


## Misil: cuerpo alargado, punta y aletas. Lo alargado ya dice que va rápido,
## incluso quieto.
func _misil(r: float) -> void:
	# Un pelo más pequeño que el radio nominal. Se dibujó cuando estaba huérfano
	# y salía más largo y más plano que la bala a la que sustituye en el asedio,
	# lo bastante para desentonar con el resto del campo.
	#
	# Se corrige aquí y no en el radio de la paleta a propósito: `radius` gobierna
	# los contagios, así que tocarlo cambiaría el balance del bioma por un motivo
	# puramente estético.
	r *= 0.88
	draw_colored_polygon(PackedVector2Array([
		Vector2(r * 1.35, 0.0),
		Vector2(r * 0.45, r * 0.38),
		Vector2(-r * 0.95, r * 0.38),
		Vector2(-r * 0.95, -r * 0.38),
		Vector2(r * 0.45, -r * 0.38)]), color)
	var aleta := Color(color, 0.75)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-r * 0.6, r * 0.35), Vector2(-r * 1.25, r * 0.95),
		Vector2(-r * 0.95, r * 0.35)]), aleta)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-r * 0.6, -r * 0.35), Vector2(-r * 1.25, -r * 0.95),
		Vector2(-r * 0.95, -r * 0.35)]), aleta)


## Pez: cuerpo de almendra y cola en triángulo. Mira hacia donde nada.
##
## La cola es lo que lo hace legible: sin ella, a este tamaño, un cuerpo ovalado
## es indistinguible de un círculo.
func _pez(r: float) -> void:
	var cuerpo := PackedVector2Array()
	var n := 16
	for i in n:
		var a := TAU * float(i) / float(n)
		cuerpo.append(Vector2(cos(a) * r * 1.05, sin(a) * r * 0.6))
	draw_colored_polygon(cuerpo, color)

	# Cola: triangulito detrás, batiendo suave.
	var bat := sin(_fase * 6.0 + _semilla) * 0.3
	draw_colored_polygon(PackedVector2Array([
		Vector2(-r * 0.85, 0.0),
		Vector2(-r * 1.6, r * (0.55 + bat)),
		Vector2(-r * 1.6, -r * (0.55 - bat))]), color)

	# Ojo, del color del fondo del bioma no: negro, que se lee sobre cualquiera.
	draw_circle(Vector2(r * 0.55, -r * 0.12), r * 0.15, Color(0, 0, 0, 0.6))


## Estrella: cuatro puntas y un núcleo. El destello sale de que las puntas sean
## mucho más largas que anchas, no de ningún efecto.
func _estrella(r: float) -> void:
	var brillo := 0.75 + 0.25 * sin(_fase * 2.4 + _semilla)
	var largo := r * 1.5 * brillo
	var ancho := r * 0.3
	draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, -largo), Vector2(ancho, 0.0),
		Vector2(0.0, largo), Vector2(-ancho, 0.0)]), color)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-largo, 0.0), Vector2(0.0, ancho),
		Vector2(largo, 0.0), Vector2(0.0, -ancho)]), color)
	draw_circle(Vector2.ZERO, r * 0.42, color)


## Llama: gota apuntada hacia arriba con núcleo claro, ondeando.
##
## Siempre apunta arriba pase lo que pase con el rumbo, porque una llama que se
## tumbara al moverse dejaría de leerse como fuego. El ondeo va con la fase
## propia, así que dos llamas vecinas nunca hacen lo mismo.
func _llama(r: float) -> void:
	var onda := sin(_fase * 7.0 + _semilla) * 0.22
	var pts := PackedVector2Array()
	var n := 14
	for i in n + 1:
		var t := float(i) / float(n)
		# Perfil de gota: ancho abajo, puntiagudo arriba, con vaivén lateral.
		var ancho := r * 0.85 * pow(sin(PI * t), 0.75)
		var y := lerpf(r * 0.9, -r * 1.5, t)
		pts.append(Vector2(ancho + onda * r * t * 1.6, y))
	for i in range(n, -1, -1):
		var t := float(i) / float(n)
		var ancho := r * 0.85 * pow(sin(PI * t), 0.75)
		var y := lerpf(r * 0.9, -r * 1.5, t)
		pts.append(Vector2(-ancho + onda * r * t * 1.6, y))
	draw_colored_polygon(pts, Color(color, 0.55))

	# Núcleo, más claro y más corto: es lo que da la lectura de brasa viva.
	var nucleo := PackedVector2Array()
	for i in n + 1:
		var t := float(i) / float(n)
		var ancho := r * 0.42 * pow(sin(PI * t), 0.75)
		var y := lerpf(r * 0.55, -r * 0.75, t)
		nucleo.append(Vector2(ancho + onda * r * t, y))
	for i in range(n, -1, -1):
		var t := float(i) / float(n)
		var ancho := r * 0.42 * pow(sin(PI * t), 0.75)
		var y := lerpf(r * 0.55, -r * 0.75, t)
		nucleo.append(Vector2(-ancho + onda * r * t, y))
	draw_colored_polygon(nucleo, Color(1.0, 1.0, 0.85, 0.9))


## Burbuja de jabón: casi transparente, con reflejo y una película iridiscente.
##
## Es la forma más difícil de este juego: una burbuja es sobre todo AUSENCIA de
## color, y aquí el target tiene que verse sí o sí. La solución es el anillo del
## borde, que va a alfa alta y carga toda la legibilidad; el interior puede
## permitirse ser casi invisible porque el contorno ya está resuelto.
func _burbuja(r: float) -> void:
	draw_circle(Vector2.ZERO, r, Color(color, 0.16))
	draw_arc(Vector2.ZERO, r * 0.94, 0.0, TAU, 22, Color(color, 0.95), 2.2, true)
	# Reflejo arriba a la izquierda y un punto de luz: sin ellos parece un aro.
	draw_arc(Vector2.ZERO, r * 0.66, PI * 0.85, PI * 1.45, 10,
			Color(1, 1, 1, 0.55), 2.0, true)
	draw_circle(Vector2(-r * 0.34, -r * 0.36), r * 0.14, Color(1, 1, 1, 0.75))
	# Tornasol: un arco cálido abajo a la derecha, que es lo que la separa de
	# una pompa de cristal.
	draw_arc(Vector2.ZERO, r * 0.8, PI * 0.05, PI * 0.45, 8,
			Color(1.0, 0.75, 0.95, 0.5), 2.0, true)


## Globo: cuerpo ovalado, nudo y cordel ondulado.
##
## El cordel es lo que lo convierte en globo y no en un huevo: es la única parte
## que se sale de la silueta, y por eso se dibuja en color claro aunque el globo
## sea oscuro.
func _globo(r: float) -> void:
	var tinte: Color = color
	if numero > 0:
		tinte = COLOR_GLOBO[(numero - 1) % COLOR_GLOBO.size()]

	# Cordel: ondea con la fase propia, así que dos globos nunca coinciden.
	var pts := PackedVector2Array()
	for i in 9:
		var t := float(i) / 8.0
		pts.append(Vector2(sin(t * 3.4 + _fase * 1.6 + _semilla) * r * 0.42,
				r * 1.15 + t * r * 1.5))
	draw_polyline(pts, Color(1, 1, 1, 0.45), 1.6, true)

	# Nudo.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-r * 0.2, r * 1.0), Vector2(r * 0.2, r * 1.0),
		Vector2(0.0, r * 1.28)]), tinte)

	# Cuerpo ovalado, más alto que ancho.
	var cuerpo := PackedVector2Array()
	var n := 18
	for i in n:
		var a := TAU * float(i) / float(n)
		cuerpo.append(Vector2(cos(a) * r * 0.82, sin(a) * r * 1.0 - r * 0.05))
	draw_colored_polygon(cuerpo, tinte)

	# Brillo, que es lo que le da volumen de goma.
	draw_circle(Vector2(-r * 0.3, -r * 0.38), r * 0.2, Color(1, 1, 1, 0.5))


## Meteoro: roca irregular con la estela ardiendo detrás.
##
## Va orientado, así que en local el rumbo es +X y la estela cae hacia -X. Ese
## detalle es el que lo separa de una piedra flotando: la estela dice de dónde
## viene y, sobre todo, hacia dónde va, que es la información que el jugador
## necesita cuando hay quince cayendo a la vez.
func _meteoro(r: float) -> void:
	# Dos capas de estela: una ancha y tenue, otra estrecha y viva. Con una
	# sola no hay sensación de calor, solo una mancha.
	draw_colored_polygon(PackedVector2Array([
			Vector2(-r * 0.5, -r * 0.62), Vector2(-r * 3.2, 0.0),
			Vector2(-r * 0.5, r * 0.62)]), Color(color, 0.22))
	draw_colored_polygon(PackedVector2Array([
			Vector2(-r * 0.5, -r * 0.3), Vector2(-r * 2.0, 0.0),
			Vector2(-r * 0.5, r * 0.3)]), Color(color, 0.62))

	# Roca: polígono deformado con la semilla propia, así que no hay dos
	# meteoros iguales sin necesidad de guardar nada. Muchos vértices y poca
	# amplitud: con pocos salía un pentágono, que se lee como una señal de
	# tráfico y no como una piedra.
	var roca := color.darkened(0.62)
	var pts := PackedVector2Array()
	var n := 15
	for i in n:
		var a := TAU * float(i) / float(n)
		var rr := r * (0.9 + 0.13 * sin(a * 3.0 + _semilla) * cos(a * 2.0 + _semilla * 1.7))
		pts.append(Vector2(cos(a) * rr, sin(a) * rr))
	draw_colored_polygon(pts, roca)

	# Borde al rojo, siguiendo el contorno real. Antes era un arco de radio fijo
	# que no coincidía con la silueta deformada y se leía como un arañazo suelto
	# flotando al lado de la piedra.
	var cerrado := pts.duplicate()
	cerrado.append(pts[0])
	draw_polyline(cerrado, Color(color, 0.8), maxf(1.4, r * 0.14), true)

	draw_circle(Vector2(-r * 0.24, -r * 0.22), r * 0.19, roca.darkened(0.4))
	draw_circle(Vector2(r * 0.12, r * 0.28), r * 0.12, roca.darkened(0.4))


## Robot: cuerpo cuadrado, antena y dos ojos.
##
## Se dibuja siempre derecho aunque se mueva de lado. Un robot ladeado se lee
## como un robot averiado, y estos no lo están: están patrullando.
func _robot(r: float) -> void:
	var chapa: Color = color
	var oscuro := color.darkened(0.72)

	# Antena, con la bolita parpadeando: es lo que da el pulso de "encendido".
	var luz := 0.45 + 0.55 * absf(sin(_fase * 3.4 + _semilla))
	draw_line(Vector2(0.0, -r * 0.75), Vector2(0.0, -r * 1.15), chapa, maxf(1.2, r * 0.11))
	draw_circle(Vector2(0.0, -r * 1.22), r * 0.2, Color(1.0, 0.42, 0.35, luz))

	# Patas cortas, antes del cuerpo para que queden por debajo.
	for lado in [-1.0, 1.0]:
		draw_line(Vector2(r * 0.36 * lado, r * 0.7), Vector2(r * 0.5 * lado, r * 1.05),
				oscuro, maxf(1.4, r * 0.16))

	# Cuerpo.
	draw_rect(Rect2(-r * 0.78, -r * 0.75, r * 1.56, r * 1.5), chapa)
	# Visor: una banda oscura de lado a lado con dos ojos dentro. La banda es
	# lo que hace que se lea como cara a nueve píxeles.
	draw_rect(Rect2(-r * 0.62, -r * 0.42, r * 1.24, r * 0.58), oscuro)
	draw_circle(Vector2(-r * 0.28, -r * 0.13), r * 0.15, Color(1.0, 0.42, 0.35, luz))
	draw_circle(Vector2(r * 0.28, -r * 0.13), r * 0.15, Color(1.0, 0.42, 0.35, luz))
	# Rejilla del pecho.
	for i in 3:
		var y := r * (0.16 + float(i) * 0.2)
		draw_line(Vector2(-r * 0.45, y), Vector2(r * 0.45, y), oscuro, maxf(1.0, r * 0.08))


## Cuánto se arquea la trayectoria de la fugaz, en radianes por segundo.
## Largo de la punta vertical del destello, en radios de dibujo.
const DESTELLO_LARGO := 2.3
## Las puntas horizontales son más cortas que las verticales: un destello con
## las cuatro iguales se lee como una cruz, no como un brillo.
const DESTELLO_ANCHO := 0.72
## Cuánto se hunden los lados entre dos puntas. Es lo que hace la silueta
## cóncava; con 0 saldría un rombo.
const DESTELLO_CONCAVIDAD := 2.6
## Segmentos del contorno. A 72 la curva ya no se ve poligonal al tamaño al que
## cruza.
const DESTELLO_SEGMENTOS := 72
## El destello interior, más pequeño y teñido, es lo que le da volumen: sin él
## la silueta blanca se lee plana, como un recorte.
const DESTELLO_INTERIOR := 0.52
const TINTE_DESTELLO := Color("a99fd0")
## Semianchos y opacidades de las dos cintas, en radios de dibujo.
const ESTELA_HALO_ANCHO := 0.42
const ESTELA_HALO_ALFA := 0.34
const ESTELA_FILO_ANCHO := 0.16
const ESTELA_FILO_ALFA := 0.95
## Capas del halo y opacidad de cada una.
##
## Seis capas de 0.06 se veían como seis aros concéntricos con su borde: una
## diana. El salto de brillo entre capas es lo que delata el escalón, así que la
## solución no es repartir mejor seis, sino que cada salto sea tan pequeño que
## no se distinga.
const HALO_CAPAS := 20
const HALO_ALFA := 0.014

## Color del rastro. Va aparte del color del objetivo porque la cabeza es la luz
## y la estela es lo que esa luz deja en el aire: en Cielo abierto la cabeza es
## blanca y el rastro tira a azul, como el de la onda.
var color_estela: Color = Color("8ec5ff")

## Si la posición la pone otro. Ver Hormiguero.
var guiado: bool = false

var curva_fugaz: float = 0.35
## Cuántos puntos de rastro guarda para dibujar la estela.
var largo_estela: int = 16


## La estela, con la trayectoria REAL y no con una recta hacia atrás.
##
## Es lo que hace que la curvatura se vea. Con una recta, arquear el rumbo no se
## notaría y la curva sería trabajo perdido.
##
## Va como UN polígono con color por vértice, y no como tramos sueltos. Tramo a
## tramo el grosor sí podía cambiar, pero cada segmento acaba en corte recto y a
## este grosor los cortes se ven: la estela salía dentada, como una escalera. Un
## polígono con los bordes ya calculados no tiene juntas que se noten.
func _dibujar_estela(r: float) -> void:
	if _estela.size() < 2:
		return
	# Dos cintas, no una. Una sola no puede ser a la vez el filo brillante que
	# marca la trayectoria y el resplandor ancho que la envuelve: subir su ancho
	# la vuelve una mancha y bajarlo la deja como un pelo. Separadas, la ancha
	# pone el color y la fina pone el trazo.
	_cinta(r, ESTELA_HALO_ANCHO, ESTELA_HALO_ALFA, color_estela)
	_cinta(r, ESTELA_FILO_ANCHO, ESTELA_FILO_ALFA, color_estela.lerp(color, 0.85))


## Una cinta a lo largo del rastro, que se estrecha y se apaga hacia atrás.
func _cinta(r: float, ancho: float, alfa: float, col: Color) -> void:
	var n := _estela.size()
	var izq := PackedVector2Array()
	var der := PackedVector2Array()
	var col_izq := PackedColorArray()
	var col_der := PackedColorArray()
	for i in n:
		var t := float(i) / float(n - 1)
		var p := to_local(_estela[i])
		# El rumbo en cada punto sale de sus vecinos; en los extremos, del único
		# que hay. Sin esto la cinta se retuerce justo en las puntas.
		var antes := to_local(_estela[maxi(i - 1, 0)])
		var luego := to_local(_estela[mini(i + 1, n - 1)])
		var rumbo := luego - antes
		if rumbo.length() < 0.001:
			rumbo = Vector2.RIGHT
		# El ancho va con t al cuadrado, no lineal: la cinta se abre despacio al
		# principio y deprisa junto a la cabeza. Lineal salía una cuña recta, y
		# al cubo se abría de golpe, como un ala.
		var semi := r * ancho * t * t
		var c := Color(col, alfa * t * t)
		var normal := rumbo.orthogonal().normalized()
		izq.append(p + normal * semi)
		der.append(p - normal * semi)
		col_izq.append(c)
		col_der.append(c)
	# El contorno va por un lado y vuelve por el otro.
	der.reverse()
	col_der.reverse()
	draw_polygon(izq + der, col_izq + col_der)


## Estrella fugaz: una chispa, y nada más. La estela la pone _dibujar_estela.
##
## Antes era un rombo alargado en el sentido de la marcha. El rombo se leía como
## una punta de flecha —algo disparado, con forma propia— y competía con el
## rastro por contar la misma cosa. Una fugaz no tiene forma: tiene brillo, y lo
## que de verdad se ve de ella es lo que deja detrás. Así que la cabeza pasa a
## ser redonda y la dirección la cuenta la estela, ella sola.
##
## Mismo esquema que _chispa —núcleo y halo, sin efectos— pero más grande y con
## el centro en blanco: es un objetivo que vale diez y tiene que pedir el dedo
## desde el otro lado de la pantalla.
func _fugaz(r: float) -> void:
	# El halo va en capas finas y no en dos círculos. Dos dejan un borde duro
	# cada uno y la cabeza se lee como una diana. El radio va con t al cuadrado:
	# así las capas se apiñan junto al centro y se separan hacia fuera, que es
	# como cae la luz de verdad.
	for i in HALO_CAPAS:
		var t := 1.0 - float(i) / float(HALO_CAPAS)
		draw_circle(Vector2.ZERO, r * (0.3 + 1.2 * t * t), Color(color, HALO_ALFA))
	draw_colored_polygon(_silueta_destello(r * DESTELLO_LARGO), color)
	draw_colored_polygon(_silueta_destello(r * DESTELLO_LARGO * DESTELLO_INTERIOR),
			color.lerp(TINTE_DESTELLO, 0.45))


## Contorno del destello de cuatro puntas.
##
## Va SIN girar con el rumbo —Giro.FIJO en GIRO_DE_FORMA—. Antes giraba, y tenía
## sentido cuando la cabeza era un rombo apuntando a donde iba: había que
## orientarlo. Un destello no tiene delante ni detrás, y ladeado deja de leerse
## como un brillo y pasa a parecer un aspa torcida. La estela no se entera del
## cambio porque se dibuja a partir de posiciones del mundo, no del nodo.
##
## Sale de una fórmula polar —el radio se estrangula según se separa de una
## punta— y no de dos rombos cruzados. Dos rombos dan lados RECTOS entre punta y
## punta, y lo que hace que un brillo parezca brillo es justo lo contrario: que
## los lados se hundan hacia el centro y las puntas salgan afiladas.
func _silueta_destello(largo: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in DESTELLO_SEGMENTOS:
		var a := TAU * float(i) / float(DESTELLO_SEGMENTOS)
		var radio := largo / (1.0 + DESTELLO_CONCAVIDAD * absf(sin(a * 2.0)))
		pts.append(Vector2(cos(a) * radio * DESTELLO_ANCHO, sin(a) * radio))
	return pts


## Hormiga: tres segmentos, seis patas y dos antenas.
##
## Va orientada, con la cabeza en +X. Las patas se mueven: a este tamaño el
## detalle no se distingue, pero el temblor sí, y es lo que convierte una
## mancha alargada en un bicho que camina.
func _hormiga(r: float) -> void:
	var cuerpo: Color = color
	var paso := sin(_fase * 14.0 + _semilla) * r * 0.22

	# Patas: los tres pares salen del TÓRAX, que es donde salen de verdad, y
	# tienen rodilla. Naciendo del abdomen y rectas parecían púas; con el codo
	# y el punto de anclaje correcto se leen como patas aunque midan cuatro
	# píxeles.
	for i in 3:
		var bx := r * (0.16 - float(i) * 0.18)
		var atras := r * (0.45 - float(i) * 0.5)
		var largo := r * (0.85 - float(i) * 0.05)
		var alt := paso if i % 2 == 0 else -paso
		for lado in [-1.0, 1.0]:
			var codo := Vector2(bx + atras * 0.45, r * 0.42 * lado)
			draw_line(Vector2(bx, r * 0.1 * lado), codo, cuerpo, maxf(0.9, r * 0.09))
			draw_line(codo, Vector2(bx + atras + alt, largo * lado),
					cuerpo, maxf(0.9, r * 0.09))

	# Antenas.
	for lado in [-1.0, 1.0]:
		var codo := Vector2(r * 1.05, r * 0.26 * lado)
		draw_line(Vector2(r * 0.74, r * 0.12 * lado), codo, cuerpo, maxf(0.8, r * 0.07))
		draw_line(codo, codo + Vector2(r * 0.34, r * 0.12 * lado + paso * 0.3),
				cuerpo, maxf(0.8, r * 0.07))

	# Gáster, tórax y cabeza. Los tres SEPARADOS: lo que identifica a una
	# hormiga es la cintura, y si los óvalos se solapan queda un churro
	# alargado que podría ser cualquier bicho.
	_ovalo(Vector2(-r * 0.8, 0.0), r * 0.5, r * 0.44, cuerpo)
	_ovalo(Vector2(-r * 0.02, 0.0), r * 0.24, r * 0.3, cuerpo)
	_ovalo(Vector2(r * 0.6, 0.0), r * 0.3, r * 0.28, cuerpo)
	# Ojo, en claro: da la dirección de un vistazo.
	draw_circle(Vector2(r * 0.72, -r * 0.14), r * 0.1, cuerpo.lightened(0.65))


## Elipse rellena. draw_circle solo hace círculos y estos bichos son ovalados.
func _ovalo(centro: Vector2, rx: float, ry: float, tinte: Color) -> void:
	var pts := PackedVector2Array()
	var n := 14
	for i in n:
		var a := TAU * float(i) / float(n)
		pts.append(centro + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(pts, tinte)


## Brasa: sube y se renueva por abajo. Es la nieve del revés, y eso cambia la
## lectura del campo más de lo que parece — se caza hacia arriba.
func _mover_brasa(delta: float, area: Rect2) -> void:
	var vaiven := sin(_fase * 2.2 + _semilla) * base_speed * 0.45
	position += Vector2(vaiven, -base_speed * 0.5) * delta
	if position.y < area.position.y - radius:
		position = Vector2(area.position.x + randf() * area.size.x,
				area.end.y + radius)
	if position.x < area.position.x - radius:
		position.x = area.end.x + radius
	elif position.x > area.end.x + radius:
		position.x = area.position.x - radius


## Billar: rueda por el tapete, roza y rebota en las bandas.
##
## No cruza la pantalla: vive dentro de la mesa. Lo único que le cambia el rumbo
## son los choques, que resuelve Main, y las bandas, que resuelve esto.
##
## El límite NO es el borde de la pantalla sino el interior de la banda, y el
## rebote se calcula contra el centro más el radio dibujado, así que la bola
## nunca pisa la madera.
func _mover_billar(delta: float, area: Rect2) -> void:
	# La minima es un SUELO, no solo un tope al frenado. Frenando unicamente por
	# encima de ella, una bola que se para en seco al recibir un golpe frontal
	# -que es lo que hace un golpe frontal: transfiere toda la velocidad- se
	# quedaba quieta para siempre, y el bioma se iba apagando bola a bola.
	var minima := BILLAR_MINIMA * _unidad_de_arte()
	var v := velocity.length()
	if v > minima:
		velocity = velocity.normalized() * maxf(minima, v * pow(BILLAR_ROZAMIENTO, delta))
	elif v > 0.01:
		velocity = velocity.normalized() * minima
	else:
		# Parada del todo y sin rumbo que conservar: sale por donde sea.
		velocity = Vector2.from_angle(randf() * TAU) * minima
	position += velocity * delta

	# El limite es el borde interior de la banda de madera, no el de la pantalla,
	# y se mide contra el centro MAS el radio dibujado: asi la bola nunca pisa la
	# madera. Arriba manda ademas el area de juego si es mas baja, que es la
	# franja que el HUD tiene reservada.
	var pant := get_viewport_rect().size
	var margen := BILLAR_MARCO * _unidad_de_arte() + radio_bola()
	var izq := margen
	var der := pant.x - margen
	var arr := maxf(margen, area.position.y + radio_bola())
	var aba := pant.y - margen
	if position.x < izq:
		position.x = izq
		velocity.x = absf(velocity.x) * BILLAR_REBOTE
	elif position.x > der:
		position.x = der
		velocity.x = -absf(velocity.x) * BILLAR_REBOTE
	if position.y < arr:
		position.y = arr
		velocity.y = absf(velocity.y) * BILLAR_REBOTE
	elif position.y > aba:
		position.y = aba
		velocity.y = -absf(velocity.y) * BILLAR_REBOTE
	_rodar()


## Suma al ángulo rodado lo que la bola ha avanzado EN SU RUMBO.
##
## Se proyecta el paso sobre el rumbo en vez de usar su longitud: así una
## corrección de posición que no es avance —la separación de un choque, un
## reajuste contra la banda— no hace girar la bola. `phi += |v|·dt/r` parece
## correcto y no lo es.
func _rodar() -> void:
	if not _bola_listo:
		_bola_listo = true
		_bola_antes = position
		# La fase entra al azar: sin esto todas nacerían con el número mirando al
		# frente y se vería el patrón. Aparecer rodando incluye aparecer a media
		# vuelta.
		_bola_phi = randf() * TAU
		return
	var rad := radio_bola()
	if rad > 0.001 and velocity.length_squared() > 1.0:
		_bola_phi += (position - _bola_antes).dot(velocity.normalized()) / rad
	_bola_antes = position
	queue_redraw()


## El radio del disco dibujado. Es el radio con el que dos bolas se tocan y el
## que gobierna cuánto se desplaza la marca al rodar.
func radio_bola() -> float:
	return radio_dibujo * Arte.LIENZO_EN_RADIOS * BOLA_RADIO


## Con qué radio choca este objetivo contra otro igual.
##
## Normalmente es el de contagio, que es lo que siempre se usó. En Billar es el
## DIBUJADO, el mismo con el que se juzga el toque: dos bolas que se ven
## tocándose tienen que tocarse, y el de contagio es mucho menor que el dibujo.
func radio_contacto() -> float:
	return radio_bola() if modo == Movimiento.BILLAR else radius


## Cuántos píxeles mide una unidad del lienzo de arte en esta pantalla.
func _unidad_de_arte() -> float:
	var v := get_viewport()
	if v == null:
		return 1.0
	return v.get_visible_rect().size.x / Fondo.ARTE_ANCHO


## Globo: sube recto con una ese sutil, y se va por arriba.
##
## La deriva lateral NO acumula: la `x` oscila alrededor de una columna que no se
## mueve, así que un globo entra por una columna y sale por la misma. Sumando el
## seno a la posición en vez de calcularla, el globo se iría de lado poco a poco
## y acabaría pegado a un borde.
##
## Quien lo saca por arriba y lo devuelve por abajo es Main: la regla de entrada
## mira dónde están los demás globos, y un globo no conoce a sus vecinos.
func _mover_globo(delta: float) -> void:
	if not _globo_listo:
		_preparar_globo()
	_globo_fase += TAU / _globo_periodo * delta
	position.y -= _globo_sube * delta
	position.x = _globo_x + _globo_amplitud * sin(_globo_fase)


## Sortea la ese de este globo. La fase entra al azar: sin ella todos suben en
## paralelo y el campo entero se mece a la vez, que es lo contrario de una fiesta.
func _preparar_globo() -> void:
	_globo_listo = true
	_globo_x = position.x
	_globo_sube = base_speed * GLOBO_SUBE
	_globo_amplitud = randf_range(GLOBO_AMPLITUD.x, GLOBO_AMPLITUD.y)
	_globo_periodo = randf_range(GLOBO_PERIODO.x, GLOBO_PERIODO.y)
	_globo_fase = randf() * TAU


## Vuelve a entrar por abajo, en la columna que le diga Main.
func renacer_globo(donde: Vector2) -> void:
	position = donde
	_globo_listo = false
	_preparar_globo()


## La bola de billar, en tres capas. Devuelve si ha podido dibujarla.
##
## Una bola rodando se reconoce por una sola cosa: el número se va al borde, se
## achata, desaparece y vuelve media vuelta después. El color y el brillo se
## quedan donde están. Eso permite resolverlo sin animar el sprite:
##
##   cuerpo   el color y, en las rayadas, la franja   se rota al rumbo
##   marca    el disco blanco con el número           se desplaza y se achata
##   luz      brillo y sombra interior                no se mueve
##
## La LUZ es la pieza que más cambia el resultado: viene de la lámpara, no de la
## bola, así que no puede girar. Girando el sprite entero el brillo gira con ella
## y la bola se convierte en una peonza.
##
## Y el cuerpo se rota SIEMPRE, también en las lisas. La franja de una rayada es
## un cinturón alrededor de la esfera: alineado con el rumbo no cambia de aspecto
## al rodar en ese rumbo, así que no hay que animarla. Un círculo de color
## uniforme rotado es el mismo círculo, de modo que la regla vale para las
## dieciséis y no hay dos caminos de código.
func _dibujar_bola(r: float) -> bool:
	var cuerpo := Arte.target_capa(forma, numero, "cuerpo")
	if cuerpo == null:
		return false
	var lado := r * Arte.LIENZO_EN_RADIOS
	var destino := Rect2(Vector2(-lado, -lado) * 0.5, Vector2(lado, lado))
	var theta := velocity.angle() if velocity.length_squared() > 1.0 else 0.0

	draw_set_transform(Vector2.ZERO, theta, Vector2.ONE)
	draw_texture_rect(cuerpo, destino, false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	var k := cos(_bola_phi)
	if k > BOLA_MARCA_MINIMA:
		var marca := Arte.target_capa(forma, numero, "marca")
		if marca != null:
			_dibujar_marca(marca, lado, theta, k)
	var luz := Arte.target_capa(forma, numero, "luz")
	if luz != null:
		draw_texture_rect(luz, destino, false)
	return true


## El disco del número, desplazado sobre el rumbo y recortado al círculo.
##
## El recorte no es opcional: sin él la marca se sale del contorno de la bola en
## cuanto el ángulo rodado pasa de 45 grados. Se hace dibujando el propio círculo
## como polígono texturizado —la forma del polígono ES el recorte— en vez de con
## una máscara aparte, que costaría un material y una pasada más.
##
## El desplazamiento y el achatamiento van SOBRE EL RUMBO, no sobre el eje
## horizontal. En un bioma cenital donde las bolas rebotan en cuatro bandas la
## diagonal es el caso normal, y achatar siempre en X haría que una bola que sube
## enseñara el número estirado a lo alto: se leería como si la marca resbalara
## por la superficie en vez de girar con ella.
func _dibujar_marca(marca: Texture2D, lado: float, theta: float, k: float) -> void:
	var rad := lado * BOLA_RADIO
	var d := rad * sin(_bola_phi)
	var c := cos(theta)
	var s := sin(theta)
	# La transformación es girar al rumbo, desplazar, achatar en un solo eje y
	# deshacer el giro. Su parte lineal sale simétrica y su determinante es
	# exactamente el achatamiento, así que invertirla es barato.
	var cs := c * s * (k - 1.0)
	var a11 := k * c * c + s * s
	var a22 := k * s * s + c * c
	var t := Vector2(c, s) * d
	var puntos := PackedVector2Array()
	var uvs := PackedVector2Array()
	for i in BOLA_LADOS:
		var p := Vector2.from_angle(TAU * float(i) / float(BOLA_LADOS)) * rad
		puntos.append(p)
		# Qué punto de la textura le toca a este vértice: se deshace la
		# transformación y se pasa a coordenadas de 0 a 1 del lienzo.
		var q := p - t
		var origen := Vector2(a22 * q.x - cs * q.y, -cs * q.x + a11 * q.y) / k
		uvs.append(origen / lado + Vector2(0.5, 0.5))
	draw_colored_polygon(puntos, Color.WHITE, uvs, marca)


## Planeo: vira despacio y cabecea. Ningún tramo es recto del todo, así que
## adivinar dónde estará un avión exige mirarlo un segundo entero, no un
## instante. Es lo contrario del circuito.
func _mover_planeo(delta: float, area: Rect2) -> void:
	_giro -= delta
	if _giro <= 0.0:
		_giro = randf_range(1.1, 2.4)
		_vira = randf_range(-0.8, 0.8)
	velocity = Vector2.from_angle(velocity.angle() + _vira * delta) * base_speed
	var cabeceo := Vector2(0.0, sin(_fase * 2.1 + _semilla) * base_speed * 0.2)
	position += (velocity + cabeceo) * delta
	_rebotar(area)


## Misil: acelera en su rumbo hasta un tope.
##
## Es el único bioma donde el campo se vuelve más difícil solo con esperar: un
## grupo que ahora se puede cazar, en dos segundos ya no. Castiga la duda, que
## es justo lo que el resto del juego premia.
const MISIL_ACEL := 0.85
const MISIL_TOPE := 2.4

func _mover_misil(delta: float, area: Rect2) -> void:
	var v := velocity.length()
	if v < base_speed * MISIL_TOPE:
		velocity = velocity.normalized() * (v + base_speed * MISIL_ACEL * delta)
	position += velocity * delta
	_rebotar(area)


## Bombardeo: el misil CAE, y cada uno cae a su manera.
##
## Antes cruzaban de lado a lado con un zigzag único, y eso era doblemente falso:
## un misil no viaja en horizontal, y si todos hacen el mismo zigzag el campo se
## memoriza en dos partidas.
##
## La trayectoria es un desplazamiento que se SUMA a la vertical, no un cambio de
## rumbo: el misil no deriva hacia un lado, serpentea alrededor de su vertical.
## Por eso se guarda `_misil_x` y la x de cada fotograma sale de ella más el
## desplazamiento, en vez de integrarse.
##
## No rebota abajo a propósito: llegar a la ciudad es perder, y de eso se encarga
## main.gd. Un misil solo desaparece por detonación.
func _mover_bombardeo(delta: float, area: Rect2) -> void:
	var antes := position
	var t := _fase
	var caida := base_speed

	if not _misil_anclado:
		_misil_anclado = true
		_misil_x = position.x
		_misil_y = position.y
		_misil_y0 = position.y
	# La vertical cae sola y la posición sale de ella más el desplazamiento. No
	# se integra la posición: el bucle del remolino SUBE durante parte de la
	# vuelta, y si eso se integrara la caída se perdería un trozo cada bucle.
	_misil_y += caida * delta

	var dx := 0.0
	var dy := 0.0
	match misil_tray:
		Misil.RECTA:
			dx = misil_deriva * t
		Misil.ESE:
			dx = _dx_ese(t)
		Misil.QUIEBRO:
			# Cae recto, corrige UNA vez y mantiene el rumbo nuevo. Es el único
			# que cambia de rumbo de verdad, y funciona porque el jugador ya
			# había calculado dónde iba a caer.
			if t >= misil_quiebro:
				dx = misil_tangente * caida * (t - misil_quiebro)

	# El desfase de nacimiento se ancla al MOVERSE y no al sortear la
	# trayectoria: Main prepara el misil antes de meterlo en el árbol, y ahí
	# _semilla todavía vale cero porque la sortea _ready.
	if is_zero_approx(t - delta) and not is_zero_approx(dx):
		_misil_dx0 = dx
	dx -= _misil_dx0

	position.y = _misil_y + dy
	# En los lados el desplazamiento se PLIEGA contra la guarda, no se envuelve:
	# teletransportar un misil que el jugador viene siguiendo rompe lo único que
	# se le pide hacer en este bioma.
	position.x = _plegar(_misil_x + dx, area.position.x + radius,
			area.end.x - radius)

	# El ángulo sale de la velocidad de ESTE fotograma, no de un valor fijo.
	# Con la llamarada al triple dejó de ser un detalle: con un ángulo fijo el
	# fuego apunta a donde el misil no va, y en el remolino sale de costado.
	var v := (position - antes) / maxf(delta, 0.0001)
	if v.length_squared() > 1.0:
		velocity = v
		rotation = v.angle()


## El desplazamiento lateral de la ese en un instante.
##
## Dos senos de periodos que no encajan —el segundo es 0,41 del primero, que no
## es fracción entera— así que la ese no se repite nunca igual. Es el mismo truco
## que la nieve, con más amplitud y menos periodo: la nieve oscila, el misil
## serpentea.
func _dx_ese(t: float) -> float:
	var d := misil_amplitud * sin(TAU * t / misil_periodo + _semilla)
	return d + misil_amplitud * 0.34 * sin(
			TAU * t / (misil_periodo * 0.41) + _semilla * 1.7)


## Cuánto mide la estela del meteoro y cada cuánto se muestrea.
##
## Se llama estela_meteoro_largo y no largo_estela porque ese nombre ya es de la
## fugaz, que cuenta su estela en FOTOGRAMAS y no en píxeles: son dos estelas con
## dos maneras de medirse y conviene que no se confundan.
func estela_meteoro_largo() -> float:
	return radio_dibujo * _estela_largo


func paso_estela() -> float:
	return estela_meteoro_largo() / float(MUESTRAS_ESTELA)


func ancho_estela() -> float:
	return radio_dibujo * ANCHO_ESTELA


func anillo_estela() -> PackedVector2Array:
	return _anillo


func entrada() -> float:
	return _entrada


## Sortea el largo propio de esta roca. La llama Main al darla de alta.
func preparar_estela(largo: Vector2) -> void:
	_estela_largo = randf_range(largo.x, largo.y)
	_anillo = PackedVector2Array()


## Añade una muestra al anillo cuando el meteoro ha recorrido un paso.
##
## Y lo VACÍA si ha dado un salto: en cuanto el meteoro se teletransporta
## —reaparecer arriba, envolver por un lado— la cinta uniría la posición vieja
## con la nueva y cruzaría la pantalla de lado a lado.
## Las muestras se guardan en el espacio del PADRE, no en el global.
##
## La capa de estelas cuelga del mismo padre que los targets y se desplaza con
## la sacudida igual que ellos. Guardando globales, el desplazamiento se contaría
## dos veces y la estela se despegaría de su roca en cuanto el campo temblara.
func _muestrear_estela() -> void:
	var p := position
	if _anillo.is_empty():
		_anillo.append(p)
		return
	var ultimo := _anillo[0]
	var d := p.distance_to(ultimo)
	if d > radius * SALTO_ESTELA:
		_anillo = PackedVector2Array([p])
		return
	if d < paso_estela():
		# Sin muestra nueva, pero la cabeza sigue donde está el meteoro: si no,
		# la cinta se quedaría un paso por detrás de la roca.
		_anillo[0] = p
		return
	_anillo.insert(0, p)
	var tope := MUESTRAS_ESTELA + 1
	while _anillo.size() > tope:
		_anillo.remove_at(_anillo.size() - 1)


## Refleja un valor dentro de un rango, las veces que haga falta.
##
## Una reflexión y no un recorte: recortado, el misil se quedaría pegado al borde
## mientras su seno sigue empujando hacia fuera, y lo que se ve es un misil
## clavado en la pared. Plegado, rebota y sigue.
func _plegar(v: float, lo: float, hi: float) -> float:
	if hi <= lo:
		return lo
	var ancho := hi - lo
	var u := fposmod(v - lo, ancho * 2.0)
	return lo + (u if u <= ancho else ancho * 2.0 - u)


## Sortea la trayectoria y sus parámetros. La llama Main al dar de alta el misil.
func preparar_misil(cual: Misil, deriva: Vector2, amplitud: Vector2,
		periodo: Vector2, quiebro: Vector2, angulo: Vector2) -> void:
	misil_tray = cual
	_misil_x = position.x
	_misil_y0 = position.y
	_misil_y = position.y
	_misil_dx0 = 0.0
	_misil_anclado = false
	match cual:
		Misil.RECTA:
			misil_deriva = randf_range(deriva.x, deriva.y)
		Misil.ESE:
			misil_amplitud = randf_range(amplitud.x, amplitud.y)
			misil_periodo = randf_range(periodo.x, periodo.y)
		Misil.QUIEBRO:
			misil_quiebro = randf_range(quiebro.x, quiebro.y)
			var grados := randf_range(angulo.x, angulo.y) * (1.0 if randf() < 0.5 else -1.0)
			misil_tangente = tan(deg_to_rad(grados))


## Circuito: solo horizontal y vertical, con giros de noventa grados. Las
## trayectorias son las más predecibles del juego, así que lo difícil deja de ser
## adivinar y pasa a ser esperar al cruce.
func _mover_circuito(delta: float, area: Rect2) -> void:
	_giro -= delta
	if _giro <= 0.0:
		_giro = randf_range(0.45, 1.3)
		var d := velocity.normalized()
		velocity = (Vector2(-d.y, d.x) if randf() < 0.5 else Vector2(d.y, -d.x)) * base_speed
	position += velocity * delta
	_rebotar(area)


## Se comprueba también el signo de la velocidad: sin eso, un círculo que
## aparece fuera del borde queda atrapado invirtiéndose cada frame.
## Lo que tiene que caber en pantalla es lo que se ve, no el radio de lógica.
##
## Rebotando con `radius` —que es la mitad del dibujo— un objetivo giraba a nueve
## píxeles del borde y se quedaba quince cortado por fuera.
func radio_visible() -> float:
	return radio_dibujo


func _rebotar(area: Rect2) -> void:
	var r := radio_visible()
	if position.x < area.position.x + r and velocity.x < 0.0:
		velocity.x = -velocity.x
	elif position.x > area.end.x - r and velocity.x > 0.0:
		velocity.x = -velocity.x
	if position.y < area.position.y + r and velocity.y < 0.0:
		velocity.y = -velocity.y
	elif position.y > area.end.y - r and velocity.y > 0.0:
		velocity.y = -velocity.y
