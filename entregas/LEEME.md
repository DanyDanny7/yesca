# Contrato de entregas

Esto es lo que hay que saber para entregar arte, efectos o movimientos a Yesca
sin romper nada y sin que haya que preguntar.

## La regla de oro

> **Nadie escribe en `arte/`. Todo entra por `entregas/`.**

`entregas/` es el buzón. `arte/` es lo que el juego lee, y lo genero yo
importando desde el buzón.

**Las tandas NO se versionan.** El buzón es de paso: llega una tanda, se importa
a `arte/` y se reemplaza lo viejo. Guardar el historial de tandas llenaría el
repo de diseños obsoletos que nadie va a volver a mirar, y que pesan más que el
juego entero. Lo que vale es el resultado y el contrato, no los borradores.

Del buzón solo se versionan este documento y la plantilla, porque no son
entregas: son las normas.

Una carpeta por tanda, con fecha delante para que se ordenen solas mientras
están en disco:

```
entregas/
  2026-09-03-revision-por-bioma/   ← la tanda nueva
  LEEME.md                         ← esto. Sí se versiona
  _plantilla/                      ← cópiala para empezar. Sí se versiona
```

Si una tanda corrige una pieza ya importada, **la sustituye**: mismo nombre de
fichero, y al importar gana la nueva. No hay que renombrar nada ni conservar la
anterior.

Dentro de cada tanda:

```
<lote>/
  ENTREGA.md          qué trae, qué cambia y qué hay que mirar
  targets/            formas que el jugador revienta
  fondos/             fondos de bioma
  explosiones/        detonaciones
  movimientos/        especificaciones de movimiento (texto, no imágenes)
```

Las carpetas que no se usen se pueden omitir. Una tanda de solo tres targets es
una tanda perfectamente válida.

---

## 1 · Targets

### Nombre

El nombre del fichero **es** la instrucción. Otro nombre y no lo lee nadie.

```
circulo  copo  abeja  hoja   bola   dron    chispa  chip     avion
misil    pez   estrella  llama  burbuja  globo  meteoro  robot  hormiga
fugaz
```

Variantes por instancia, con caída al fichero base si falta:

```
bola_1 … bola_15      quince bolas de billar
globo_1 … globo_8     ocho colores de globo
```

### Lienzo

Cuadrado. El **cuerpo** del target mide `1/5.4` del ancho y va centrado: en
512×512, unos 190 px de diámetro.

El aire de alrededor no sobra. Es para lo que se sale del cuerpo —el cordel del
globo, la llamarada del misil, las antenas de la hormiga, la estela del
meteoro—, y **eso sí puede salirse**: lo que tiene que respetar la proporción es
el cuerpo, porque es lo que el jugador toca.

### Orientación · la parte que más se rompe

El juego orienta cada forma según una política declarada en
`scripts/dot.gd` → `GIRO_DE_FORMA`. **Hay que dibujar sabiendo cuál le toca.**

| Política | Qué hace el juego | Cómo hay que dibujarla |
|---|---|---|
| `FIJO` | nunca gira | como se vaya a ver siempre |
| `RUMBO` | gira hasta apuntar a donde va | **vista cenital**, morro a la DERECHA |
| `ESPEJO` | no gira; se refleja al ir hacia la izquierda | **de perfil**, mirando a la DERECHA |
| `CABECEO` | se refleja y además se inclina hacia donde va | **de perfil**, mirando a la DERECHA |
| `NORIA` | gira sola, sin relación con el rumbo | cualquier orientación |

La regla que ordena la tabla:

> **Una forma solo puede dar la vuelta entera si se dibujó vista desde arriba.**

Un dron o un meteoro vistos desde arriba pueden apuntar a cualquier lado. Una
abeja o un pez dibujados de perfil, no: al girar hacia la izquierda quedarían
boca arriba, y nadie mira un pez del revés y piensa «va hacia allá», piensa que
está muerto.

Por eso los de perfil se **reflejan**, no se giran. Es una diferencia que no se
ve en una hoja de contactos, porque ahí están quietos.

Asignación actual:

```
FIJO      circulo  copo  bola  chispa  chip  estrella  llama  burbuja  globo  robot
RUMBO     dron  misil  meteoro  hormiga  fugaz
CABECEO   abeja  avion  pez
NORIA     hoja
```

Si una forma nueva necesita otra política, **dilo en `ENTREGA.md`**; es una
línea en la tabla.

### `fugaz` · dibuja solo la cabeza

La estrella fugaz es el primer **objetivo especial**: sale una vez por minuto en
Cielo abierto, vale **diez veces** lo normal y su detonación es **un 50% más
grande** —y como la onda es el radio de contagio, encadena más lejos que
cualquier otra cosa del juego.

Para dibujarla hay una regla propia: **entrega solo la cabeza, sin estela.**

La estela la genera el juego con vectores, a partir de la trayectoria real que
siguió el objetivo. Tiene que ser así porque la fugaz se arquea al cruzar, y una
estela pintada en la imagen sería recta y rígida: se vería que no acompaña al
recorrido. El juego la dibuja siempre, tanto si hay asset como si no, así que
una estela dibujada en el PNG saldría **encima** de la de verdad.

La cabeza va orientada como cualquier `RUMBO`: **mirando a la derecha**.

### Color

Se dibuja tal cual. No se tiñe con la paleta del bioma: el color lo pone quien
dibuja. Las paletas de los 17 biomas están en `arte_exportado/README.md`.

### Lo que se pierde

Un PNG no se anima por dentro. Al sustituir una forma que se movía por código
—alas, cola, titileo— queda quieta. Lo que **no** se pierde: la orientación de
arriba y la animación de aparición, porque las pone el nodo.

Borrar el fichero devuelve la versión de código. Siempre.

---

## 2 · Fondos

Un fondo de bioma son **tres capas**, y lo que las separa no es qué son sino
**cuánta deformación tolera cada una**. Esa es la idea entera: si se declara por
adelantado qué se puede estirar, se puede llenar cualquier pantalla sin recortar
nada que importe.

De abajo arriba:

| Capa | Carpeta | Deformación | Qué le pasa en pantalla |
|---|---|---|---|
| **Elástica** | `elasticas/` | **sí, la que haga falta** | se estira a pantalla completa |
| **Azulejo** | `fondos/` | no hace falta: se repite | cubre todo y **se desplaza** |
| **Rígida** | `telones/` | **ninguna** | se ancla abajo, escala solo por el ancho |

**Elástica** es lo que no tiene forma reconocible: el degradado del cielo, una
niebla, el agua del fondo. Estirarla al doble de alto no lo nota nadie, y es lo
que hace que un móvil de 21:9 y una tableta de 4:3 se llenen los dos sin dejar
franjas.

**Azulejo** es el patrón que se repite. Si hay capa elástica debajo, el azulejo
tiene que ser **transparente salvo el dibujo del patrón**: si lleva su propio
color de fondo, tapa la base y la elástica no sirve de nada.

**Rígida** es lo que tiene sitio: la bañera, la ciudad, el planeta, el
horizonte. No se deforma nunca, ni un píxel.

### Bandas · `arte/bandas/`

Tiras ancladas **arriba** que se repiten solo en horizontal y se desplazan
solas. La aurora de Invierno es el caso que las trajo.

```
invierno_1.png    la capa de atrás,  se desplaza a  +5 px/s
invierno_2.png    la de delante,     se desplaza a  −3 px/s
```

**Se numeran desde 1 con el nombre del bioma y nada más.** La entrega del 3 de
septiembre las llamó `invierno_aurora_1`; se renombraron al importarlas, porque
el código no puede adivinar la palabra del medio. Dos como mucho.

Tienen que **encajar consigo mismas en horizontal**: se repiten a lo ancho, así
que el borde derecho debe continuar en el izquierdo o se ve la costura pasar. En
vertical no se repiten.

Van **entre la elástica y el azulejo**, y ese orden no es arbitrario: la aurora
está a cien kilómetros y la nieve a diez metros, así que los copos caen por
delante.

Las velocidades son opuestas y primas entre sí a propósito. Con una sola capa lo
que se ve es una cortina corriéndose de lado; con dos a distinta velocidad, los
máximos de una caen sobre los huecos de la otra y el brillo **late en el sitio**.
Y siendo 5 y 3, el patrón conjunto tarda seis minutos en repetirse.

### Piezas del fondo que se mueven un poco

Una pieza rígida que deba mecerse sin salirse de su sitio va como **tira de
fotogramas** en `telones/`, con la convención `<bioma>_<pieza>@N.png`. Sirve para
las algas del lecho, y serviría igual para las llamas de Asedio, los banderines
de Fiesta o la espuma de Ducha.

**Mejor una pieza suelta que el decorado entero.** Para las algas hay dos
formas y la segunda es mejor:

```
rio_algas@8.png    el lecho entero, con las once algas horneadas
rio_alga@8.png     UNA sola alga  ← manda sobre la anterior
```

Con el lecho horneado, el desfase y el reparto vienen dados y lo único que se
puede tocar desde el código es la duración del ciclo. Con una sola alga se decide
cuántas hay, cada cuánto, cuánto se retrasa cada una respecto a su vecina y
cuánto varía de tamaño — y pesa una décima parte.

El juego ya reparte, desfasa y varía el tamaño por su cuenta. Lo que hace falta
entregar es **una pieza bien dibujada**, no el decorado montado.

### Variantes por proporción

Cualquiera de las tres capas admite versión por forma de pantalla, con caída a
la general si falta:

```
ducha__ancho.png    pantallas más anchas que 1:1.6   (tabletas 4:3, 16:10)
ducha__medio.png    entre 1:1.6 y 1:1.9              (16:9, 18:9)
ducha__alto.png     de 1:1.9 en adelante             (19.5:9, 20:9, 21:9)
ducha.png           la que vale para todas
```

Tres grupos y no más porque tres cubren el parque real y cada uno multiplica el
trabajo. **No hace falta entregar las tres**: con la capa elástica bien puesta,
casi siempre basta una sola imagen. Las variantes son para cuando un bioma
concreto pida composición distinta —por ejemplo, una ciudad más ancha y baja en
tableta— no para todos por sistema.

La forma más cómoda de entregarla es como hasta ahora: **un SVG por bioma**, con
el patrón en `<defs>` y los `<rect>` a lienzo completo primero, y la pieza
anclada después. Yo lo troceo con `tools/separar_fondos.py`.

Nombre del fichero: el del bioma, en minúsculas y sin acentos.

```
cielo_abierto  invierno  rio     hormigas  basico   billar  panal
estampida      otono     brasas  caza_de_robots     circuito
ciudad_de_papel  ducha   fiesta  asedio    lluvia_de_meteoros
```

### Que sirva en cualquier pantalla

Los teléfonos van de 16:9 a 20:9, y las tabletas bajan hasta 4:3. Un fondo tiene
que servir para todos sin que se note el apaño.

**La solución de fondo son las tres capas de arriba**, y sobre todo la elástica:
con ella no queda hueco en ninguna proporción sin recortar nada. Las variantes
por proporción están para afinar, no para tapar el problema.

Y para la capa rígida, además: **lienzo más alto que la pantalla más alta, y una
zona segura declarada**.

Antes de nada, una advertencia honesta sobre «que se vea exacto en todas»: con
un fondo a sangre eso es **físicamente imposible en sentido estricto**. Las
proporciones van de 1:1.33 a 1:2.33 —un 75% de diferencia— y solo hay tres
salidas: deformar, recortar, o dejar barras negras. Nadie pone barras negras
desde hace quince años.

Lo que sí se puede garantizar, y es lo que hace el juego:

- **Cero deformación.** Nunca, en ningún eje.
- **Cero huecos.** Ni barras ni franjas de otro color.
- **La misma banda de abajo, al mismo ancho, en todos los aparatos.**
- Lo único que cambia entre un móvil y otro es **cuánto cielo se ve por arriba**.

Eso es lo más cerca de «exacto» que existe sin deformar.

#### Lo que hace el juego, exactamente

La composición se escala **por el ancho** y se ancla **abajo**. De ahí salen tres
consecuencias que conviene tener presentes al dibujar:

1. **Nunca hay deformación horizontal.** El ancho siempre encaja. Lo que se
   dibuje a lo ancho se ve entero, siempre.
2. **Lo de abajo nunca se pierde.** La bañera, la ciudad, el planeta: están
   anclados y no se recortan jamás.
3. **Lo de arriba es elástico.** Según la pantalla, o se recorta, o aparece
   azulejo por encima.

#### El lienzo: 208 × 500

**Este es el cambio importante.** El lienzo actual, 208×336, es 1:1.62 — más
corto que cualquier móvil. Por eso el comportamiento no es uniforme hoy: en un
20:9 falta un 27% de arte por arriba y hay que rellenarlo con azulejo; en una
tableta sobra y se recorta.

Con **208 × 500** (1:2.40) el arte es más alto que la pantalla más alta que
existe, así que **nunca falta**. Todas las pantallas hacen lo mismo: enseñar la
banda de abajo y recortar por arriba lo que no cabe.

| Pantalla | Qué ve, del lienzo de 500 |
|---|---|
| Móvil 21:9 | los 485 units de abajo |
| Móvil 20:9 | los 462 |
| Móvil 19.5:9 | los 451 |
| Móvil 18:9 | los 416 |
| Móvil 16:9 | los 370 |
| Tableta 16:10 | los 333 |
| Tableta 4:3 | los 277 |

#### Las dos reglas al dibujar

**Zona segura: los 277 units de abajo.** Se ven enteros en todo, tabletas
incluidas. Ahí va todo lo que tenga que verse sí o sí: la bañera, la ciudad, el
planeta, el suelo, el horizonte.

Si el juego acaba siendo solo para móviles, la zona segura sube a **370 units**,
que es bastante más cómodo. Dilo en `ENTREGA.md` y lo damos por bueno.

**Sangrado: todo lo que quede por encima.** Cielo, agua, atmósfera, humo.
Aparece o no según el aparato, así que **ahí no va nada que importe** — pero
tiene que estar dibujado, porque en un 21:9 se ve casi entero.

#### Y si el lienzo se queda corto

Los diecisiete fondos actuales son de 208×336 y siguen funcionando; el juego
rellena por arriba con el azulejo. Para que no quede una franja delgada de otro
color —que se lee como error de montaje, no como cielo— la composición **tiene
que fundirse con el azulejo por su borde superior**.

En los biomas sin patrón eso sale gratis: el azulejo se sintetiza con el color
de la fila de arriba de la propia composición. En los que traen patrón, la
composición debe ser **transparente arriba**.

Ese fundido es automático en los biomas sin patrón, porque el azulejo se
sintetiza con el color de la fila superior de la propia composición. En los que
sí traen patrón, la composición debe ser **transparente arriba**.

#### La única deformación que existe

Cuando falta **menos del 12%** para cubrir la pantalla, la composición se estira
ese poco en vertical. Con el lienzo de 500 no llega a pasar nunca; existe para
que el arte antiguo de 336 no deje franja en un 16:9.

Está acotado a propósito: por debajo de ese umbral no lo ve nadie, y una franja
delgada de azulejo justo encima del dibujo se lee como un error de montaje, no
como cielo. Por encima del 12% no se fuerza — se deja ver el azulejo, que para
eso está.

**No hay ninguna otra deformación.** Ni horizontal, ni recorte por abajo, ni por
los lados.

#### Lo más robusto: banda en vez de pantalla completa

Si el bioma tiene patrón repetible, lo ideal es que la composición **solo traiga
la pieza anclada**, sobre fondo transparente y ocupando los 208 units de abajo.
Así la altura de la pantalla deja de importar del todo: el azulejo cubre lo que
haga falta y la pieza se queda donde tiene que estar.

Las composiciones a lienzo completo funcionan —las diecisiete actuales lo son en
siete casos— pero son las que se recortan y las que obligan a cuidar el fundido
de arriba.

### El desplazamiento

Un bioma **sin patrón** pierde el movimiento del fondo. Hoy invierno, río y
brasas están dibujados forma a forma, así que la nieve no cae, la corriente no
corre y las pavesas no suben. Si eso importa —y en esos tres importa— hay que
entregar el elemento móvil **como patrón**, no como formas sueltas.

### La geometría que es regla, no decorado

En dos biomas el dibujo **define dónde se pierde**:

- **Asedio**: el tejado más alto de la ciudad es la línea de derrota.
- **Lluvia de meteoros**: el disco de la Tierra es la zona de impacto.

Si cambian de sitio o de tamaño, hay que decirlo en `ENTREGA.md`. Yo leo las
cifras del SVG y las meto en el código, pero si no me avisas puedo no mirarlo, y
el resultado es que el jugador pierde tocando algo que ya no está ahí. **Ya pasó
una vez.**

---

## 3 · Explosiones

Tres tipos, y el nombre dice cuál es:

```
cadena.png     el tap y cada eslabón de la cascada
fallo.png      el toque errado; se ve igual pero no contagia
impacto.png    algo llegó a la ciudad o al planeta: fin de partida
```

No hace falta entregar los tres. El que falte se sigue dibujando por código.

### Dos formas de entregarla

**Imagen quieta** — `cadena.png`. El juego la escala al radio de cada instante y
la desvanece al final. Lo que hay que dibujar es el momento de más energía.

**Tira de fotogramas** — `cadena@8.png`: ocho fotogramas en fila, todos del mismo
ancho, del primero al último. El juego recorre la tira a lo largo de la vida de
la onda y **no desvanece**: el apagado lo decide el dibujo.

Esa es la diferencia importante. Con imagen quieta el juego controla el final;
con tira, lo controlas tú. Si el efecto tiene una idea propia sobre cómo
apagarse, va en tira.

Hasta 24 fotogramas.

### Una explosión propia para un bioma

Se puede, y sin inventar un tipo nuevo: se añade el bioma al nombre y se cae al
genérico si falta.

```
impacto_asedio.png            la ciudad ardiendo
impacto_lluvia_de_meteoros@12.png   el planeta, en doce fotogramas
cadena_ducha.png              burbujas reventando, solo en Ducha
```

### El lienzo

Cuadrado, **3 radios de ancho**. Menos que un target porque una detonación es
redonda y no tiene cola, pero más de dos: las esquirlas adelantan al anillo hasta
un 28%.

### El contraste

La regla no es «el anillo es claro», es **«el anillo contrasta contra su fondo»**.
Ducha es el único bioma de fondo claro; ahí un anillo pálido no existe. El
dibujo por código lo resuelve con un contorno oscuro debajo; un asset tiene que
resolverlo por su cuenta o entregar variante `_ducha`.

### Tiempos

La onda dura **1.2 s**: 0.3 de crecida, 0.6 de sostén, 0.3 de apagado. El
contagio se propaga cada 0.55 s. Una tira de N fotogramas se reparte por igual a
lo largo de esos 1.2 s.

**El radio no crece con la cadena**, y no puede: el radio de la explosión *es* el
radio de contagio. Si el dibujo creciera y el contagio no, el jugador aprendería
que el juego le miente.

---

## 4 · Movimientos

Un movimiento **no es un asset**: es código, porque necesita ver a los demás
objetivos y a las detonaciones. Lo que se entrega es una **especificación**, en
`movimientos/<nombre>.md`, y yo la implemento.

Para que sea implementable sin ida y vuelta, tiene que contestar estas seis
preguntas. Si alguna se queda en blanco, me la invento, y probablemente mal.

```markdown
# <nombre del movimiento>

**Entrada** — ¿por dónde aparece? (arriba / un lateral / los cuatro lados /
repartido por el campo). ¿Apunta a algún sitio?

**Rumbo** — ¿en línea recta? ¿gira? ¿cada cuánto y cuánto?

**Rapidez** — ¿constante, acelera, frena? ¿varía entre unos y otros?

**Bordes** — al llegar al borde: ¿rebota, se envuelve al lado opuesto, o sale
y desaparece?

**Relación con los demás** — ¿se ignoran, chocan, se buscan, se apartan de las
explosiones?

**Orientación** — cuál de las cinco políticas de giro le toca, y por qué.
```

### Lo que hace falta saber antes de diseñar uno

- El campo de juego **no es la pantalla**: hay 150 px de guarda arriba (bajo la
  barra de tiempo) y 90 a los lados y abajo. Un objetivo nunca se queda dentro
  de esa guarda, para que toda detonación nazca donde se ve.
- Un movimiento que **no rebota** —el meteoro, por ejemplo— tiene que garantizar
  que el objetivo acaba saliendo o muriendo. Si se queda flotando fuera del
  campo, ocupa sitio en el cupo y no se puede tocar.
- La **velocidad no es libre**: sale de la paleta del bioma multiplicando una
  base común. Un movimiento que solo funciona a una rapidez concreta es un
  movimiento frágil.

---

## 5 · Qué hago yo con la entrega

Por si sirve para saber qué esperar y en qué orden:

1. **Leo `ENTREGA.md`** y compruebo que los nombres cuadran con los que el juego
   busca. Los que no cuadren los digo, no los adivino.
2. **Miro las piezas** una a una, y mido lo que se puede medir: centrado,
   proporción del cuerpo, orientación de partida.
3. **Corrijo lo que se pueda corregir en el fichero.** En la primera tanda,
   cuatro de siete formas rotables venían mal orientadas; se giraron al
   instalarlas. El pez se **reflejó**, no se giró.
4. **Importo a `arte/`.** El buzón nunca se lee en ejecución.
5. **Capturo una pantalla real por bioma** (`tools/capturar.gd`) y la miro. Es el
   único paso que encuentra los problemas de verdad: así aparecieron la línea de
   derrota cortando los edificios y el disco del planeta descolocado.
6. **Vuelvo a correr las medidas** de balance y geometría, y digo qué se movió.

Si algo no encaja, lo digo antes de instalarlo. Una entrega a medias instalada
es peor que una entrega devuelta.
