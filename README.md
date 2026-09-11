# Yesca

Yesca es el material que prende al primer roce y arde entero en un instante.
El nombre dice lo que hace el juego; la palabra *cadena*, que antes daba nombre
al proyecto, queda libre para significar solo lo que significa dentro: la
sucesión de estallidos que provoca un tap.

Juego móvil 2D para Android, hecho en Godot 4.7. Proyecto personal: el objetivo
es que sea divertido y pegajoso. Si lo consigue, se publica en Play Store con
publicidad; si no, se publica igual sin anuncios.

**El concepto.** Puntos flotando por la pantalla. Tocas uno: explota, y
su onda expansiva contagia a los vecinos, que explotan a su vez en cascada. Una
barra de tiempo baja sin parar; tocar cuesta tiempo, atrapar devuelve tiempo, y
tanto el tiempo como los puntos crecen con la longitud de la cadena. Cada tap es
una apuesta entre detonar ya o esperar a que se junten más.

## Estado

**Fase v5** — dos modos. **Campaña**: ocho niveles con objetivo, que es donde
vive el cierre (un juego de supervivencia no tiene victoria por naturaleza; para
que exista un "ganaste" la partida tiene que ser finita). **Sin fin**: la caza
del récord.

Siete reglas de movimiento (rebote, abeja, nieve, choque, corriente, enjambre,
huida) que son el cimiento de los biomas, con un nivel por regla para probarlas.
Primera capa de game feel: hit stop, sacudida, esquirlas, sonido y música
sintetizados, y vibración. Opciones de sonido, música y vibración desde la
pausa. Corriendo ya en un teléfono real. Ver `contexto/08-campana.md`,
`contexto/09-movimientos.md` y `contexto/10-game-feel.md`.

## Cómo correrlo

```powershell
.\jugar                  # juega y relanza a cada cambio
.\jugar 12               # ... entrando de una en el nivel 12
.\jugar derrota          # ... con esa pantalla a la vista
.\jugar 12 -SinMorir     # el nivel 12 sin que te maten mientras miras
.\jugar 12 -Una          # una sola ejecución, sin vigilante
```

Deja esa terminal al lado mientras se edita: avisa de qué archivo cambió y
vuelve a arrancar el juego con ese cambio dentro, sin tocar nada. Los `print()`
y los errores del motor salen ahí mismo.

El argumento dice **dónde caer**, y existe para no repetir los clics del menú en
cada reinicio: retocar algo del nivel 12 obligaba a cruzar menú → campaña → doce
flechas → jugar → briefing en cada arranque. Acepta dos cosas:

- **Un número de nivel**, contando desde 1, como los enseña el juego: `.\jugar 12`.
- **El nombre de una pantalla**, de esta lista:

| nombre | qué deja a la vista |
| --- | --- |
| `menu` | el menú principal |
| `seleccion` | el selector de nivel de la campaña |
| `briefing` | la tarjeta con el objetivo del nivel |
| `listo` | el campo montado, esperando el primer toque |
| `jugando` | la partida en marcha |
| `pausa` | la pantalla de pausa y sus opciones |
| `derrota` | el resultado tras perder |
| `victoria` | el resultado tras superar el nivel |
| `final` | el cierre de campaña completa |
| `log` | el registro de la sesión anterior |

Las que enseñan datos de partida —`derrota`, `victoria`, `pausa`— montan una
antes de mostrarse: sin ella salían con los marcadores vacíos y parecía un fallo
del juego. Se pueden combinar con el nivel: `.\jugar derrota -Nivel 5`.

Son los mismos nombres que salen en el registro (`pantalla=derrota`), y a
propósito: mantener una segunda lista de nombres es mantener una que se queda
vieja. Todo esto solo funciona en compilación de depuración; en una de
publicación no hace nada, pase lo que pase por la línea de comandos.

No hay recarga en caliente porque el hot reload de GDScript solo funciona cuando
quien lanza el juego es el editor de Godot. Desde una terminal, reiniciar es la
única forma fiable de ver el cambio — y este proyecto arranca en un segundo.

Debajo siguen los lanzadores de siempre:

```powershell
.\tools\run.ps1              # ejecuta el juego
.\tools\run.ps1 -Editor      # abre el editor
.\tools\run.ps1 -Calibrar    # banco de calibración headless
.\tools\vigilar.ps1          # el vigilante, con -Nivel / -Pantalla / -SinFin / -SinMorir
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
- `scripts/main.gd` — bucle, input, detección de contagios, escalones de
  dificultad y máquina de estados de pantallas.
- `scripts/niveles.gd` — la campaña como tabla de datos: un nivel es un
  objetivo más un escalón de partida, no contenido dibujado a mano.
- `scripts/dot.gd` — un círculo y sus reglas de desplazamiento. No mueve su
  posición solo: lo dirige `main.gd`, porque hay modos que necesitan ver a los
  demás círculos o a las detonaciones.
- `scripts/explosion.gd`, `scripts/circle_button.gd` — nodos que se dibujan
  solos con `_draw()`. Sin sprites ni escenas: para formas geométricas no hacen
  falta.
- `scripts/arte.gd` — carga de assets intercambiables. Si existe el fichero
  manda el fichero; si no, se dibuja como siempre. El dibujo procedural no
  desaparece, pasa a ser el respaldo. Ver `contexto/13-arte-intercambiable.md`.
- `arte/targets/` y `arte/fondos/` — donde se dejan los PNG (o SVG) que
  sustituyen formas y mosaicos. Vacías de serie: el juego arranca igual.
- `audio/` — los efectos y la música, generados por síntesis con
  `tools/generar_audio.py`. Se versionan como código, no como binarios opacos:
  cambiar el timbre es editar una fórmula.
- `tools/` — utilidades de desarrollo, fuera del juego. `calibracion.gd` mide
  el reparto de cadenas; `simulacion.gd` juega partidas enteras con dos
  perfiles de jugador para ver si la economía separa el juego bueno del malo.
  Ninguno mide diversión. `exportar_arte.gd` vuelca todo el arte procedural a
  PNG en `arte_exportado/`, para tener de dónde partir al dibujar:

      godot --path . --script tools/exportar_arte.gd

  Tiene que correr con ventana, no en headless: los targets se capturan
  renderizando de verdad.

## Antes de publicar

- [ ] **`todos_los_niveles` a false** en el inspector de `Main`, grupo Pruebas.
      Está en true para poder testear cualquier bioma sin superar la campaña, y
      con eso encendido no existe progresión: se entra al nivel 31 desde el
      primer arranque y se pierde la curva entera.
- [ ] Icono propio de la app (ahora sale el de Godot).

## Android

```powershell
.\tools\build-apk.ps1            # APK de depuración en build/
.\tools\build-apk.ps1 -Release   # APK de publicación
```

El script exporta y **verifica la firma**: un APK sin firmar se genera igual y
solo falla al instalarlo en el teléfono, que es el peor momento para enterarse.

Estado actual: `com.cadena.juego`, minSdk 24 (Android 7+), solo arm64-v8a,
~27 MB. Sin icono propio todavía, así que sale el de Godot por defecto.

### Diagnosticar un cierre en el teléfono

```powershell
.\tools\capturar-crash.ps1     # conecta el móvil por USB, reproduce el fallo, Ctrl+C
```

Un cierre que solo pasa en el móvil no se diagnostica adivinando: hace falta el
log. El script deja el volcado en `build/crash.txt`.

### Montar el entorno (una sola vez)

```powershell
winget install Microsoft.OpenJDK.17     # el export pide 17, no vale el 21
winget install Google.AndroidCLI
android sdk install platform-tools "build-tools;35.0.0" "platforms;android-35" "cmdline-tools;latest"
```

Después, keystore de depuración con el `keytool` del JDK 17:

```powershell
keytool -keyalg RSA -genkeypair -alias androiddebugkey -keypass android `
  -keystore "$env:APPDATA\Godot\keystores\debug.keystore" -storepass android `
  -dname "CN=Android Debug,O=Android,C=US" -validity 9999 -deststoretype pkcs12
```

Y en `%APPDATA%\Godot\editor_settings-4.7.tres` hay que dejar
`export/android/java_sdk_path` apuntando al **JDK 17** — Godot autodetecta el
más nuevo que encuentre, que aquí era el 21 y no sirve.

Faltan las plantillas de exportación (1.28 GB): `Editor → Gestionar plantillas
de exportación` en el editor, o descargando el `.tpz` de la release de Godot y
extrayendo su carpeta `templates/` en
`%APPDATA%\Godot\export_templates\4.7.2.stable\`.
