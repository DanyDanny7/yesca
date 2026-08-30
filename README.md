# juego-test-1

Nombre provisional. Se renombra cuando el concepto esté validado.

Juego móvil 2D para Android, hecho en Godot 4.7. Proyecto personal: el objetivo
es que sea divertido y pegajoso. Si lo consigue, se publica en Play Store con
publicidad; si no, se publica igual sin anuncios.

**Concepto — Cadena.** Puntos flotando por la pantalla. Tocas: detonas, la
explosión se expande y todo punto que alcanza explota también, en cascada. Una
barra de tiempo baja sin parar; tocar cuesta tiempo, atrapar devuelve tiempo.
Cada tap es una apuesta entre detonar ya o esperar a que se junten más.

## Estado

**Fase v0** — solo la cascada, para responder si se siente bien al tacto. Sin
barra de tiempo, sin récord, sin derrota. Ver `contexto/03-concepto-cadena.md`
para el plan v0-v3.

## Cómo correrlo

```sh
godot --path .            # abre el proyecto y ejecuta
godot -e --path .         # abre el editor
```

En el editor, los parámetros de calibración están como `@export` en el nodo
`Main`: se pueden mover desde el inspector con el juego corriendo.

Banco de calibración (mide reparto de cadenas, no diversión):

```sh
godot --headless --path . --script res://tools/calibracion.gd
```

## Estructura

- `contexto/` — decisiones, criterios e iteraciones de diseño. Es la memoria
  del proyecto: se lee antes de tocar código.
- `main.tscn` — escena principal, con los contenedores de puntos y
  detonaciones más la UI.
- `scripts/main.gd` — bucle, input, detección de contagios y estado de ronda.
- `scripts/dot.gd`, `scripts/explosion.gd` — nodos que se dibujan solos con
  `_draw()`. Sin sprites ni escenas: para formas geométricas no hacen falta.
- `tools/` — utilidades de desarrollo, fuera del juego.

## Pendiente de entorno

El export a Android pide **JDK 17** y en la máquina hay JDK 21. Habrá que
instalar el 17 en paralelo antes de la primera build. Tampoco está el Android
SDK todavía.
