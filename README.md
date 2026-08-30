# juego-test-1

Nombre provisional. Se renombra cuando el concepto esté validado.

Juego móvil 2D para Android, hecho en Godot 4.7. Proyecto personal: el objetivo
es que sea divertido y pegajoso. Si lo consigue, se publica en Play Store con
publicidad; si no, se publica igual sin anuncios.

**Concepto — Cadena.** Puntos flotando por la pantalla. Tocas uno: explota, y
su onda expansiva contagia a los vecinos, que explotan a su vez en cascada. Una
barra de tiempo baja sin parar; tocar cuesta tiempo, atrapar devuelve tiempo, y
tanto el tiempo como los puntos crecen con la longitud de la cadena. Cada tap es
una apuesta entre detonar ya o esperar a que se junten más.

## Estado

**Fase v3** — curva de dificultad por escalones, multiplicador de cadena que
puntúa (el punto N de una cascada vale N) y medidor de fallos consecutivos.
Falta todo el game feel: impacto, vibración, partículas, sonido. Ver
`contexto/07-escalones-y-combo.md` y `contexto/03-concepto-cadena.md`.

## Cómo correrlo

```powershell
.\tools\run.ps1              # ejecuta el juego
.\tools\run.ps1 -Editor      # abre el editor
.\tools\run.ps1 -Calibrar    # banco de calibración headless
```

El lanzador encuentra Godot solo. Existe porque una terminal abierta antes de
instalar Godot hereda el PATH viejo y `godot` no se resuelve aunque la entrada
ya esté en el registro — reabrir VSCode lo arregla, pero el script funciona
igual sin tener que acordarse.

Con `godot` ya en el PATH, el equivalente directo es:

```sh
godot --path .            # ejecuta
godot -e --path .         # abre el editor
godot --headless --path . --script res://tools/calibracion.gd
```

En el editor, los parámetros de calibración están como `@export` en el nodo
`Main`: se pueden mover desde el inspector con el juego corriendo.

## Estructura

- `contexto/` — decisiones, criterios e iteraciones de diseño. Es la memoria
  del proyecto: se lee antes de tocar código.
- `main.tscn` — escena principal, con los contenedores de puntos y
  detonaciones más la UI.
- `scripts/main.gd` — bucle, input, detección de contagios y estado de ronda.
- `scripts/dot.gd`, `scripts/explosion.gd`, `scripts/circle_button.gd` — nodos
  que se dibujan solos con `_draw()`. Sin sprites ni escenas: para formas
  geométricas no hacen falta.
- `tools/` — utilidades de desarrollo, fuera del juego. `calibracion.gd` mide
  el reparto de cadenas; `simulacion.gd` juega partidas enteras con dos
  perfiles de jugador para ver si la economía separa el juego bueno del malo.
  Ninguno mide diversión.

## Pendiente de entorno

El export a Android pide **JDK 17** y en la máquina hay JDK 21. Habrá que
instalar el 17 en paralelo antes de la primera build. Tampoco está el Android
SDK todavía.
