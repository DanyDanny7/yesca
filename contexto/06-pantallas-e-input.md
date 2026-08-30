# Pantallas e input

Actualizado: 2026-08-30

## El feedback que lo forzó

Jugando el v1: *"tiene su toque, pero no se entiende cuándo pierdes o cuándo
ganas. Terminé explotando todos y la pantalla quedó vacía un segundo pero el
juego siguió. También llené la barra superior y el juego siguió. Terminé
dejando que la barra cayera y el juego continuó."*

Tres síntomas del mismo problema — **el juego no comunicaba nada** — y uno de
ellos era un bug de verdad.

## El bug: la muerte era invisible

La partida **sí** terminaba: la lógica pasaba a estado DEAD correctamente, y la
simulación lo confirmaba con muertes a los 26 s y a los 185 s. Lo que fallaba es
que morir no se veía.

Cada punto mueve su propia posición en su `_process`, y al morir solo se
detenía la lógica de partida: la puntuación, el desagüe, los contagios. Los
puntos seguían rebotando tan tranquilos. El único aviso era una línea de texto
en medio de la pantalla, contra un campo que seguía animándose exactamente
igual que antes. Para el jugador, el juego simplemente continuaba.

Arreglo: al morir se congela el mundo entero con
`_dots_root.process_mode = PROCESS_MODE_DISABLED`.

## Lo demás que no comunicaba nada

- **Vaciar la pantalla no producía nada.** En un endless no existe "ganar", y
  limpiar el campo es lo más parecido que hay. Ahora da `clear_bonus` de tiempo
  y se anuncia.
- **Llenar la barra tampoco.** No es un objetivo, es tu vida — el excedente
  simplemente se descarta al llegar a `time_max`. Se etiquetó como "tiempo"
  para que deje de leerse como una barra de progreso.
- **El récord no sobrevivía a cerrar el juego.** Ahora se guarda en
  `user://cadena.cfg`. Sin un récord persistente el marcador no significa nada.

## El cambio de input: se toca un CÍRCULO

Propuesta del feedback, y es mejor diseño que la original:

> *"creí que la explosión salía únicamente cuando tocaba un círculo, pero veo
> que puedo ejecutarla yo al hacer click. Creo que funcionaría mejor que solo
> explote el círculo al tocarlo y que la onda expansiva sirva para destruir
> más."*

Detonar en cualquier punto de la pantalla es una acción **arbitraria**: apuntas
a un vacío y esperas. Tocar un círculo concreto es una acción **con puntería**,
y trae dos cosas:

- **El fallo se vuelve legible.** Tocaste al lado, no explotó nada, perdiste el
  tiempo del tap. Es el criterio número uno de `01-criterios-diseno.md`.
- **La habilidad se afila.** Ya no es "dónde hay hueco denso" sino "*qué*
  círculo tiene mejor vecindario", que es una decisión más concreta.

El riesgo es el dedo gordo: acertar a un círculo de 9 px en movimiento con un
dedo que tapa más de 50. Se resuelve con `tap_tolerance` generosa (60 px) y no
agrandando los puntos — la habilidad que queremos premiar es elegir el círculo,
no la precisión motriz.

El tap cuesta tiempo **acierte o no**. Si fallar fuese gratis se podría machacar
la pantalla hasta acertar y la puntería dejaría de ser una decisión.

## La regresión que trajo, y cómo se corrigió

Cambiar el input rompió la economía calibrada, porque al tocar un círculo el tap
descuidado **ya no puede fallar del todo**: siempre revienta al menos el círculo
que tocas. Medido justo después del cambio:

| Perfil | Antes (tocar pantalla) | Tras el cambio |
|---|---|---|
| Descuidado | 26 s · 37 pts | 75 s · 152 pts |
| Bueno | 185 s · 462 pts | 172 s · 430 pts |
| **Separación** | **7x · 12x** | **2.3x · 2.8x** |

El jugador descuidado casi triplicó su supervivencia y la brecha se hundió.

La corrección fue mover el premio del número de puntos a la **longitud de la
cadena**: `reward_base` de 0.6 a 0.4 y `reward_step` de 0.12 a 0.18. Así la
cascada corta es pérdida neta y solo la paciencia paga.

| Perfil | Sobrevive | Puntúa |
|---|---|---|
| Descuidado | ~48 s | ~87 |
| Bueno | ~169 s | ~421 |
| **Separación** | **3.5x** | **4.8x** |

No se recupera el 7x/12x original, y es un precio asumido: viene de que el
nuevo input garantiza al menos un acierto por tap. A cambio el juego es mucho
más legible, que es lo que se estaba comprando.

## Pantallas

**Inicio** — título, dos líneas de reglas, botón redondo grande al centro y el
récord. **Fin** — "SE ACABÓ EL TIEMPO", la puntuación en grande, si fue récord,
cuánto aguantaste, botón de reintentar, y además vale tocar en cualquier sitio
para no romper el reinicio instantáneo.

Los botones son `CircleButton`, un Control que se dibuja solo, **no un `Button`
de Godot**. El proyecto tiene `emulate_touch_from_mouse` activado para que el
mismo código de input sirva en editor y teléfono, y mezclarlo con el sistema de
foco y ratón de los Control es una fuente de rarezas que no compensa por un
botón. De paso, el botón se pulsa igual que se juega: tocando un círculo.

## Pendiente

- **La aceleración del desagüe sigue invisible.** Ves la barra bajar más rápido
  sin saber por qué. Material de v2 junto al resto del game feel.
- Nada de esto tiene todavía impacto, vibración, partículas ni sonido. La
  mecánica ya es legible; falta que se sienta.
