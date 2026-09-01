# Fondos de los 17 biomas

Cada bioma en SVG y en PNG. **Usa el SVG si puedes**: son vectores planos, sin
degradados dentro de las formas, así que escalan a cualquier resolución sin
pesar más. Los PNG son 624×1008 por si el importador lo pide en mapa de bits.

    01_cielo_abierto      10_brasas
    02_invierno           11_caza_de_robots
    03_rio                12_circuito
    04_hormigas           13_ciudad_de_papel
    05_enjambre           14_ducha
    06_billar             15_fiesta
    07_panal              16_asedio
    08_estampida          17_lluvia_de_meteoros
    09_otono

## El aviso importante: la proporción

Están compuestos en **208×336**, que es 1:1.62. Tu pantalla de juego no es esa
proporción, y estos fondos **no se pueden estirar** para que encajen.

Cada uno tiene una parte que aguanta el estirado y otra que no:

- **Mosaico** (panal, circuito, estampida, enjambre, brasas): se repite. Estira
  todo lo que quieras, o mejor, hazlo un `TextureRect` en modo `tile`.
- **Marco y banda** (bañera de ducha, mesa de billar, ciudad de papel y asedio,
  nido de hormigas, bosque de otoño, la Tierra de meteoros): están anclados a un
  borde y **hay que anclarlos, no escalarlos**. Una bañera estirada al doble de
  ancho deja de ser una bañera.

Lo práctico es partir cada fondo en dos capas al importarlo: el mosaico como
textura repetida cubriendo la pantalla, y la pieza anclada como sprite en su
borde. En el SVG están separadas — el mosaico son los `<rect>` con `fill="url(#…)"`
del principio, la pieza anclada es todo lo que va después.

## Los valores

Todos los fondos van hundidos a propósito. La regla: **ninguna pieza del
escenario contrasta más contra su vecina que un objetivo contra el escenario.**
Si al meterlos en el juego un fondo compite con los puntos, baja el fondo, no
subas el punto.

Ducha es el único bioma claro. Ahí el anillo de la explosión tiene que llevar
contorno oscuro en vez de claro: sobre un fondo claro un anillo blanco no
existe. La regla no es «el anillo es blanco», es «el anillo contrasta contra su
fondo».

## Lo que no está

**El movimiento.** Varios mosaicos deben desplazarse: la nieve baja, las pavesas
suben, la corriente del río va a la derecha. Eso es un `offset` animado sobre la
textura repetida, y no puede ir dentro de un PNG.

**La estrella fugaz** de cielo abierto está dibujada quieta; en juego debería
cruzar de vez en cuando.

**Los misiles y meteoros cayendo** de Asedio y Lluvia de meteoros no están en el
fondo — son objetivos, y salen en `targets/`.

## Un par de decisiones que conviene conocer

Ciudad de papel y Asedio comparten literalmente los mismos edificios, y solo
cambia el cielo: de día a noche, con incendios en la base. Es deliberado — el
segundo se lee como consecuencia del primero, no como otro bioma parecido.

Caza de robots pasó de chapa remachada a rejilla en perspectiva violeta porque
en la primera versión se confundía con Estampida a distancia. Los separa el
color y la profundidad; el detalle fino no basta cuando los dos son cuadrícula
fría sobre azul oscuro.
