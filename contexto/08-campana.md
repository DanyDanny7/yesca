# Campaña

Actualizado: 2026-08-30

## La pregunta

*"Ahora tenemos el final al llegar la barra a 0, pero ¿cuándo ganamos? Ahorita
está en un concepto de supervivencia — lo que aguantes — pero necesitamos darle
un cierre."*

## La respuesta

Un juego de supervivencia **no tiene victoria por naturaleza**. Flappy Bird,
Tetris moderno, cualquier endless: solo tienen récord. Para que exista un
"ganaste", la partida tiene que ser **finita**. De ahí salen los niveles.

Dos modos:

- **Campaña** — cada nivel tiene un objetivo; se gana o se pierde. Aquí vive el
  cierre.
- **Sin fin** — lo que ya había, la caza del récord. Aquí vive la retención.

Es la estructura estándar del móvil, y por buenos motivos: la campaña enseña el
juego y da satisfacción de cierre, el modo libre da razones para volver.

## Los niveles son datos, no contenido

`00-decisiones.md` descartó los géneros con hambre de contenido: nada de
producir cuarenta niveles a mano. Una campaña parecía chocar con eso, y no
choca, porque aquí **un nivel es una fila de una tabla**: un objetivo, un
escalón de partida y una pista. Añadir un nivel cuesta una línea en
`scripts/niveles.gd`, no una tarde de arte.

Técnicamente, el nivel solo impone `_stage_offset`, que desplaza el escalón
inicial dentro del sistema de dificultad que ya existía. No hay un segundo
sistema de balance que mantener.

## La variedad sale del objetivo, no de los números

Ocho niveles con "llega a N puntos" y N creciendo es relleno. Lo que hace que
un nivel se sienta distinto es que pida **otra habilidad** del mismo mecanismo:

| Objetivo | Qué habilidad pide |
|---|---|
| `PUNTOS` | ritmo general |
| `CADENA` | paciencia: esperar el cluster y no cortar la cascada |
| `LIMPIAS` | lectura del campo entero |
| `SEGUNDOS` | supervivencia pura, sin puntuar |
| `PUNTOS_LIMPIOS` | puntería: un solo fallo y se acabó |

Los ocho primeros están ordenados para enseñar **una cosa cada uno**: tocar,
buscar un grupo, aprovechar el multiplicador, vaciar, no cortar la cadena,
aguantar, no fallar, y por último maestría con el campo rápido.

## Detalles de diseño

**La victoria se comprueba antes que la derrota.** Si el último eslabón de una
cascada cumple el objetivo justo cuando la barra llega a cero, ganas. Es lo
justo, y produce finales memorables.

**El campo sigue vivo detrás del menú y de la selección.** Una pantalla de
inicio con el juego moviéndose detrás se siente despierta, y de paso enseña la
mecánica antes de que el jugador toque nada.

**Progreso persistente** en `user://cadena.cfg`: récord del modo sin fin y
nivel más alto desbloqueado. Se puede volver a cualquier nivel ya superado.

## Lo que falta, y por qué no está

**Los biomas.** Deliberadamente solo hay un bioma, "Campo abierto", con el
comportamiento base. Añadir un segundo bioma ahora significaría cambiar paleta y
subir números, y eso es exactamente el relleno que se quería evitar.

Un bioma tiene que ser una **regla**, no una paleta: círculos que aceleran al
pasar cerca de una explosión, que huyen de la onda, que se dividen al reventar,
que se atraen entre sí. Cada regla cambia cómo se lee el campo y cómo se planea
la cadena, y ahí sí ocho niveles nuevos son ocho problemas nuevos. Es la
siguiente conversación.

**Estrellas por nivel.** Repetir un nivel para hacerlo mejor es retención
barata y no toca el balance. Pendiente.

**Game feel.** Sigue sin haber impacto, vibración, partículas ni sonido. Es lo
único de la lista que ya debería estar hecho.
