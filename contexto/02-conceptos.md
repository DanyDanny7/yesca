# Conceptos

Estado: dos candidatos vivos. Se deciden prototipando, no en papel.

---

## CANDIDATO A — Cadena

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
- **Pendiente:** encontrar esa vuelta propia. Sin ella no es un juego, es una
  demo.

---

## CANDIDATO B — Rotar el mundo

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
- **Pendiente:** decidir si rota la cámara o el mundo (no es lo mismo para el
  ojo), y si la rotación es libre o en pasos discretos de 90°.

---

## DESCARTADO — Timing / tempo

Enemigos avanzando en fila, tap en el momento exacto, deriva a juego de ritmo.
Descartado: no motiva al desarrollador. Era el de menor riesgo pero eso no
compensa trabajar meses en algo que no interesa.

---

## Cómo se decide

Lo pegajoso no se decide en el concepto, se descubre con el pulgar. Ninguno
de los dos se puede evaluar en papel.

Plan: prototipar los dos, un fin de semana cada uno. Cubos grises, cero arte,
cero menús, cero meta-progresión. Solo la mecánica corriendo en el teléfono
real — nunca juzgar un juego móvil con teclado y mouse.

Criterio de decisión: cuál de los dos no se puede soltar a los cinco minutos.
El otro se descarta sin pena, porque no se invirtió nada.

Riesgo a matar en cada prototipo:
- **A:** ¿hay decisión interesante, o es solo suerte y espectáculo?
- **B:** ¿se entiende lo que pasa al rotar, o marea y frustra?
