# Ritmo y lectura

Actualizado: 2026-08-30

Tanda de arreglos salidos de jugar en el teléfono. Todos apuntan a lo mismo:
que el jugador **entienda** lo que pasa, antes y después de cada partida.

## Tarjeta de objetivo antes de empezar

Antes se caía dentro del nivel sin saber qué pedía. Era especialmente malo al
encadenar niveles: tras "SIGUE" empezabas a jugar a ciegas.

Ahora hay una tarjeta con bioma, número, objetivo y pista, y se sale de ella con
un tap. **Ese tap no detona**: solo arranca la partida. Si detonara, el jugador
gastaría su primer toque sin haber mirado el campo.

Solo en campaña. En el modo sin fin no hay objetivo que leer.

## La derrota deja ver el campo

El fondo de la pantalla de derrota pasa de opaco (0.92) a translúcido (0.55), y
el campo queda congelado detrás tal y como estaba. Además, si perdiste por
fallar un toque, **queda clavado un anillo donde tocaste**.

El mensaje dice POR QUÉ perdiste; la marca dice DÓNDE. Sin ella el jugador lee
"fallaste el toque" y se queda sin saber por cuánto.

## Cámara lenta en el último movimiento

Al ganar o perder, el mundo sigue moviéndose a **0.3x durante 0.8 s** antes de
que aparezca la pantalla de resultado.

Ese es justo el momento que el jugador quiere entender, y a velocidad normal se
lo pierde. Cortar de golpe le roba la información que necesita para volver a
intentarlo.

Dos detalles que hicieron falta:

- La escala de tiempo normal se **captura al arrancar** en vez de asumir 1.0, o
  la cámara lenta pisaría la que impone el simulador.
- El récord se decide **al terminar** la cámara lenta, no al empezarla: durante
  ella la cascada sigue sumando puntos, y cuentan.

## La campaña pasa a 22 niveles

Siete biomas, ordenados de menos a más hostil:

| Bioma | Regla | Qué le hace al jugador |
|---|---|---|
| Campo abierto | rebote | enseña |
| Ventisca | nieve | deja respirar |
| Río | corriente | regala los grupos |
| Enjambre | enjambre | los grupos vienen servidos, cuesta el instante |
| Billar | choque | los grupos se deshacen solos |
| Panal | abeja | cuesta leer hacia dónde van |
| Estampida | huida | se defiende de ti |

El selector de movimiento de la pausa **se retira**: era un banco de pruebas, y
ahora cada regla tiene sus niveles. Sigue disponible desde el inspector, grupo
Pruebas, para seguir cacharreando.

## Vaciar la pantalla, aparcado

`Meta.LIMPIAS` sigue implementada y funcionando, pero ningún nivel la usa:
resultó demasiado dura. Queda disponible para cuando haya un bioma que la haga
razonable.

## El contador de fallos no miente

En los niveles que se pierden al primer fallo, el HUD mostraba "fallos 0 / 5",
que era falso: no hay margen que gastar. Ahora pone **"sin fallos permitidos"**
en rojo, y el mensaje de derrota es "FALLASTE EL TOQUE" en vez de hablar de un
margen que no existe.

## Vibración apagada

Apagada por defecto por ser la principal sospechosa del cierre en el teléfono.
Se fuerza a apagada una vez aunque estuviera guardada como encendida — no vale
dejar encendida una función sospechosa de tumbar la app solo porque así estaba
en la configuración. El interruptor sigue en la pausa para volver a probarla.

## Alarma de tiempo bajo

La barra pasa de dos estados a **tres**: verde por encima de 6 s, ámbar entre 3
y 6, rojo por debajo. Con solo verde y rojo el aviso llegaba de golpe y ya no
daba tiempo a reaccionar; el ámbar es el que dice "empieza a buscar un buen
grupo".

En rojo suena un pitido corto y agudo, **cada vez más seguido**: de 0.59 s entre
pitidos con 2.9 s en la barra, a 0.26 s con 0.3 s. Ese acelerón es lo que
convierte el aviso en presión en vez de en ruido de fondo.

No es un bucle que haya que parar: son pitidos sueltos que dejan de programarse
en cuanto la barra vuelve a ámbar o verde. Se calla solo.

El timbre lleva un armónico impar que lo hace nasal a propósito. Un tono limpio
a ese volumen se confundiría con un eslabón más de la cadena, que es justo lo
que no puede pasar con un aviso.

## Celebración al ganar

Al superar un nivel: fogonazo verde a pantalla completa, nueve anillos
repartidos por el campo y una fanfarria de arpegio ascendente.

Coincide con la cámara lenta del final, así que la celebración se ve entera
antes de que aparezca la pantalla de resultado. Dos decisiones:

- El fogonazo llega a **0.5 de opacidad, no a 1**. Un blanco pleno taparía el
  campo justo cuando el jugador quiere ver qué acaba de conseguir.
- Los anillos se registran como **efectos y no como detonaciones**: adornan, no
  contagian. Si contagiaran, la celebración cambiaría la puntuación final.
