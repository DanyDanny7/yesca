# 14 · Catálogo de biomas

Los diecisiete biomas, cada uno con **qué se revienta** y **sobre qué fondo**.

Un bioma no es una piel. Cambia tres cosas a la vez —la forma del objetivo, su
manera de moverse y el telón— y las tres tienen que contar la misma historia: si
las abejas se movieran como copos de nieve, el dibujo sería decorado y no
información. La regla que gobierna todo el catálogo:

> La silueta dice qué es y el movimiento dice cómo cazarlo. Si hay que
> explicarlo con un texto, la forma está mal elegida.

Todo está dibujado con polígonos en `_draw()`, sin una sola imagen. Se puede
sustituir cualquier pieza por un PNG sin tocar la lógica: ver
`13-arte-intercambiable.md`.

## Cómo leer las fichas

**Movimiento** es el de `Dot.Movimiento`; gobierna el balance y es lo que
realmente cambia la partida. **Marco** y **banda** son adornos que no se repiten
en mosaico: el marco se dibuja una vez sobre el fondo (una bañera repetida en
baldosas no es una bañera) y la banda se ancla a un borde.

---

## 1 · Cielo abierto

| | |
|---|---|
| **Objetivo** | **Dos formas mezcladas al azar**: estrella de cinco puntas que **titila** —el brillo late despacio y cada una con su fase, así que el campo nunca parpadea a coro— y **chispa**, un núcleo pequeño con halo que parece emitir luz sin necesidad de ningún efecto. |
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
| **Objetivo** | Pez, con **la cola batiendo**. Orientado: mira siempre hacia donde nada. |
| **Fondo** | Líneas de corriente que se desplazan **hacia la derecha**, en el mismo sentido que el agua arrastra a los peces. La dirección del mosaico cuenta la historia sin decir una palabra. |
| **Movimiento** | Corriente. Entran por la izquierda y salen por la derecha; siempre en ese sentido, porque un río con dos sentidos no es un río. |

Los grupos se forman solos río abajo: es el bioma que regala cadenas.

## 4 · Hormigas

| | |
|---|---|
| **Objetivo** | Hormiga: tres segmentos separados —gáster, tórax y cabeza—, seis patas que se mueven y dos antenas. Lo que identifica a una hormiga es **la cintura**, no la silueta general. Orientada al avance. |
| **Fondo** | Tierra vista desde arriba: granos, guijarros y dos **galerías** que serpentean. Las galerías van con alfa muy baja a propósito: dicen que debajo hay un hormiguero, pero si se vieran más competirían con las hormigas, que es lo que hay que mirar. |
| **Movimiento** | Hormiga. Avanzan sin parar con el rumbo girando poco a poco, sumando dos ondas de periodo distinto para que el recorrido no se cierre en círculos. |

**Treinta y cuatro objetivos**, más que ningún otro bioma, y los más lentos. Es
donde se aprende que la cadena vale más que la prisa: con este gentío, esperar
medio segundo siempre paga.

## 5 · Enjambre

| | |
|---|---|
| **Objetivo** | Círculo liso. El único bioma sin forma propia, y es deliberado: aquí lo interesante es el **grupo**, no la pieza. |
| **Fondo** | Células orgánicas, contornos redondeados que se agrupan. |
| **Movimiento** | Enjambre. Se buscan entre sí y forman grumos. |

El grupo viene servido; la decisión es cuándo detonarlo.

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
| **Objetivo** | Abeja con **alas que baten**, franjas negras y **aguijón**. Orientada al vuelo. |
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
| **Objetivo** | Llama pequeña que **ondea**, más ancha abajo que arriba. |
| **Fondo** | Pavesas subiendo sobre rojo muy oscuro. El mosaico se desplaza **hacia arriba**, al revés que la nieve. |
| **Movimiento** | Brasa. Suben y se renuevan por abajo. |

La nieve del revés: se caza hacia arriba, y eso basta para que se sienta otro
juego.

## 11 · Caza de robots

| | |
|---|---|
| **Objetivo** | Robot cuadrado con **antena parpadeante**, visor oscuro de lado a lado y dos ojos que laten. Se dibuja siempre derecho aunque se mueva de lado: un robot ladeado se lee como averiado, y estos están patrullando. |
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
| **Objetivo** | Globo ovalado con nudo y **cordel que ondea**, cada uno de uno de ocho colores. El cordel es lo que lo convierte en globo y no en un huevo: es la única parte que se sale de la silueta, y por eso va en claro aunque el globo sea oscuro. |
| **Fondo** | Confeti inclinado en tamaños distintos, y una **guirnalda de banderines** colgando en curva de la banda superior. La curva tiene un periodo entero en el mosaico, así que la cuerda continúa de una repetición a la siguiente sin escalón. |
| **Movimiento** | Choque, como el billar. |

Un choque puede regalarte la cadena o arruinártela.

## 16 · Asedio · *defensa*

| | |
|---|---|
| **Objetivo** | **Misil**, orientado a la caída: morro apuntado y aletas traseras. |
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
