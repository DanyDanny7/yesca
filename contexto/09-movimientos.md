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
