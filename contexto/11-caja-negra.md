# Caja negra

Actualizado: 2026-08-30

## El problema

La app se cierra sola en el teléfono, alrededor de los 200 puntos. En PC no
ocurre nunca. Sin el registro de Android no hay diagnóstico posible, y llegar a
él exige cable y `adb`, que no siempre se tiene a mano.

## RESUELTO: era el renderizador

La caja negra dio la respuesta a la primera vez que se usó. Línea de arranque:

```
gpu=ANGLE ((Samsung Xclipse 540) on Vulkan 1.3.279)  driver=OpenGL ES 3.2
```

El teléfono de pruebas es un Galaxy A56 con GPU **Samsung Xclipse 540**, que no
tiene OpenGL nativo: Android le sirve OpenGL ES **traducido a Vulkan mediante
ANGLE**. Y `00-decisiones.md` había elegido `gl_compatibility` precisamente por
ser "lo seguro en gama baja".

O sea que el juego corría sobre OpenGL emulado sobre Vulkan, una capa de
traducción con mala fama justo en esas GPU.

El resto del registro confirma que no era carga ni fuga:

```
12.14  pts=35 exp=4 cad=2 lbl=2 fps=60.0 nodos=126 memMB=61.7
```

**60 fps clavados, memoria plana, 126 nodos, y se cierra.** A los 12 segundos y
35 puntos, no a los 200 de la primera vez. Sin picos, sin degradación, sin nada
que anticipe el corte: la firma de un fallo nativo de la capa gráfica, no de
nada que el juego estuviera haciendo mal.

**Arreglo:** `renderer/rendering_method = "mobile"` (Forward Mobile, Vulkan
nativo). Se habla Vulkan directamente y ANGLE desaparece de la ecuación.

Dos consecuencias asumidas:

- Vulkan pasa a ser obligatorio, así que quedan fuera dispositivos muy antiguos
  con solo OpenGL ES. A cambio funciona en el teléfono real que tenemos delante.
- Escritorio y móvil usan ahora el **mismo** renderizador. Tenerlos distintos
  significaba que lo probado en el PC no era lo que corría en el teléfono, y esa
  divergencia costó tres builds y varias horas persiguiendo la vibración, el
  audio y la sacudida.

### Lo que la caza en falso enseñó

Antes de tener el registro se sospechó, por orden: fuga de memoria, vibración,
frecuencia de audio y sacudida de pantalla. Las cuatro eran razonables y las
cuatro estaban equivocadas. **La primera línea del log valía más que todas las
horas de conjetura**, y el log costó una tarde de escribirlo.

## Lo que se descartó por el camino

**No es una fuga de memoria.** Medido con 40 000 frames y varios miles de puntos
acumulados: nodos entre 108 y 129, cero huérfanos, memoria estable en 40-44 MB, y
cadenas, etiquetas y pool todos acotados. Si algo creciera sin control, el
teléfono lo notaría antes que el PC — pero no crece.

## El sospechoso principal

Este es el primer build en el que **la vibración funciona de verdad**: hasta
ahora faltaba el permiso y `Input.vibrate_handheld()` era un no-op silencioso.
En una cascada larga se llamaba decenas de veces por segundo, y cada llamada
cruza al servicio de vibración de Android. En PC no se nota porque allí no hace
nada. Se le puso un tope de unas ocho por segundo.

Se confirma o se descarta en una sola partida: apagar VIBRAR desde la pausa.

## La caja negra

Como el teléfono no tiene consola a la vista, el juego se registra a sí mismo.

- `Diagnostico` escribe migas de pan a `user://sesion.log` **volcando en cada
  línea**. Eso es lo único que garantiza que lo escrito sobreviva a un cierre
  brusco: sin el volcado, el buffer se pierde justo cuando más falta hace.
- Al arrancar, el registro anterior se copia aparte y se lee desde el propio
  juego. Si no contiene la marca `CIERRE LIMPIO`, esa sesión se fue sin avisar.
- Cada segundo de partida se anota una instantánea: puntos, escalón,
  movimiento, círculos, detonaciones, cadenas, etiquetas, pool, sonidos y
  vibraciones desde la última foto, FPS, nodos y memoria.
- Se anotan además los eventos: inicio de partida, cambio de escalón, victoria,
  derrota con motivo, y arranque de música.
- Al inicio se registra modelo del teléfono, versión de Android, GPU y driver.

**También se lee el registro del propio motor** (`user://logs/godot.log`,
activado ahora explícitamente para móvil en `project.godot`). Es la mitad que
faltaba: la caja negra solo ve lo que el juego decide anotar, mientras que ahí
caen los errores de script y del motor, que son los que suelen tumbar el
proceso. Si hay alguno, se muestra **arriba del todo**, porque pesa más que
cualquier instantánea.

## Cómo se lee

Botón **LOG** en la esquina inferior derecha del menú principal. Se pone
**rojo** cuando la sesión anterior murió sin avisar — si no, el registro estaría
ahí y nadie lo miraría nunca.

## Verificado

Matando el proceso con SIGKILL a mitad de partida:

- el registro sobrevive con datos hasta el último segundo
- la siguiente sesión detecta el cierre brusco
- el botón LOG sale en rojo
- un cierre normal deja la marca y el botón gris

## Si hace falta el registro completo

`tools/capturar-crash.ps1` con el teléfono por USB. Da el volcado nativo de
Android, que es más de lo que el juego puede ver de sí mismo.
