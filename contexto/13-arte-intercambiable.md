# 13 · Arte intercambiable

Hasta aquí, todo el arte del juego vivía dentro del código: cada forma es una
función `_draw()` con polígonos y arcos, y cada fondo es un mosaico generado
píxel a píxel. Eso tiene ventajas reales —cero assets, cero problemas de
resolución, un juego de 28 MB— pero un techo evidente: **mejorar el aspecto
obligaba a tocar la lógica**, y quien dibuja bien no tiene por qué saber
GDScript.

Este paso rompe ese acoplamiento sin tirar nada de lo que ya funciona.

## La regla

> Si existe el fichero, manda el fichero. Si no, se dibuja como siempre.

El dibujo procedural no desaparece: pasa a ser el **respaldo**. Esa decisión es
lo que hace que el sistema sea utilizable en la práctica:

- Se puede sustituir **una sola forma** sin tocar las otras quince.
- Si falta un fichero, o viene corrupto, el juego sigue jugable.
- La lógica no se entera. Radio de contagio, radio de toque, movimiento,
  balance: idénticos. Un asset solo cambia lo que se ve.

La alternativa —migrar todo a sprites de una vez— habría exigido dibujar 16
formas y 17 fondos antes de poder ejecutar el juego otra vez. Nadie termina esa
tarea.

## Dónde van las cosas

Cuatro carpetas, y cuál se elige **es parte del encargo**:

| carpeta | qué es | lo que hay que vigilar |
|---|---|---|
| `arte/targets/` | lo que se revienta | la proporción del lienzo |
| `arte/fondos/` | azulejo que **se repite** | tiene que casar consigo mismo |
| `arte/telones/` | fondo de **pantalla completa** | pierde el desplazamiento |
| `arte/explosiones/` | las detonaciones | `cadena`, `fallo`, `impacto` |

Cada una lleva su `LEEME.txt` con los nombres válidos y las trampas, para que
quien dibuja no tenga que leer este documento ni el código.

Mosaico y pantalla completa son dos carpetas y no una a propósito. Confundirlos
se paga en las dos direcciones: un azulejo estirado a pantalla completa se ve
borroso, y un cuadro repetido en baldosas deja una rejilla de costuras por todas
partes. El nombre de la carpeta obliga a decidir cuál se está entregando, y esa
decisión no puede quedar implícita porque **no hay forma fiable de adivinarla
mirando la imagen**.

Si existen las dos para el mismo telón, gana la de pantalla completa.

También valen `.svg`, `.webp` y `.jpg`. Godot importa el SVG rasterizándolo al
importar, así que no escala mejor que un PNG en tiempo de ejecución; la ventaja
del SVG es poder reeditarlo.

### Variantes por instancia

Dos formas cambian de un target a otro: la bola de billar lleva número y el
globo lleva color. Se prueba primero `bola_7.png` y se cae a `bola.png`. Así se
puede dibujar una bola genérica hoy y las quince cuando apetezca, sin decidirlo
por adelantado ni tocar código.

### El lienzo

El target **no llena la imagen**. El lienzo mide `5.4` radios de ancho y la
forma va centrada. Hace falta margen porque varias formas se salen de su radio:
el cordel del globo llega a 2.65 radios y las aletas del misil a 1.35. Sin
margen se recortarían justo esos detalles que las identifican.

En un lienzo de 512 px, eso deja el cuerpo principal en unos 190 px de diámetro
y el resto en aire. Quien dibuje a mano tiene que respetar la proporción o su
forma saldrá de otro tamaño que las demás.

### La orientación

Siete formas las rota el nodo hacia su rumbo —dron, avión, misil, abeja, pez,
meteoro y hormiga— y la convención es **0 grados = mirando a la derecha**, porque
el código hace `rotation = velocity.angle()`.

No es negociable, y compensarla por forma llenaría el código de una tabla de
excepciones que habría que mantener para siempre. Se arregla en el fichero, una
vez.

En la primera tanda de assets **cuatro de siete no cumplían**: el dron miraba
arriba, el avión arriba-derecha, el meteoro viajaba abajo-izquierda y el pez a la
izquierda. Se corrigieron al instalarlos.

Y el pez trae su propia trampa: se **refleja** en horizontal, no se gira 180
grados. Girado nadaría panza arriba, y es el tipo de fallo que no se ve en una
hoja de contactos porque ahí está quieto.

### El color

Un asset se dibuja **tal cual**. Ni targets ni fondos se tiñen con la paleta del
bioma: el color lo pone quien dibuja.

Es distinto de lo que hace el generador, que produce todo en blanco con alfa
para poder teñirlo por bioma. Tenía que ser distinto: teñir el trabajo de
alguien que ya eligió sus colores es pelearse con él.

## El exportador

```
godot --path . --script tools/exportar_arte.gd
```

Vuelca las 37 imágenes de target (contando variantes) y los 17 mosaicos a
`arte_exportado/`, que **no** es la carpeta que lee el juego. A propósito:
exportar no debe cambiar en nada lo que se ve. Cuando un dibujo esté listo se
copia a `arte/` y entonces sí manda.

Escribe además un `README.md` con las 54 piezas y su nombre de fichero al lado,
más la paleta de cada bioma. Va en Markdown y no en un PDF porque GitHub lo
renderiza solo: quien recibe el repo abre la carpeta y lo ve, sin instalar nada.
El nombre de fichero es la mitad del encargo —es lo que hace que un dibujo entre
en el juego— así que tiene que ir pegado a la imagen y no en otro documento.

Dos detalles del exportador que son decisiones, no casualidades:

- **Los targets se renderizan de verdad**, en un `SubViewport`, en vez de
  reimplementar las formas sobre un `Image`. Lo exportado es exactamente lo que
  dibuja el juego, y no hay una segunda versión del código que se desincronice
  al primer cambio. El precio: tiene que correr con ventana, no en headless.
- **Los fondos se exportan ya compuestos** sobre su color de bioma. El generador
  los hace en blanco con alfa, pero un PNG blanco sobre transparente se ve vacío
  en cualquier editor y, peor, al copiarlo a `arte/fondos/` saldría blanco,
  porque a un asset no se le aplica tinte. Exportarlo compuesto hace que lo que
  ves sea lo que hay.

## Las explosiones

Una detonación no es una imagen: crece con un frenazo al final, se sostiene
—esa es la ventana en la que un punto puede contagiarse— y se apaga. Aun así
**basta con entregar una imagen quieta**, porque el nodo la escala al radio de
cada instante y la desvanece al final. Lo que hay que dibujar es el momento de
más energía.

Hasta ahora las tres detonaciones se distinguían solo por el color, que basta
para dibujarlas pero no para sustituirlas: un asset necesita saber **cuál** está
reemplazando. De ahí el enum `Explosion.Tipo`, que es todo lo que hizo falta
añadir.

El precio de sustituirlas: hoy la detonación toma el color del bioma, y un asset
se dibuja tal cual, así que pasaría a ser la misma en los diecisiete. No es poco
—el color de la onda es parte de la identidad de cada bioma— y conviene decidirlo
a sabiendas.

## Lo que se pierde al sustituir

Las formas que se animan por dentro quedan **congeladas**: las alas de la abeja,
la cola del pez, el titileo de la estrella, el ondeo de la llama, el cordel del
globo. Una imagen no bate alas.

No es un fallo del sistema, es lo que significa cambiar código por imagen. Para
esas cinco formas conviene decidirlo a conciencia: un dibujo mejor y quieto
puede compensar, o no. Se puede comprobar sin arriesgar nada, porque quitar el
fichero devuelve la animación.

Lo que **no** se pierde: la rotación hacia la dirección de vuelo (la aplica el
nodo, no el dibujo) ni la animación de entrada al aparecer.

Y en los fondos de pantalla completa se pierde otra cosa distinta: **el
desplazamiento**. Hoy la nieve cae, el río corre y las pavesas suben porque el
azulejo se mueve, y una imagen que no se repite no puede moverse sin descubrir su
borde. Es un cambio de sensación, no solo de dibujo. El azulejo lo conserva.

## Verificación

- **Ida y vuelta exacta.** Se exportó `abeja.png`, se metió en `arte/targets/` y
  se volvió a exportar: la imagen resultante es la misma (2940 → 2953 bytes, la
  diferencia es recompresión). Si la convención del lienzo estuviera mal, la
  abeja habría salido de otro tamaño o descentrada.
- **Llega al teléfono.** Comprobado sobre el paquete exportado: el `.png`
  original no viaja, pero sí su `.ctex` importado y la entrada de remapeo, así
  que `ResourceLoader.exists("res://arte/targets/abeja.png")` responde que sí
  también en el APK. Por eso `Arte` pregunta por el recurso y no por el fichero.
- **Balance intacto.** La simulación da los mismos números que antes del cambio.

## Generado, pero versionado

`arte_exportado/` empezó ignorado por git, con el argumento de siempre: es
generado, se regenera con un comando, no se versiona lo derivable.

Estaba mal, y el motivo se ve al mirar el repo desde fuera: **no contiene ni una
imagen**. Todo el arte es código, así que quien lo abre en GitHub no ve nada del
juego. Para redibujar una abeja hay que verla primero, y exigir instalar Godot
4.7 y correr un comando para eso convierte una tarea de diseño en una de
entorno. Son 115 KB.

La regla útil no es «no versiones lo generado», es **no versiones lo generado
que nadie va a mirar**. Esto se mira: es el encargo.

Del APK sí sigue excluido, que es donde de verdad sobraba.

## Un fallo que salió de la verificación

Al inspeccionar el paquete apareció `arte_exportado/` entero dentro del APK: 54
PNG que nadie usa, 112 KB. Godot empaqueta todo lo que hay en el proyecto salvo
lo que excluyas. Corregido en `export_presets.cfg`:

```
exclude_filter="tools/*,arte_exportado/*"
```

Vale la pena anotarlo porque es el tipo de cosa que no se nota nunca: el juego
funcionaba perfectamente con el peso de más.
