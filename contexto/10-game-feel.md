# Game feel

Actualizado: 2026-08-30

Primera capa de sensación, ya con el juego corriendo en un teléfono real. No es
maquillaje: según `01-criterios-diseno.md` es donde vive lo pegajoso — dos
juegos con la misma mecánica, uno adictivo y otro muerto, se diferencian solo
aquí.

## Área de toque: de 60 a 30 px

Feedback jugando en el móvil: *"funciona bien en el cel, el área de touch
debería ser un 50% más pequeña, para aumentar algo la dificultad"*.

Los 60 px se calcularon para que el dedo no fuera el enemigo. En el teléfono
resultó demasiado indulgente: se acertaba sin mirar. A 30 px sigue siendo mayor
que el círculo (9 px de radio) pero ya exige apuntar, y de paso el margen de
fallos deja de ser decorativo.

**El simulador no puede medir esto**: su jugador apunta perfecto, así que la
tolerancia le da igual. Es una subida de dificultad que solo se comprueba con
el pulgar.

## Lo que se añadió

| Recurso | Qué hace |
|---|---|
| **Hit stop** | congela el mundo unos frames en cada eslabón |
| **Sacudida** | desplaza el campo, con tope y amortiguación |
| **Esquirlas** | siete fragmentos que adelantan al anillo y se encogen |
| **Sonido** | tono que sube con cada eslabón, más fallo, hito y final |
| **Vibración** | tap, fallo, hito de cadena y muerte |
| **Golpe de marcador** | escala el número en cada punto |

## Los tres errores que cazó la medición

**El hit stop no existía.** Estaba en 0.010 s por eslabón, que a 60 fps es menos
de un frame (16.7 ms): se consumía entero antes de dibujar nada. El test lo
pilló congelando **0 frames**. Lo habitual son 2-4 frames por impacto, de ahí
0.035 s. Ahora congela 6 frames en un eslabón.

**El hit stop regalaba tiempo.** Congelaba también el desagüe de la barra, así
que cada cascada larga era tiempo gratis: la supervivencia del jugador
descuidado subió de 98 s a 135 s solo por añadir el efecto. Un recurso visual no
debe repartir tiempo de juego. Ahora el reloj sigue corriendo durante el golpe —
sesenta milisegundos son imperceptibles, el regalo no lo era.

**La sacudida rompía la puntería.** El campo se desplaza hasta 20 px, pero el
tap se comparaba contra las posiciones sin desplazar: en plena cascada fallabas
taps que visualmente eran buenos. Ahora el dedo se lleva al sistema de
coordenadas del campo antes de buscar el círculo. Con la tolerancia a 30 px esto
habría sido muy visible.

## Decisiones

- **La sacudida escala con la longitud de la cadena.** Antes era idéntica en
  todos los eslabones, y eso es justo lo que impide sentir el choque: si el ×2
  mueve lo mismo que el ×10, el número sube pero la mano no se entera. Ahora va
  de 2.5 px en el primer eslabón a 6.7 px en el noveno, con un golpe extra de
  11 px en cada hito de cinco — que coincide con el sonido de premio, así que
  oído y tacto dicen lo mismo en el mismo instante.
- **El golpe se impone, no se suma.** Sumando impulsos, cuatro eslabones
  seguidos ya tocaban el tope y a partir de ahí un impacto mayor no movía nada:
  lo contrario de lo que se busca. Tomando el máximo, cada eslabón produce
  exactamente la sacudida que le toca por su longitud, y los pequeños no se
  apilan hasta convertir la pantalla en una batidora.
- **La sacudida mueve los contenedores del campo, no una cámara.** Así el HUD se
  queda quieto, que es lo correcto: sacudir los números los vuelve ilegibles
  justo cuando el jugador quiere leerlos.
- **Ocho voces de audio por turnos.** Con una sola, cada eslabón cortaría al
  anterior y la cascada sonaría a un único clic en vez de a una ráfaga.
- **El tono sube con cada eslabón.** Es el truco más viejo del género y sigue
  siendo el que más se nota: convierte una ráfaga de clics en una escala que
  sube, y da ganas de alargar la cadena solo por oírla.
- **La vibración solo en hitos**, no en cada contagio: vibrar en todos sería un
  zumbido continuo, y el motor háptico de Android no encola bien.
- **Las esquirlas se dibujan dentro de la propia detonación**, no como nodos
  aparte. Son siete círculos; un sistema de partículas traería basura de nodos
  en cada eslabón de cada cascada.

## Sonido sintetizado, no assets

Los cuatro efectos se generan con `tools/generar_audio.py`. Son cortos y
sintéticos, así que quedan versionados **como código** en vez de como binarios
opacos: cambiar el timbre es editar una fórmula, no volver a buscar un sample.

## Medición

Tras cerrar la fuga del hit stop, 2 partidas por perfil con tope de 150 s:

| Perfil | Sobrevive | Puntúa |
|---|---|---|
| Descuidado | ~86 s | ~252 |
| Bueno | 150 s (tope) | ~2424 |

Separación de 9.6x en puntuación. El perfil bueno ya no muere dentro del tope,
así que para volver a medir su techo habrá que alargarlo.

## La vibración no existía

Feedback: *"lo que sí no percibí fue la vibración, de ninguna forma"*.

`Input.vibrate_handheld()` **no hace nada en Android sin el permiso
`android.permission.VIBRATE`, y falla en silencio**: ni error, ni aviso, ni
excepción. El teléfono simplemente no vibra. Se generaron tres APK sin el
permiso antes de que nadie lo notara, y el `aapt2 dump permissions` del APK
salía con cero permisos declarados.

De paso apareció otra trampa: `ConfigFile` de Godot, que es lo que parsea
`export_presets.cfg`, usa `;` para comentar, **no `#`**. Un comentario con `#`
rompe el resto de la sección en silencio, así que la primera corrección tampoco
llegó a aplicarse.

## Música

Un bucle de 12 s generado por síntesis (`tools/generar_audio.py`), en Am–F–C–G
a 80 bpm, con bajo, pad y un pulso. Grave, de ataque lento y sin nada en la
banda de los efectos: los pops del juego son agudos y secos, y la música tiene
que caber por debajo sin pelearse.

La duración sale exacta a propósito (4 compases de 3 s) para que el bucle cierre
sin salto, y todas las envolventes mueren dentro de su compás, o al empalmar el
final con el principio se oiría un chasquido.

**El bucle se activa en código, no en el `.import`.** `edit/loop_mode=1` en el
archivo de importación no llega al recurso en esta versión de Godot: el
`.import` lo dice y el `AudioStreamWAV` cargado sigue reportando 0. Ponerlo en
código requiere que la pista se importe sin comprimir, o `data` no sería PCM
plano y la cuenta de fotogramas no saldría.

Está preparada **por bioma** desde ya: `_musica_de_bioma()` es un `match` con
una sola rama. Va como función y no como `const Dictionary` porque un
diccionario constante con recursos precargados dentro hace que Godot los libere
tarde.

## Opciones en la pausa

Tres interruptores — sonido, música y vibración — que se guardan en
`user://cadena.cfg` junto al progreso. Apagado se ve apagado: el círculo se
atenúa, porque un interruptor que no dice en qué estado está no es un
interruptor.

## Aviso conocido y benigno

Al cerrar en headless, Godot informa de dos instancias filtradas y un recurso
en uso. El `--verbose` es concluyente: son la pista de música y su
`AudioStreamPlaybackWAV`, vivas porque la música sigue sonando en el momento
del apagado. Es orden de destrucción, no una fuga real, y no afecta al juego en
el teléfono. Queda anotado para que nadie lo persiga otra vez.

## Pendiente

- Ajustar a oído en el teléfono: `shake_por_eslabon`, `hitstop_por_eslabon` y el
  volumen están en el inspector, grupo **Game feel**.
- El hit stop congela el 10% de los frames durante una cascada larga. Puede ser
  demasiado; se sabrá jugando.
- Falta el sonido de "pantalla limpia".
- **Sonido y música por bioma**: pedido explícitamente para más adelante. La
  música ya está estructurada para ello; los efectos de acción todavía no.
- Sigue sin haber icono propio de la app.
