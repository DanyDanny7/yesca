# Targets para `arte/targets/`

41 ficheros, en PNG y en SVG. Copia los `.png` a `arte/targets/` y el juego
los usa; los `.svg` son la fuente editable y **no hace falta copiarlos**.

## Nombres

18 formas base:

    circulo  copo  abeja  hoja  bola  dron  chispa  chip  avion
    misil    pez   estrella  llama  burbuja  globo  hormiga  robot  meteoro

23 variantes por instancia, con caída al fichero base si falta:

    bola_1 … bola_15     1-8 lisas, 9-15 con banda
    globo_1 … globo_8    ocho colores

No hay `bala`: Asedio dispara misil.

## El lienzo

512×512, cuerpo centrado en **190 px de diámetro** — los 5.4 radios de
`13-arte-intercambiable.md`, medidos sobre el cuerpo. Las extensiones que el
documento licencia corren por fuera de esos 190 px: el cordel del globo, las
aletas y la llama del misil, la antena del robot, las patas y antenas de la
hormiga, la estela del meteoro.

Las 18 formas tienen el mismo cuerpo, así que todas ocupan lo mismo respecto a
su radio de toque. Eso no era cierto en la primera tanda: había 1.6× de
diferencia entre la más grande y la más pequeña.

## Estilo

Contorno oscuro `#0f1319` de 3.5 unidades sobre 100, **solo en la silueta**.
El detalle interior —franjas, nervios, agallas, brillos— va sin contorno: si lo
hereda, a 40 px la forma se convierte en una mancha oscura.

Hasta cuatro rellenos planos por forma, cero degradados dentro. Los brillos son
trazos con extremo redondo, no piezas.

## Orientación

Están dibujadas tal como se revisaron, y **no comparten orientación de
partida**: abeja, hormiga y misil miran a la derecha; el pez a la izquierda; el
dron arriba; el avión arriba-derecha; el meteoro abajo-izquierda.

Para las formas que el nodo rota hacia el rumbo hay que fijar una convención
—lo natural es rotación 0 = mira a la derecha— y girar las que no cumplan
**antes** de meterlas en el proyecto. El pez se refleja en horizontal, no se
gira 180°: girado nadaría boca arriba.

## Dos avisos

El número de las bolas es texto con la fuente del sistema, no un trazado. Si el
número tiene que ser exacto, conviértelo a curvas en el SVG antes de rasterizar.

El fuego del misil **es** la forma `llama` reducida. Es lo correcto para el
sistema, pero significa que la llama ya no se puede identificar por su dibujo:
dos formas la contienen. Distínguelas por nombre de forma, nunca por geometría.
