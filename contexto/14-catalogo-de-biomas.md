# 14 · Catálogo de biomas

Los diecisiete biomas, cada uno con **qué se revienta** y **sobre qué fondo**.

Un bioma no es una piel. Cambia tres cosas a la vez —la forma del objetivo, su
manera de moverse y el telón— y las tres tienen que contar la misma historia: si
las abejas se movieran como copos de nieve, el dibujo sería decorado y no
información. La regla que gobierna todo el catálogo:

> La silueta dice qué es y el movimiento dice cómo cazarlo. Si hay que
> explicarlo con un texto, la forma está mal elegida.

## Los targets vienen de assets desde el 2026-08-31

Las dieciocho formas se dibujan ahora desde PNG en `arte/targets/`. El dibujo por
polígonos sigue ahí de respaldo —borrar un fichero lo devuelve— pero ya no es lo
que se ve.

**Siete formas han perdido su animación interna**, que era el precio anunciado y
ahora pagado: las alas de la abeja, la cola del pez, el titileo de la estrella,
el ondeo de la llama, el cordel del globo, las patas de la hormiga y la antena
del robot. Una imagen no bate alas. Lo que **no** se ha perdido es la rotación
hacia el rumbo ni la animación de aparición, porque las pone el nodo y no el
dibujo.

Las fichas de abajo describen lo que se ve hoy. Los fondos y las explosiones
siguen siendo procedurales.

## Cómo leer las fichas

**Movimiento** es el de `Dot.Movimiento`; gobierna el balance y es lo que
realmente cambia la partida. **Marco** y **banda** son adornos que no se repiten
en mosaico: el marco se dibuja una vez sobre el fondo (una bañera repetida en
baldosas no es una bañera) y la banda se ancla a un borde.

---

## 1 · Cielo abierto

| | |
|---|---|
| **Objetivo** | **Dos formas mezcladas al azar**: estrella de cinco puntas y **chispa** de cuatro brazos. Ambas quietas: el titileo que tenía la estrella dibujada por código se perdió al pasar a asset. |
| **Fondo** | Campo de estrellas sobre azul casi negro. Cada pocos segundos **cruza una estrella fugaz**, con estela que se apaga. Es el único fondo con un suceso, y está aquí a propósito: es el primer bioma y el que enseña a mirar la pantalla entera. |
| **Movimiento** | Rebote. Línea recta y rebota en los bordes. |

> **Decidido el 2026-08-31, sin construir todavía.** Hoy el bioma solo dibuja
> estrellas; la chispa está dibujada pero huérfana, sin bioma que la use. Hasta
> que se aplique, esta ficha describe la intención.
>
> No es una línea como lo fue el misil: hace falta que una paleta pueda declarar
> **varias** formas y que se elija una **por objetivo**, no por bioma. El sitio
> es `_preparar_dot`, junto a la variedad por instancia que ya existe para el
> número de las bolas y el color de los globos. Y hay un segundo punto que se
> olvida fácil: en el modo sin fin, el barrido que cambia de bioma **reasigna la
> forma de cada objetivo** al pasar, así que ahí también tiene que sortear en
> vez de copiar una sola.

El bioma donde se aprende a jugar. Todo lo demás es una variación sobre esto.

Mezclar dos formas en un mismo bioma es un experimento que se paga barato aquí:
es el primer nivel, el más calmado, y si dos siluetas distintas confunden en vez
de enriquecer, se nota enseguida y con poco en juego.

## 2 · Invierno

| | |
|---|---|
| **Objetivo** | Cristal de nieve: seis brazos con ramitas. A nueve píxeles el detalle real es imposible, así que lo que lo identifica es la **silueta radial**. |
| **Fondo** | Copos cayendo en un azul frío, más una **aurora boreal** en la banda superior: cortinas de luz verde que ondean. El fondo se desplaza hacia abajo, así que la nieve cae aunque el mosaico no se mueva. |
| **Movimiento** | Nieve. Caen despacio con vaivén lateral y reaparecen arriba por otra columna. |

Va después de Cielo abierto para bajar el pulso antes de apretar.

## 3 · Río

| | |
|---|---|
| **Objetivo** | Pez naranja con franjas. Orientado: mira siempre hacia donde nada. La cola ya no bate; el asset llegó mirando a la izquierda y se **reflejó**, no se giró — girado nadaría panza arriba. |
| **Fondo** | Líneas de corriente que se desplazan **hacia la derecha**, en el mismo sentido que el agua arrastra a los peces. La dirección del mosaico cuenta la historia sin decir una palabra. |
| **Movimiento** | Corriente. Entran por la izquierda y salen por la derecha; siempre en ese sentido, porque un río con dos sentidos no es un río. |

Los grupos se forman solos río abajo: es el bioma que regala cadenas.

## 4 · Hormigas

| | |
|---|---|
| **Objetivo** | Hormiga: tres segmentos separados —gáster, tórax y cabeza—, seis patas y dos antenas. Lo que la identifica es **la cintura**, no la silueta general. Orientada al avance; las patas ya no se mueven. |
| **Fondo** | Tierra vista desde arriba: granos, guijarros y dos **galerías** que serpentean. Las galerías van con alfa muy baja a propósito: dicen que debajo hay un hormiguero, pero si se vieran más competirían con las hormigas, que es lo que hay que mirar. |
| **Movimiento** | Hormiga. Avanzan sin parar con el rumbo girando poco a poco, sumando dos ondas de periodo distinto para que el recorrido no se cierre en círculos. |

**Treinta y cuatro objetivos**, más que ningún otro bioma, y los más lentos. Es
donde se aprende que la cadena vale más que la prisa: con este gentío, esperar
medio segundo siempre paga.

## 5 · Básico

| | |
|---|---|
| **Objetivo** | Círculo liso. El único bioma sin forma propia, y de ahí el nombre: aquí lo interesante es el **grupo**, no la pieza. |
| **Fondo** | Células orgánicas, contornos redondeados que se agrupan. |
| **Movimiento** | Enjambre. Se buscan entre sí y forman grumos. |

El grupo viene servido; la decisión es cuándo detonarlo.

El bioma se llama Básico por el objetivo, no por la dificultad: el movimiento
sigue siendo el enjambre, que no tiene nada de básico. Es el mismo caso que Otoño
usando el movimiento de la nieve — **el nombre del bioma y el del movimiento son
cosas distintas**, y en la pantalla se ven las dos: «dificultad 9 · enjambre»
debajo del nombre del bioma.

## 6 · Billar

| | |
|---|---|
| **Objetivo** | Bola numerada del 1 al 15, cada una con su color y su **número dentro**. Lisa o con banda según el número, como en una mesa de verdad. |
| **Fondo** | **Mesa de billar**: tapete verde con su trama, marco de madera y **las seis troneras**. Va como marco, no como mosaico. El verde se oscureció respecto al primer intento porque un tapete realista dejaba el contraste con las bolas en 4,4:1; ahora está en 5,9:1. |
| **Movimiento** | Choque. Rebotan en los bordes **y entre ellos**. |

Nada se queda quieto: cada choque rehace el tablero.

## 7 · Panal

| | |
|---|---|
| **Objetivo** | Abeja de alas azuladas, franjas negras y **aguijón**. Orientada al vuelo. Las alas ya no baten. |
| **Fondo** | Panal hexagonal ámbar. El paso de la retícula es de 64 px —la mitad del mosaico— y no puede ser otro: con 128 el periodo del dibujo sale de 256 y aparecen costuras. |
| **Movimiento** | Abeja. Tirones, pausas y giros bruscos. Lo que la hace difícil de leer no es la velocidad media sino **lo poco que dura cada tramo recto**. |

## 8 · Estampida

| | |
|---|---|
| **Objetivo** | Dron, orientado a su rumbo. |
| **Fondo** | Rejilla técnica, fría y regular. |
| **Movimiento** | Huida. **Se apartan de las detonaciones activas.** |

El único bioma donde los objetivos reaccionan a lo que haces. Cada tap dispersa
al grupo que ibas a encadenar, así que la cadena hay que armarla antes.

## 9 · Otoño

| | |
|---|---|
| **Objetivo** | Hoja, que **voltea despacio** al caer. |
| **Fondo** | Hojas cayendo en tonos cálidos, desplazándose hacia abajo. |
| **Movimiento** | Nieve, el mismo que Invierno. |

Es Invierno en cálido, y está a propósito: el mismo movimiento con otra piel
demuestra cuánto cambia un bioma solo por el color y la forma.

## 10 · Brasas

| | |
|---|---|
| **Objetivo** | Llama pequeña, más ancha abajo que arriba. Ya no ondea. |
| **Fondo** | Pavesas subiendo sobre rojo muy oscuro. El mosaico se desplaza **hacia arriba**, al revés que la nieve. |
| **Movimiento** | Brasa. Suben y se renuevan por abajo. |

La nieve del revés: se caza hacia arriba, y eso basta para que se sienta otro
juego.

## 11 · Caza de robots

| | |
|---|---|
| **Objetivo** | Robot con antena, visor oscuro de lado a lado y dos ojos claros. Se dibuja siempre derecho aunque se mueva de lado: un robot ladeado se lee como averiado, y estos están patrullando. La antena ya no parpadea. |
| **Fondo** | Chapa remachada: placas grandes con **un remache en cada esquina**. El remache es lo que la separa de la rejilla de Estampida; sin él son dos cuadrículas. |
| **Movimiento** | Patrulla. Tramos rectos, **parada en seco** y salida en otra dirección. Entran por los cuatro lados de la pantalla. |

La parada es la pieza importante. Sin ella, un robot que cambia de rumbo cada
segundo se caza por suerte y no por puntería: ese cuarto de segundo quieto es la
ventana que lo convierte en una cacería. Solo catorce en pantalla, los menos de
todo el juego salvo los biomas de defensa.

## 12 · Circuito

| | |
|---|---|
| **Objetivo** | Chip con sus patillas. |
| **Fondo** | Trazas de placa: pistas con **codos en ángulo recto** y vías. |
| **Movimiento** | Circuito. Solo horizontal y vertical, con giros de 90 grados. |

Predecible y exigente a la vez: sabes dónde va a estar, pero también lo saben
los otros catorce.

## 13 · Ciudad de papel

| | |
|---|---|
| **Objetivo** | Avión de papel, orientado al vuelo. |
| **Fondo** | Estelas suaves, y en la banda inferior **una ciudad encendida y alegre**: edificios con ventanas cálidas que ocupan el tercio inferior de la pantalla. |
| **Movimiento** | Planeo. Viran suave y cabecean, como algo que se deja caer en el aire. |

Es el gemelo amable de Asedio: la misma ciudad, antes de que la ataquen.

## 14 · Ducha

| | |
|---|---|
| **Objetivo** | **Burbuja de jabón**: casi transparente, con reflejo, punto de luz y un arco tornasolado. Fue la forma más difícil de todo el juego, porque una burbuja es sobre todo **ausencia** de color y aquí el objetivo tiene que verse sí o sí. Se resolvió cargando toda la legibilidad en el anillo del borde: con el contorno resuelto, el interior puede permitirse ser casi invisible. |
| **Fondo** | Alicatado de baño, y una **bañera** dibujada como marco: cuerpo, patas, grifo y una hilera de espuma en la línea de agua. |
| **Movimiento** | Brasa. Las burbujas suben desde el agua. |

El bioma más amable de todos. Aquí no hay prisa.

## 15 · Fiesta

| | |
|---|---|
| **Objetivo** | Globo ovalado con nudo y cordel, cada uno de uno de ocho colores. El cordel es lo que lo convierte en globo y no en un huevo: es la única parte que se sale de la silueta. Ya no ondea. |
| **Fondo** | Confeti inclinado en tamaños distintos, y una **guirnalda de banderines** colgando en curva de la banda superior. La curva tiene un periodo entero en el mosaico, así que la cuerda continúa de una repetición a la siguiente sin escalón. |
| **Movimiento** | Choque, como el billar. |

Un choque puede regalarte la cadena o arruinártela.

## 16 · Asedio · *defensa*

| | |
|---|---|
| **Objetivo** | **Misil**, orientado a la caída, con su llamarada detrás. |
| **Fondo** | Estelas, y en la banda inferior **la misma ciudad de papel, pero rota y ardiendo**: siluetas quebradas en naranja. |
| **Movimiento** | Bombardeo. Caen de arriba abajo zigzagueando en ese. |

**Si uno toca el suelo, se acabó la partida.** Es una de las dos derrotas del
juego que no vienen de la barra de tiempo, y por eso se lee distinto: explosión
grande, del color de la ciudad ardiendo, en el sitio exacto del impacto. El
jugador tiene que ver **dónde** falló, no solo que falló.

El bioma está calibrado en contra de su propio instinto: los proyectiles caen
más despacio pero salen mucho más seguido, porque la amenaza no es la velocidad
de cada uno sino cuántos hay bajando a la vez. Y el desagüe de la barra baja al
45%: con el normal se perdía por tiempo a los 11 s mientras los proyectiles
tardaban 21 s en llegar abajo, así que la mecánica del bioma **no llegaba a
entrar en juego**.

## 17 · Lluvia de meteoros · *defensa*

| | |
|---|---|
| **Objetivo** | **Meteoro**: roca deformada con cráteres y **dos capas de estela** ardiendo detrás, una ancha y tenue y otra estrecha y viva. Con una sola no hay sensación de calor, solo una mancha. La deformación sale de la semilla propia de cada uno, así que no hay dos iguales sin guardar nada. |
| **Fondo** | Campo de estrellas y, **abajo a la izquierda, la Tierra**: océano, cinco masas continentales en posiciones fijas, casquete polar y dos aros de atmósfera. El centro cae por debajo del borde inferior, así que solo se ve un casquete y se lee como un mundo y no como una pelota. La luz entra por arriba a la derecha, que es de donde vienen los meteoros. |
| **Movimiento** | Meteoro. Rumbo fijo hacia el planeta, **acelerando**, y no rebotan nunca. |

**Si uno alcanza el planeta, se acabó la partida.**

Entran por arriba y por la derecha, nunca dos por el mismo sitio, pero todos
apuntan al planeta. Esa convergencia es lo que convierte quince trayectorias
sueltas en una lluvia; sin ella solo son piedras. Cada uno apunta a un punto
**cualquiera del disco**, no al centro: si todos fueran al centro, las
trayectorias se solaparían en un solo hilo al acercarse y la lluvia se leería
como una fila.

La geometría del planeta vive en `Fondo`, en estático, aunque quien comprueba el
impacto sea `Main`. Es la frontera entre lo que se ve y la derrota: si cada uno
calculara su versión, bastaría con retocar el dibujo para que el impacto dejara
de coincidir con el borde visible, y el jugador perdería por tocar algo que ya
no estaba ahí.

Medido sin tocar nada: la partida muere a los **15,2 s** por impacto, no por
reloj. Es la comprobación que faltó la primera vez que se hizo Asedio.

---

## Los proyectiles caen en unos seis segundos

Caían en quince de media, y a esa velocidad se leían como adorno de fondo, no
como amenaza. La tensión de un bioma de defensa está en el poco tiempo que
tienes para reaccionar a cada proyectil, no en cuántos hay.

Ahora la caída media es de unos seis segundos en los dos. Como consecuencia
directa, una partida abandonada muere en cinco o seis segundos en vez de en
doce: es el mismo número visto desde el otro lado, y por eso el mundo espera
congelado hasta que tocas.

## Los biomas de defensa esperan a que empieces

En Asedio y Lluvia de meteoros **nada se mueve hasta el primer toque**. En el
resto de biomas el campo sigue vivo de fondo desde el menú, que es una decisión
vieja y buena: una pantalla de inicio con el juego moviéndose detrás se siente
despierta y enseña la mecánica antes de que nadie toque nada.

Pero en defensa esa misma decisión producía un fallo feo: la comprobación de
impacto solo cuenta durante la partida, así que antes del primer toque los
proyectiles caían, **atravesaban la ciudad y no pasaba nada**. Después de tocar
una vez ya funcionaba, lo que lo hacía todavía más desconcertante.

Congelar es mejor que la alternativa. Dejar que exploten antes de empezar sería
perder sin haber tocado nada, que es peor fallo que el que se arregla. Y encaja
con el reloj, que tampoco corre hasta que empiezas.

## Los dos que faltan en el modo sin fin

La rotación del modo sin fin usa **quince** de los diecisiete: quedan fuera
Asedio y Lluvia de meteoros. Perder porque un proyectil tocó el suelo tiene
sentido en un nivel que avisa de ello en su pista, pero en una partida sin fin
aparecería de la nada a los tres minutos y se leería como una injusticia.

Los quince salen **barajados en una bolsa**: se saca sin reemplazo hasta
agotarla y solo entonces se vuelve a llenar. Al azar puro saldría el mismo bioma
dos veces seguidas cada tantas rondas, y un jugador que ve repetirse el
escenario no piensa «ha tocado otra vez», piensa que el juego no avanza. Con la
bolsa el orden es imprevisible pero el reparto es justo: antes de repetir
ninguno, salen todos.
