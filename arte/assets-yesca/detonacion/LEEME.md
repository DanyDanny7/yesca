# Detonación y encadenado

Los tres sprites son de apoyo. **La detonación no es una animación pregrabada**:
es un anillo dibujado y dos degradados escalados por curva, así que el juego la
controla por completo y no hay tira de fotogramas que se desincronice del
radio real.

## Los sprites

| Fichero | Qué es | Cómo se usa |
|---|---|---|
| `anillo.png` | Aro claro con contorno oscuro, 512×512, radio 232 | Escalar de 0.12 a 1.18 del radio de explosión |
| `destello.png` | Degradado radial blanco → ámbar | Aditivo, en el centro |
| `halo.png` | Anillo suave ámbar, sin bordes | Aditivo, detrás del anillo |

El anillo también va en SVG. Si prefieres dibujarlo en código —`draw_arc` con
dos pasadas, oscura debajo y clara encima— queda mejor a cualquier tamaño y
puedes saltarte el PNG.

## Tiempos

La onda dura **1.2 s** y va en tres tramos: 0.3 de crecida, 0.6 de sostén,
0.3 de desvanecido. El contagio se propaga cada **0.55 s**.

    t = 0.00   escala 0.12, opacidad 0     el punto se apaga
    t = 0.10   escala 0.50, opacidad 1     destello a tope
    t = 0.40   escala 1.00, opacidad 0.9   radio real de contagio
    t = 0.80   escala 1.18, opacidad 0     se va creciendo un poco más

El destello vive solo el primer tercio: entra a 0.05 y ha desaparecido a 0.45.
Si dura más, tapa la forma que acaba de explotar y no se ve qué era.

## La regla que no se puede romper

**El eslabón se cierra en el instante del contagio, nunca antes.** La línea que
une dos puntos aparece cuando el segundo prende, no cuando la onda va de
camino. Si se adelanta, el jugador cree que la cadena falló cuando en realidad
aún no había llegado.

Ese fue el error de la primera versión y costó verlo: se leía como un fallo de
detección de colisiones cuando solo era la línea llegando pronto.

## La cadena

Un solo trazo continuo que pasa por todos los puntos prendidos, en tres capas:
contorno oscuro de 9, cuerpo ámbar de 5, y un segmento corto claro de 20 de
largo corriendo por la punta con resplandor.

Se difumina hacia la cola: el eslabón recién hecho va al 100% y los anteriores
van bajando. Así se lee la dirección de la cadena sin números.

No se corta en los vértices. Cada tramo nuevo continúa el trazo anterior —
`polyline` con `join` y `cap` redondos, no segmentos sueltos.

## El contador

`×N` va pegado a **cada** círculo, no uno solo al final: en una cascada puede
haber varios encadenados a la vez y hay que ver cuál va por dónde.

Se coloca a 46 unidades del centro, por la **normal exterior** del vértice — la
bisectriz hacia fuera del ángulo que forman los dos tramos. Así nunca cae encima
de la línea, sea cual sea la forma de la cadena.

## El radio no crece

Todos los anillos miden lo mismo, porque el radio de la explosión **es** el
radio de contagio. Si el anillo creciera con la cadena, la cadena se
autoalimentaría: el eslabón 5 alcanzaría más lejos, engancharía más, y se
llegaría a 20 sin más habilidad.

Y hacerlos distintos solo por fuera no vale: el anillo enseña dónde alcanza. Si
el dibujo crece y el contagio no, el jugador aprende que el juego le miente.

La escalada la cuentan el `×N`, el tono que sube y el trazo de la cadena.

## Lo que falta

Hit stop, sacudida de pantalla y sonido. Son la mitad del golpe y no se pueden
mockear en una pantalla quieta. Sin ellos la detonación se ve correcta pero no
se siente.
