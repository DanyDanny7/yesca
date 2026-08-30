# Conceptos

Estado: **elegido A**. Ver `03-concepto-cadena.md` para la especificación.
B queda congelado, no descartado.

---

## ELEGIDO — Cadena

Pantalla llena de puntos flotando. Un solo tap en toda la partida: se detona
donde se toca, la explosión se expande y todo lo que alcanza explota también,
en cascada. Score = cuántos se atrapan.

La habilidad es leer el movimiento de los puntos y elegir el instante y el
lugar exactos. Partida de ~15 segundos.

- **Arte:** círculos, glow, un color por estado. Prácticamente cero producción.
- **Fortaleza:** el más satisfactorio de programar y el que más rápido se
  siente bien. Riesgo técnico bajo.
- **Riesgo:** el concepto base ya existe (Boomshine, 2007) y el gancho se
  puede agotar. Necesita una vuelta propia — variantes de partícula, alguna
  decisión adicional del jugador, o una razón para volver.
- **Resuelto:** la vuelta propia es la barra de tiempo como única economía —
  tocar cuesta, atrapar devuelve. Convierte cada tap en una apuesta y añade el
  fin de partida que al concepto original le faltaba. Ver `03-concepto-cadena.md`.
- ~~**Pendiente:** encontrar esa vuelta propia. Sin ella no es un juego, es una
  demo.~~

---

## CONGELADO — Rotar el mundo

El personaje corre solo, siempre hacia adelante, y nunca se le controla. Lo
que se controla es el nivel: un swipe y todo rota 90°, la gravedad cambia,
lo que era pared pasa a ser piso. Endless procedural. Score = distancia.

- **Arte:** geométrico plano, siluetas. También barato.
- **Fortaleza:** el más original de los dos, y el gancho se lee al instante.
  Técnicamente el más interesante: generar terreno que siempre sea resoluble
  tras cualquier rotación es un problema real y entretenido.
- **Riesgo:** la legibilidad visual al rotar puede ser un infierno —
  desorientación, mareo, y que el jugador no entienda por qué murió. Choca de
  frente con el criterio "la muerte es legible". Es el riesgo a matar primero
  en el prototipo.
- **Mitigaciones ya pensadas** para cuando se retome. La legibilidad no se
  arregla puliendo, se arregla con estas cuatro decisiones de diseño:
  1. **Rota el mundo, no la cámara.** El personaje se queda siempre vertical y
     en el mismo punto de la pantalla. Si el que se voltea es el jugador, el
     ojo se pierde.
  2. **Pasos discretos de 90°**, nunca rotación libre, con un tween corto y
     eased (~0.15 s).
  3. **Slow-motion durante la rotación.** Da tiempo a releer el terreno y de
     paso convierte el momento de rotar en el momento estrella.
  4. **Paleta por función, no por orientación.** Lo sólido siempre del mismo
     color, se mire como se mire.

---

## DESCARTADO — Timing / tempo

Enemigos avanzando en fila, tap en el momento exacto, deriva a juego de ritmo.
Descartado: no motiva al desarrollador. Era el de menor riesgo pero eso no
compensa trabajar meses en algo que no interesa.

---

## Cómo se decidió

Se descartó tempo por falta de motivación. Entre A y B se eligió A por ser el
camino más corto a tener algo jugable, y porque el trabajo de game feel que
exige no se pierde: es exactamente el que haría falta para B más adelante.

B no está muerto. Su problema abierto sigue siendo la legibilidad al rotar, y
las cuatro decisiones que lo mitigan quedan anotadas arriba para cuando toque.

Regla que se mantiene: lo pegajoso no se decide en papel, se descubre con el
pulgar y en el teléfono real, nunca con teclado y mouse.
