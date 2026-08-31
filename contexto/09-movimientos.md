# Movimientos

Actualizado: 2026-08-30

Catálogo de reglas de desplazamiento. Es el cimiento de los biomas: un bioma no
es una paleta, es una regla que cambia cómo se lee el campo y cómo hay que
planear la cadena.

## El cambio estructural

Los círculos **ya no mueven su propia posición en un `_process` propio**. Lo
hace `Main` llamando a `Dot.mover()`, por dos motivos:

- Hay modos que necesitan ver a los demás círculos (choque, enjambre) o a las
  detonaciones activas (huida). Un nodo aislado no puede.
- Con `Main` al mando el orden de actualización es determinista: primero las
  reglas globales, después la integración de cada círculo, y solo entonces los
  contagios. Antes dependía del orden del árbol de nodos.

De paso, congelar el mundo al morir deja de necesitar `process_mode`: en DEAD,
WIN y FINAL simplemente no se llama a `_mover_dots`.

## Los siete modos

| Modo | Qué hace | Qué le pide al jugador |
|---|---|---|
| `REBOTE` | línea recta, rebota en los bordes | el original: leer trayectorias limpias |
| `ABEJA` | tirones, pausas y giros bruscos | no basta ver dónde están, sino hacia dónde salen |
| `NIEVE` | cae despacio con vaivén, reaparece arriba | ritmo lento y campo que se renueva por arriba |
| `CHOQUE` | rebota también contra los otros círculos | los grupos se deshacen solos |
| `CORRIENTE` | río en una dirección, sale por un lado y entra por el otro | esperar a que la corriente los junte |
| `ENJAMBRE` | se buscan entre sí y forman grumos | los clusters aparecen solos: lo difícil es el instante |
| `HUIDA` | se apartan de las detonaciones activas | atrapar a los vecinos antes de que escapen |

`HUIDA` es el primero que **reacciona a la mecánica** en vez de solo
desplazarse, y le da la vuelta al juego: tu propia onda dispersa al grupo que
estabas cazando.

## Medición

600 frames por modo, campo de 25 círculos:

| Modo | Vecinos a menos de 150 px |
|---|---|
| rebote | 0.6 |
| abeja | 0.8 |
| nieve | 0.8 |
| choque | 1.0 |
| huida | 1.0 |
| corriente | 1.3 |
| enjambre | 1.5 |

Ninguno deja escapar círculos de la pantalla, ninguno produce NaN y las
rapideces quedan acotadas (`abeja` es la más dispersa, 28–211, por diseño).

La columna de vecinos es la que importa: **cada modo produce un paisaje de
densidad distinto**, de 0.6 a 1.5. Como las cadenas dependen enteramente de la
densidad local, eso significa que el mismo objetivo es una dificultad diferente
en cada uno. Es la prueba de que estas reglas cambian el juego y no solo el
aspecto — que era la condición para que un bioma valiera la pena.

## Detalles de implementación

- La **rapidez base** se guarda aparte de la velocidad. Los modos que
  reorientan el vector (enjambre, huida, abeja) la necesitan para no acelerar
  ni frenar sin querer al cambiar de dirección.
- Cada círculo lleva un **desfase propio**, o dos con el mismo modo se moverían
  sincronizados como un coro.
- El **choque** ignora los pares que ya se están separando: sin eso, dos
  círculos pegados se quedan vibrando el uno contra el otro.
- La **nieve** entra siempre por arriba; el resto de modos entran por cualquier
  borde.
- `speed_variance` dispersa las rapideces dentro de un mismo modo. Conviven muy
  lentos con muy rápidos, y eso cambia la lectura del campo más que subir la
  media.

## Cómo probarlos

**Desde el juego**: botón de pausa en la esquina inferior izquierda. Dentro hay
un selector de movimiento con ‹ ›, y salida al menú principal. El cambio se
aplica **a los círculos que ya están en pantalla**, no solo a los que nazcan
después: si no, comparar dos reglas obligaba a esperar a que se renovara el
campo entero. La opción "según el nivel" devuelve el control al bioma.

En pausa el mundo se congela igual que al morir — ni los círculos se mueven ni
la barra baja.

**Desde el editor**: inspector del nodo `Main`, grupo Pruebas —
`forzar_movimiento` y `movimiento_prueba`, con el juego corriendo.

El HUD muestra siempre el modo en curso junto al escalón.

Un compromiso asumido: el botón de pausa ocupa una esquina del campo de juego,
así que un círculo que pase justo por debajo no se puede tocar — el tap pausa.
Es una esquina pequeña y el botón tiene que estar en algún sitio; si molesta,
la alternativa es reservarle una franja al HUD y encoger el campo.

## Pendiente

- **Decidir cuáles sobreviven.** Los seis modos nuevos son un catálogo, no seis
  biomas. Un bioma de verdad se queda solo con los que cambien la forma de
  jugar; el resto son variaciones bonitas y sobran.
- Ideas que faltan por probar: círculos que se dividen al explotar, círculos
  inertes que no contagian, y atracción hacia el punto donde tocas.
- El objetivo de **vaciar la pantalla** resultó demasiado duro para el nivel 4 y
  se movió al 8, como cierre del primer bioma.


# Biomas: regla, paleta y forma

Un bioma son ahora tres cosas, y las tres tienen que decir lo mismo.

| Bioma | Movimiento | Forma | Paleta |
|---|---|---|---|
| Campo abierto | rebote | círculo | neutra |
| Ventisca | nieve | **copo** | hielo |
| Río | corriente | círculo | agua |
| Enjambre | enjambre | círculo | violeta |
| Billar | choque | **bola con brillo** | tapete |
| Panal | abeja | **abeja** | miel sobre negro |
| Estampida | huida | **dron orientado** | alarma |
| Otoño | nieve | **hoja que voltea** | ámbar |
| Brasas | brasa | **pavesa con halo** | rescoldo |
| Circuito | circuito | **rombo** | fósforo |

## Lo que no se tematiza

La barra de tiempo (verde, ámbar, rojo) y el anillo gris del fallo. Esos colores
no decoran, **informan**, y cambiarlos por bioma obligaría al jugador a
reaprender a leerlos diez veces. Se tematiza el mundo; la interfaz se queda
quieta.

## Legibilidad como restricción, no como resultado

El círculo es lo único que hay que localizar a toda velocidad, así que ninguna
paleta puede comprometerlo. Contraste medido en los diez: entre **6.3:1 y
10.9:1**, todos muy por encima del 4.5:1 que sería el mínimo.

Las formas se dibujan a mano y a nueve píxeles no cabe detalle: lo que las
distingue es la **silueta**. El copo es radial, la hoja apuntada, el rombo
anguloso, el dron triangular. A ese tamaño, la silueta es toda la información.

Dos formas llevan orientación: el **dron** mira hacia donde va, lo que delata su
trayectoria antes de moverse — imprescindible en un bioma que huye de ti. Y la
**hoja** voltea despacio, como si cayera.

## Movimientos nuevos

- **Brasa**: suben y se renuevan por abajo. Es la nieve del revés, y cambia la
  lectura más de lo que parece: se caza hacia arriba.
- **Circuito**: solo horizontal y vertical, con giros de noventa grados. Las
  trayectorias más predecibles del juego, así que lo difícil deja de ser
  adivinar y pasa a ser esperar al cruce.

## El río corría en dos sentidos

Jugando el nivel 8: la pantalla se vaciaba y no se repoblaba. Dos fallos
encadenados.

**El río iba en las dos direcciones.** Los círculos entraban por un borde al
azar apuntando al centro, así que unos iban a la derecha y otros a la izquierda.
La pista del nivel decía "todos van en la misma dirección" y no era cierto. Ahora
entran siempre por la izquierda.

**La reposición era de ritmo fijo.** Daba igual que quedaran 24 círculos o
ninguno: entraba uno cada 0.4 s. En los biomas de cascada grande eso dejaba diez
segundos sin nada que tocar y con la barra bajando — tiempo muerto, y además
injusto, porque te castigaba por haber jugado bien. Ahora el ritmo escala con lo
vacío que esté el campo: de 0.38 s lleno a 0.084 s vacío.

**Los círculos entran creciendo**, de pequeños a su tamaño, como si vinieran de
lejos. Es puro telégrafo: se pueden tocar y contagiar desde el primer frame con
su radio completo. Uno que parece más pequeño de lo que se puede tocar es
generoso; al revés sería una trampa.


## Telón de fondo por bioma

Cada bioma tiene su fondo: estrellas, copos, líneas de corriente, células que
laten, paño de billar, panal hexagonal, rejilla técnica, hojas, pavesas y pistas
de circuito.

### El primer intento estaba mal, y se midió

La primera versión redibujaba el patrón entero cada frame. El panal costaba **un
tercio del rendimiento** en una RTX 2050 — 94 fps contra 144 — que en un
teléfono significa bajar de 60.

Lo revelador fue el intento de arreglo: bajar de 170 hexágonos a 45 solo subió
de 94 a **85 fps**. Es decir, casi nada. **El problema no era la cantidad de
figuras sino reemitirlas todas cada frame**, y esa distinción es la que decide
entre optimizar o rediseñar.

### La solución: mosaico

El patrón se genera **una vez** en una imagen de 128×128 que encaja consigo
misma, y en pantalla se dibuja repetida con **una única llamada**. Resultado:
los diez biomas a 144 fps, y generar un mosaico cuesta entre 0.1 y 8.9 ms, una
sola vez y cacheado por tipo.

La animación sale gratis desplazando el mosaico: cuesta exactamente lo mismo que
tenerlo quieto, porque sigue siendo una sola llamada. Y la dirección cuenta la
historia sin decir una palabra — la nieve cae, las pavesas suben, el río va de
lado.

### Detalles que hacen que encaje

- Los píxeles se pintan **con envoltura**: una figura que se sale por un borde
  entra por el opuesto, así que no hay costura.
- Los pasos de todos los patrones dividen a 128. Las ondas del río tienen
  exactamente un periodo por mosaico; el panal, dos celdas por eje.
- **Semilla fija por tipo**: el fondo de un bioma es siempre el mismo dibujo. Si
  se sembrara al azar, cambiaría de aspecto cada vez que se entra al nivel.
- El mosaico guarda solo alfa, en blanco, y se tiñe al dibujarlo. Así el mismo
  patrón sirve para cualquier color sin regenerarlo.

### La restricción que mandó sobre todo

El fondo no puede competir con los círculos. Alfas entre 0.05 y 0.13, escala
grande, movimiento lento. Lo único que el jugador tiene que localizar a toda
velocidad es un círculo de nueve píxeles, y un fondo con detalle o contraste se
lo roba. El telón tampoco se sacude con el campo: un fondo que tiembla en cada
eslabón convierte la pantalla en un mareo.
