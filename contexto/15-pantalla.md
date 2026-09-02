# 15 · La pantalla

Inventario de todo lo que aparece en pantalla y **por qué está ahí**. Un elemento
de interfaz que no responde a una pregunta del jugador es ruido, y en un juego
que se juega con un pulgar el ruido cuesta caro: tapa el campo.

## Las tres capas

El orden importa y no es negociable:

| Capa | Nodo | Qué lleva |
|---|---|---|
| Fondo | `Fondo` (Node2D) | El telón en mosaico, la banda y el marco. Una sola llamada de dibujo. |
| Juego | `Dots`, `Explosions` (Node2D) | Los objetivos y las ondas. **Es la única capa que se sacude**: el temblor mueve estos contenedores, nunca la interfaz. |
| Interfaz | `UI` (CanvasLayer) | Todo lo demás. Va en `CanvasLayer` para quedar inmune al temblor y a la cámara. |

Que el temblor no toque la interfaz no es un detalle estético. La primera versión
sacudía la pantalla entera y el toque se comparaba contra posiciones sin sacudir:
apuntabas a un sitio y tocabas otro. Ahora el toque se traduce restando el
desplazamiento del contenedor.

---

## Durante la partida

Once elementos, y ni uno más. Se ocultan todos a la vez al terminar.

### La barra de tiempo — `BarBg` + `BarFill`

Arriba del todo, a lo ancho. **Es la economía entera del juego**: baja sin parar,
tocar cuesta tiempo y atrapar devuelve tiempo. No hay marcador de vidas ni de
munición porque no hacen falta: todo se paga con la misma moneda.

Por debajo de ella hay **150 px reservados** donde no vive ningún objetivo. Sin
ese borde se formaban cadenas detrás de la barra: estaba pasando algo y el
jugador no podía verlo, que es la peor forma de perder información.

Los otros tres lados llevan **90 px** de guarda, por una razón distinta: que toda
detonación **nazca** dentro de lo que se ve. No hace falta que la onda entera
quepa —para eso harían falta 105 px y se comería casi un tercio del ancho—, basta
con ver el origen del estallido para entender qué ha pasado.

### `BarCaption` — la etiqueta de la barra

Dice qué es la barra la primera vez. Después estorba, así que desaparece.

### `Score` y `Best` — puntuación y récord

El récord al lado del marcador y no en otra pantalla: comparar es lo que hace que
una partida mala duela y una buena signifique algo.

### `Objetivo` — la meta del nivel

Qué hay que conseguir y cuánto llevas. Sin esto, un nivel de campaña es
indistinguible del modo sin fin.

### `Stage` — dificultad y movimiento

Muestra **dificultad N · nombre del movimiento**. La dificultad es la **suma de
sus cuatro apartados** (presión, escasez, generosidad, legibilidad), no un
ordinal. Un escalón solo decía cuántos saltos habían pasado; un 8 no significaba
nada frente a un 4. Sumando, sí: y como tres de los cuatro apartados topan, el
número refleja la desaceleración real de la escalada, algo que un ordinal nunca
podría expresar.

### `Fallos` — los toques fallados

Tocar donde no hay nada cuesta tiempo. Verlo acumularse es lo que convierte el
castigo en una regla y no en una sorpresa.

Enseña **solo el número**, no «2 / 5». El denominador no informaba: lo normal es
perder por tiempo con dos fallos, y entonces los tres que quedaban no
significaron nada. Un dato que casi nunca es el que te mata se lee como ruido, y
el ruido en un HUD tapa el campo.

Pero el límite existe y mata de verdad —con la barra en ocho segundos, cinco
fallos se agotan antes de que el tiempo llegue a matarte—, así que esconderlo
del todo sería cambiar el ruido por una emboscada. Aparece **cuando quedan dos o
menos**, que es justo cuando pasa a ser lo que decide la partida.

### `Combos` — los multiplicadores flotantes

Aparecen **en el sitio del contagio**, no en una esquina. El número tiene que
salir donde ocurre la cadena o el jugador no puede relacionarlo con lo que hizo.
Un tap nuevo **reinicia** la cuenta: encadenar es esperar, no repetir.

### `Flash` — los avisos

Texto grande y breve en el centro: subida de dificultad, respiro, meta cumplida.
Se va solo.

### `Hint` — la pista del nivel

Una frase que dice cómo se juega **este** bioma. Es lo que evita tener que
aprender por muerte.

### `Pausa` — el botón

Arriba a la derecha, redondo y grande. Es el único control además del propio
campo.

---

## Efectos de pantalla completa

| Nodo | Para qué |
|---|---|
| `Destello` | Fogonazo blanco muy breve en las cadenas largas. Premia sin interrumpir. |
| `Barrido` + `BarridoHalo` | La línea que cruza la pantalla al cambiar de bioma en el modo sin fin. Los objetivos que deja atrás **ya son del bioma nuevo**, y el fondo se cambia justo cuando la línea va por el medio: el cambio se ve ocurrir en vez de aparecer ya hecho. |

---

## Las pantallas

Siete estados, cada uno con su pantalla. El orden del enum `State` **no se puede
tocar**: el simulador indexa por número y una vez se quedó girando en vacío
porque se insertaron estados al principio.

### `MenuScreen` — el menú

Título, subtítulo, y **dos botones grandes**: Campaña y Sin fin. Debajo, el
récord. Y un botón de Registro, que es la única puerta a la caja negra.

### `SelectScreen` — elegir nivel

Bioma, número, meta y pista, con flechas a los lados y un botón de jugar. Existe
porque una campaña de 52 niveles sin selector obliga a rejugar todo para llegar
al que te interesa.

### `BriefingScreen` — antes de empezar

Bioma, número, meta y pista, y «toca para empezar». Es un latido de espera a
propósito: entrar de golpe a un bioma nuevo sin saber qué se te viene encima es
la forma más rápida de perder sin entender por qué.

### `OverScreen` — has perdido

**El título es el motivo de la derrota**, no la palabra «fin»: «Se acabó el
tiempo», «Demasiados fallos», «Impactó la ciudad», «Impactó la Tierra». Debajo,
la puntuación y el nivel, y un botón grande de reintentar.

### `WinScreen` — has ganado

Puntos, mejor cadena, dificultad alcanzada y tiempo. Un botón para seguir.

Ganar existía tarde: durante un buen rato el juego solo sabía terminar mal, y una
partida que solo puede acabar en derrota no tiene cierre.

### `PauseScreen` — pausa y ajustes

Cuatro interruptores —**sonido, música, vibración y temblor**— más seguir y
volver al menú. El temblor está entre las opciones porque hay gente a la que le
sienta mal, y porque fue el primer sospechoso del cierre inesperado en Android.

### `LogScreen` — la caja negra

Muestra el registro de la última sesión y si terminó bien o mal. Está dentro del
juego y no en un fichero suelto porque el teléfono de pruebas no está conectado a
nada: cuando la aplicación se cerraba sola, esta pantalla fue **la única forma de
saber por qué**, y lo resolvió en una línea después de que cuatro hipótesis
razonables se cayeran una detrás de otra.

---

## Lo que deliberadamente no está

- **Ningún contador de vidas.** La barra ya lo es.
- **Ninguna moneda ni tienda.** La gamificación está documentada pero sin
  construir, y el orden pactado empieza por misiones, no por economía.
- **Ninguna mejora permanente.** Un juego donde el progreso se compra deja de
  medir al jugador.
- **Ningún tutorial.** Cielo abierto **es** el tutorial, y la pista de cada nivel
  hace el resto.
