# Escalones, combo y fallos

Actualizado: 2026-08-30
Medido con `tools/simulacion.gd`.

## El problema

La dificultad era una rampa lineal, continua y atada al reloj. Tres defectos:
una pendiente suave no se nota (la intensidad se percibe por **contraste**, no
por nivel absoluto), castigaba igual al que juega bien y al que se queda
mirando, y era invisible.

## Escalones, no pendiente

La dificultad se queda quieta un rato, salta de golpe, se queda quieta otra vez.
El tramo plano es lo que te deja acomodarte, y es esa comodidad la que hace que
el siguiente salto se sienta. Sin meseta no hay escalón, solo una rampa con
ruido.

Se mueven **cuatro palancas** a la vez en vez de una mucho, porque cada una
ataca una habilidad distinta:

| Palanca | Qué ataca |
|---|---|
| `drain` | Presión |
| `respawn_interval` | Escasez de oportunidades |
| `chain_radius` | Generosidad de la propagación |
| `speed` | Legibilidad del campo |

Y uno de cada cuatro escalones no sube la presión: es un **respiro**. El valle
es lo que hace que se note el pico.

| Escalón | Desagüe | Radio cadena | Reposición | Vel. extra | |
|---|---|---|---|---|---|
| 1 | 0.70 | 105 | 0.32 | 0 | |
| 3 | 1.06 | 99 | 0.38 | 16 | |
| 4 | 1.06 | 96 | 0.41 | 24 | respiro |
| 6 | 1.42 | 90 | 0.47 | 40 | |
| 10 | 1.96 | 78 | 0.59 | 72 | |
| 14 | 2.50 | 75 | 0.60 | 104 | |

El escalón 1 es deliberadamente más generoso que cualquier ajuste anterior:
desagüe 0.70 contra el 1.0 plano de antes. Los primeros segundos perdonan.

## El error: atarlos a la puntuación

La primera versión los ató **solo a la puntuación**, con el argumento de que
así el que juega bien llega rápido a lo difícil y el que juega mal se queda más
tiempo en lo fácil — ajuste dinámico de dificultad gratis.

Medido, fue un error claro:

| Perfil | Sobrevive | Puntúa |
|---|---|---|
| Descuidado | ~99 s | ~175 |
| Bueno | ~110 s | ~253 |

**Separación 1.4x.** La dificultad por puntuación es una goma elástica: persigue
al buen jugador y le tapa el techo, mientras el descuidado puntúa despacio y se
queda granjeando el escalón más generoso. Se dijo que no se podía explotar
quedándose quieto, y es cierto — lo que no se vio es que sí se puede explotar
yendo despacio.

Para un juego que va del marcador, comprimir el rango de puntuaciones es lo peor
que puede pasar. Es buena idea en Tetris porque allí la puntuación **son** las
líneas; aquí no.

**Corrección:** manda el reloj (`stage_seconds`), y la puntuación queda como
acelerador con umbral alto (`stage_size`) para quien va disparado.

## El multiplicador de cadena

El punto N de una cascada vale **N**, no 1. Una cadena de 8 da 1+2+…+8 = 36
puntos, contra los 8 de ocho taps sueltos: **4.5x por la misma cantidad de
círculos reventados**.

Esto resolvió de un golpe el problema que llevaba tres iteraciones sin ceder.
Con puntuación plana la **frecuencia compensaba la calidad**: como tocar un
círculo siempre revienta al menos ese círculo, tocar mal muchas veces rendía
tanto como tocar bien pocas. Con el multiplicador no hay forma de igualar la
paciencia a base de volumen.

Y hace lo que se buscaba de diseño: el objetivo pasa a ser **encadenar**, no
pulsar. Eso frena el ritmo y compensa pensar qué círculo tocar.

**Solo la propagación sube el contador.** El círculo que tocas siempre vale ×1
y a partir de ahí suman los que alcanza la onda. Sin esto, tocar a media cascada
regalaba multiplicador y pulsar más rendía igual que dejar propagar.

### N cadenas en paralelo

La primera versión hacía que un tap nuevo **reiniciara** el contador. Se quedó
corta: lo correcto es que cada tap arranque **su propia cadena**, y que haya
tantas vivas a la vez como el jugador quiera sembrar. Así se puede lanzar una
segunda cascada abajo mientras la primera todavía se resuelve arriba, y cada una
lleva su multiplicador por separado.

Detalles que hicieron falta:

- Cada `Explosion` guarda un `chain_id`. Sin él todas compartirían contador y
  encadenar en dos sitios daría lo mismo que hacerlo en uno.
- Un círculo alcanzado por dos ondas se lo lleva la detonación **más cercana**,
  no la primera de la lista: cuando dos cadenas se solapan, la que lo reclama
  tiene que ser la que el jugador ve encima.
- El contador vive **junto a su explosión**, no en el centro de la pantalla. Con
  varias cadenas a la vez, un número centrado no diría a cuál pertenece.
- Las etiquetas se **reciclan en un pool**. Con cadenas naciendo y muriendo
  varias veces por segundo, instanciar un `Label` cada vez tiene coste real:
  cada uno arrastra tema, fuente y layout propios.

Medido con un jugador que machaca: pico de **12 cadenas simultáneas** y 9
contadores en pantalla, con explosiones, cadenas y etiquetas todas acotadas y
limpiándose solas.

Lo importante es que **no ablandó el juego**, que era el riesgo: al no reiniciar
ya no hay castigo por tocar a media cascada. Pero cada tap del impaciente arranca
una cadena que muere en ×1 o ×2, mientras el paciente construye una larga. La
separación no cayó — subió.

## El medidor de fallos

Fallos **seguidos** que se toleran antes de perder, estilo Guitar Hero. Un
acierto lo pone a cero, y el margen se acorta con los escalones: 5 al principio,
3 a partir del sexto.

**Era código muerto en su primera versión.** El fallo costaba lo mismo que el
tap acertado (2 s) y se arranca con 10 s de barra, así que al quinto fallo se
moría por tiempo y el contador nunca llegaba a su límite. Se separó `miss_cost`
(1 s) de `tap_cost` (2 s) para que el castigo principal sea el contador.

Aviso honesto sobre su alcance: como se reinicia al acertar, **no** es lo que
frena al que machaca la pantalla — de eso se encargan el coste del tap y el
multiplicador. Lo que sí castiga es el manotazo a ciegas con el campo vacío o
los círculos rápidos.

## Medición final

4 partidas por perfil, densidad equivalente al campo real, tope de 300 s:

| Perfil | Sobrevive | Puntúa |
|---|---|---|
| Descuidado (toca a media cascada) | ~43 s | ~194 |
| Bueno (deja propagar) | ~163 s | ~2622 |

**3.8x en supervivencia, 13.5x en puntuación.** La mejor separación conseguida.

Dos apuntes sobre el banco de pruebas, porque las dos veces el error escondió
justo lo que se quería medir:

- El perfil "descuidado" esperaba a que la cascada terminara, igual que el
  bueno, así que nunca sufría el reinicio del multiplicador y el cambio parecía
  no hacer nada. Un jugador descuidado de verdad toca a media cascada.
- Al añadir los estados MENU y SELECT, el enum `State` se desplazó y el
  simulador seguía usando los índices viejos: ponía la partida en READY en vez
  de PLAYING y se quedaba girando en vacío sin que el reloj avanzara nunca. Los
  índices están ahora comentados en `simulacion.gd` con el aviso.

## Pendiente

- El multiplicador usa `×2`, no kanji. La fuente por defecto de Godot no trae
  glifos CJK; para `一二三` habría que empaquetar una fuente con soporte
  japonés, o un subconjunto con solo esos glifos, que pesaría muy poco.
- Sigue sin haber game feel: ni impacto, ni vibración, ni partículas, ni sonido.
- Biomas — que los círculos se muevan e interactúen distinto según el tramo de
  partida, no solo que cambien de color. Pendiente de discutir.
