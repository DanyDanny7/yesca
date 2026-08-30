# Concepto elegido: Cadena

Estado: **elegido**, pendiente de validar con prototipo.
Actualizado: 2026-08-30

## Pitch

Puntos flotando por la pantalla. Tocas: detonas una explosión que se expande,
y todo punto que alcanza explota también, en cascada. Una barra de tiempo baja
sin parar; tocar cuesta tiempo, atrapar puntos devuelve tiempo. Llega a cero y
se acabó.

Score = puntos atrapados en total.

## La regla que sostiene todo

Una sola economía: **tiempo**.

- La barra baja constantemente
- Cada tap **cuesta** tiempo
- Cada punto atrapado **devuelve** tiempo, escalando con la longitud de la cadena
- Barra a cero = fin de partida

De ahí sale la única decisión del juego, y se repite cada pocos segundos:
*¿detono ahora este grupo de 3, o aguanto a que ese de 8 se junte?*
La avaricia mata igual que la cobardía. Eso es lo que lo separa de Boomshine,
que es por niveles, de un solo tap y sin presión.

## Por qué cumple los criterios

Contrastado contra `01-criterios-diseno.md`:

- **Muerte legible:** siempre es "gasté taps en nada". Nunca es culpa del juego.
- **Techo de habilidad:** leer trayectorias y predecir dónde va a haber densidad
  en un segundo y medio. Mejora muchísimo con práctica y no depende del azar.
- **Dificultad creciente dentro de la partida:** basta subir la velocidad de los
  puntos y bajar la densidad con el tiempo. Cero contenido que producir.
- **Endless con score:** sin niveles, sin progresión que diseñar.
- **Reinicio en un tap:** no hay estado que cargar.
- **Arte:** círculos, glow y un color por estado. Producción nula.

## Plan de implementación por fases

No implementar todo junto. Cada fase se juega antes de pasar a la siguiente.

**v0 — ¿se siente bien?**
Puntos moviéndose y rebotando, tap, explosión que se expande, cascada.
Sin barra, sin score, sin muerte. Solo la cascada. Si esto no es satisfactorio
al tacto, el concepto se cae y no vale la pena seguir.

**v1 — ¿hay juego?**
Se añade la barra de tiempo, el costo por tap, la recompensa por cadena y el
fin de partida. Aquí es donde se descubre si existe la tensión de la apuesta o
si es trivial. Es la fase que decide el proyecto.

**v2 — game feel.**
Hit stop, screen shake, partículas, háptica, sonido con variación de pitch,
easing. Sin tocar la mecánica. Aquí es donde un prototipo aburrido se vuelve
adictivo, o se confirma que no lo era.

**v3 — sesión completa.**
Récord persistente, reinicio instantáneo, curva de dificultad, primera build
en el teléfono.

Recién después: monedas, skins, anuncios. Nada de eso antes de que v2 enganche.

## Valores iniciales para tunear

Todo `@export` para ajustar en vivo desde el editor. Son puntos de partida,
no verdades:

| Parámetro | Valor inicial |
|---|---|
| Barra inicial / máxima | 10 s / 15 s |
| Costo por tap | 1.5 s |
| Recompensa por punto | 0.6 s, escalando con la cadena |
| Puntos en pantalla | ~25 |
| Velocidad de punto | 60-140 px/s |
| Radio de explosión | ~90 px |
| Vida de explosión | 1.2 s (0.3 crece / 0.6 sostiene / 0.3 decae) |

## Riesgos abiertos

- **Que la cascada sea espectáculo y no decisión.** Se detecta en v1: si el
  jugador puede tocar a lo loco y sobrevivir, la economía está mal calibrada.
- **Legibilidad con 25 puntos en una pantalla de teléfono.** Puede necesitar
  menos puntos, o que los que ya están "cargados" se distingan claramente.
- **Que el dedo tape la zona de interés** justo al tocar.
