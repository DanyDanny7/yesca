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
