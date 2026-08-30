# Calibración v0

Actualizado: 2026-08-30
Medido con `tools/calibracion.gd`.

## El problema que apareció antes de jugar nada

Con los valores iniciales de `03-concepto-cadena.md` (25 puntos, radio 90 en
720x1280), una explosión cubre el 2.8% de la pantalla. El tap inicial atraparía
**~1.3 puntos de media**: la mayoría de las partidas arrancarían con 0 o 1 y no
encadenarían nada. El juego se sentiría muerto.

Subir la densidad no lo arregla, lo invierte: con más puntos la distancia media
entre vecinos cae por debajo del radio de cadena (~96 px con 25 puntos) y la
propagación se vuelve automática. Se pasa de "no pasa nada" a "pasa todo sin
mérito", y en ninguno de los dos casos hay juego.

## La decisión: radio asimétrico

La detonación del **jugador** tiene un radio mayor que las detonaciones **en
cadena**:

- `tap_radius = 150.0`
- `chain_radius = 90.0`

Así el primer tap casi siempre produce algo, pero la propagación sigue
dependiendo de que el jugador haya encontrado densidad real. Es lo que separa
tocar de tocar *bien*.

## Medición

25 tandas por modo, densidad equivalente al campo real:

| Tap | Media | Mediana | Ceros | Máx |
|---|---|---|---|---|
| Al azar | 4.4 | 4 | 4/25 (16%) | 11 |
| Al mejor cluster | 7.6 | 8 | 0/25 | 10 |

Lectura:

- **Brecha de habilidad ~1.7x**, y en realidad mayor: la heurística "al mejor
  cluster" solo mira la foto actual, mientras que un jugador real además
  predice hacia dónde van a converger los puntos en el próximo segundo. Ese
  margen de predicción es el techo de habilidad de verdad.
- **16% de taps al azar atrapan cero.** No es un defecto: es el castigo al tap
  descuidado, y es exactamente lo que hará morder la economía de tiempo en v1.
- **Jugando bien nunca se saca cero.** La habilidad se nota.
- Las cascadas se quedan en ~10 de 44. No hay barridos de tablero completo, así
  que queda techo de sobra para que v1 escale.

## Pendiente para v1

- **¿La barra de tiempo baja durante la cascada?** Si baja, una cadena larga se
  castiga a sí misma con el tiempo que tarda en resolverse. Si no baja, la
  cascada es un descanso gratis. Probablemente haya que congelarla o ralentizar
  su caída mientras haya detonaciones vivas. Decidir midiendo, no a ojo.
- **Cuánto tiempo devuelve cada punto.** Con media de 4.4 al azar y 7.6 jugando
  bien, la recompensa tiene que estar calibrada para que el tap descuidado sea
  neta pérdida y el tap bueno neta ganancia. Ese es el punto exacto donde nace
  la tensión — o donde el juego se vuelve trivial.

## Nota sobre el banco de pruebas

`tools/calibracion.gd` mide reparto de cadenas, no diversión. Sirve para
descartar configuraciones rotas rápido, no para elegir la buena. La elección
final de cada número es con el pulgar y en el teléfono.
