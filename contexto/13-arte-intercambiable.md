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

```
arte/targets/<forma>.png     circulo, copo, abeja, hoja, bola, dron, chispa,
                             chip, avion, misil, pez, estrella, bala, llama,
                             burbuja, globo
arte/fondos/<telon>.png      liso, estrellas, copos, corriente, celulas,
                             tapete, panal, rejilla, hojas, pavesas, trazas,
                             estelas, horizonte, horizonte_roto, aurora,
                             azulejos, confeti, banderines
```

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

## Un fallo que salió de la verificación

Al inspeccionar el paquete apareció `arte_exportado/` entero dentro del APK: 54
PNG que nadie usa, 112 KB. Godot empaqueta todo lo que hay en el proyecto salvo
lo que excluyas. Corregido en `export_presets.cfg`:

```
exclude_filter="tools/*,arte_exportado/*"
```

Vale la pena anotarlo porque es el tipo de cosa que no se nota nunca: el juego
funcionaba perfectamente con el peso de más.
