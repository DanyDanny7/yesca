# 16 · Orientación y entregas

Dos cosas que hasta ahora vivían en la cabeza de alguien y ahora son mecanismo:
**cómo se orienta cada forma** y **cómo entra el arte al proyecto**.

El contrato para quien dibuja está en `entregas/LEEME.md`. Esto de aquí es el
porqué.

## La orientación era una lista de excepciones

Estaba así, dentro de `mover()`:

```gdscript
if forma in [DRON, AVION, MISIL, ABEJA, PEZ, METEORO, HORMIGA] ...:
    rotation = velocity.angle()
elif forma == HOJA:
    rotation += delta * 0.9
```

Funcionaba mientras todas las formas eran polígonos vistos desde arriba. Con
arte de verdad dejó de funcionar, y de una manera que se ve a simple vista: la
abeja y el pez están dibujados **de perfil**, así que al girar hacia un rumbo
que va a la izquierda volaban y nadaban **boca arriba**.

Nadie mira un pez del revés y piensa «va hacia allá». Piensa que está muerto.

### La regla

> Una forma solo puede dar la vuelta entera si se dibujó vista desde arriba.

De ahí salen cinco políticas, en `Dot.Giro`:

| | Qué hace | Para qué |
|---|---|---|
| `FIJO` | nunca gira | lo que tiene peso o cuelga |
| `RUMBO` | apunta a donde va | vistas cenitales |
| `ESPEJO` | se refleja al ir a la izquierda | perfiles quietos |
| `CABECEO` | se refleja **y** se inclina un poco | perfiles vivos |
| `NORIA` | gira sola, ajena al rumbo | hojas cayendo |

El detalle que importa: **el reflejo se hace con `scale.x`, no girando 180
grados**. Girado, el pez nada panza arriba; reflejado, nada hacia el otro lado,
que es lo que hace de verdad. La diferencia no se ve en una hoja de contactos
porque ahí está quieto, y por eso hay que decidirla en el código y no al
dibujar.

La inclinación del `CABECEO` está topada en 0,55 rad. Pasado ese ángulo, un pez
deja de leerse como que baja y empieza a leerse como que se cae.

### La guarda

`tools/giro.gd` recorre las dieciocho formas con un rumbo hacia la izquierda y
comprueba que ninguna de perfil acaba invertida.

La primera versión de esa herramienta **daba falsas alarmas**: marcaba también
al dron y al meteoro, que dan la vuelta entera a propósito. Se corrigió para que
solo cuente como fallo en `ESPEJO` y `CABECEO`. Una comprobación que grita sin
motivo enseña a ignorarla, y entonces ya no comprueba nada.

## Las entregas tenían un solo cajón

`arte/assets-yesca/` era la carpeta de entrega, y era una sola: una tanda nueva
pisaba a la anterior. Con dos tandas ya se notó el problema —hubo que corregir
un fondo y no había forma de comparar con lo que había antes.

Ahora:

```
entregas/<AAAA-MM-DD-tema>/     el buzón, una carpeta por tanda
arte/                            lo que el juego lee, lo genero yo importando
```

**Nadie escribe en `arte/`.** Esa separación es lo que permite reemplazar una
entrega entera sin miedo: si sale mal, la anterior sigue ahí y se reimporta en
un comando. Las herramientas toman el lote como argumento justo para eso.

## Las explosiones admiten dos formas

Antes solo una imagen quieta, que el nodo escalaba y desvanecía. Servía para
sustituir el dibujo, no para diseñar un efecto: quien lo hiciera no controlaba
el final.

Ahora también **tira de fotogramas** —`cadena@8.png`, ocho en fila— y con tira
el juego **no desvanece**: el apagado lo lleva el dibujo. Hacer las dos cosas lo
apagaría dos veces y le quitaría el control justo donde se nota.

Y **variante por bioma**, con el mismo mecanismo que ya numeraba las bolas de
billar: se prueba `impacto_asedio.png` y se cae a `impacto.png`. Así la
explosión del planeta puede no parecerse en nada a la de la ciudad sin
inventar un tipo nuevo.

## Lo que sigue sin poder entregarse como asset

**Los movimientos.** Son código, porque necesitan ver a los demás objetivos y a
las detonaciones. Lo que se entrega es una especificación de seis preguntas
—entrada, rumbo, rapidez, bordes, relación con los demás, orientación— y la
implemento yo. Las seis están en `entregas/LEEME.md`; si alguna llega en blanco,
me la invento, y probablemente mal.

## Un fondo para todas las pantallas

Los teléfonos van de 16:9 a 20:9 y las tabletas bajan a 4:3. La tentación es
entregar varios tamaños; la respuesta buena es no hacerlo.

El juego escala la composición **por el ancho** y la ancla **abajo**. Eso da tres
propiedades gratis: nunca hay deformación horizontal, lo anclado abajo no se
pierde nunca, y lo de arriba es lo elástico. Medido sobre pantallas reales, la
composición cubre entre el 73% de un 20:9 y el 121% de una tableta 4:3.

Pero eso no es «verse exacto en todas», y conviene decirlo claro: con un fondo a
sangre, **exacto es físicamente imposible**. Las proporciones van de 1:1.33 a
1:2.33 y solo hay tres salidas: deformar, recortar, o poner barras negras.

Lo que sí se puede garantizar es cero deformación, cero huecos, y **la misma
banda de abajo al mismo ancho en todos los aparatos**, cambiando solo cuánto
cielo se ve. Y para eso hace falta una cosa: que el lienzo sea **más alto que la
pantalla más alta**. El actual, 208×336, es 1:1.62 — más corto que cualquier
móvil, y por eso hoy el comportamiento no es uniforme: en un 20:9 falta arte y
se rellena con azulejo, en una tableta sobra y se recorta.

Con 208×500 (1:2.40) nunca falta. Todas las pantallas hacen lo mismo, y la zona
segura garantizada son los 277 units de abajo (los 370 si se descartan las
tabletas). Es lo mismo que hace cualquier diseño impreso con margen de corte, y
escala a pantallas que aún no existen.

Para que ese cambio de lienzo no rompa nada, la geometría que es regla —el
tejado de Asedio, el disco de la Tierra— pasó a medirse **desde el borde
inferior** en vez de desde arriba. La composición se ancla abajo, así que esas
cifras siguen valiendo aunque el lienzo crezca.

La única deformación que se permite es un **estirado vertical por debajo del
12%**, y solo cuando falta poco para cubrir. Sin él, en un 16:9 quedaba una
franja de azulejo del 9% justo encima del dibujo, y una franja delgada de otro
color no se lee como cielo: se lee como un error de montaje. Por encima de ese
umbral no se fuerza, porque ahí sí se nota aplastado.

Comprobado capturando tres biomas en 16:9, 20:9 y 4:3.
