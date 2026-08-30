# Economía v1

Actualizado: 2026-08-30
Medido con `tools/simulacion.gd`.

## Lo que forzó el cambio: v0 se sentía un bucle

Feedback directo jugándolo: *"las bolitas rebotan, luego de 5 o 10 segundos se
resetean y cambian de lugar, en ningún momento siento un avance, siento que es
más un loop"*.

Diagnóstico correcto y era un error de implementación, no de concepto. El v0
había copiado la estructura de Boomshine — **rondas**: detonar, resolver la
cascada, borrar el tablero entero, repetir. Pero `03-concepto-cadena.md` dice
explícitamente *endless, el campo se repuebla sin parar, sin niveles*. Se
implementó justo lo contrario de lo decidido, y lo que se sentía era esa
contradicción: un ciclo cerrado donde nada se acumula.

## Los dos cambios

**Campo continuo.** El tablero no se borra nunca. Los puntos atrapados se
reponen entrando desde los bordes, uno cada `respawn_interval`. Nunca aparecen
en medio de la pantalla: eso rompería la lectura de trayectorias, que es toda
la habilidad del juego, y podría materializar un punto dentro de una detonación
activa regalando un contagio.

**La barra de tiempo.** La economía completa de `03-concepto-cadena.md`. El
marcador ya no se reinicia por cascada, se acumula durante toda la partida.

## Decisiones que resolvieron las preguntas abiertas

**La barra baja también durante la cascada**, pero la muerte solo se evalúa con
el tablero quieto: `_time_left <= 0` **y** ninguna detonación viva. Así un
último tap desesperado con la barra ya en cero todavía puede salvarte si atrapa
algo. Resuelve la pregunta abierta de `04-calibracion-v0.md` sin congelar nada,
y de regalo produce rescates in extremis, que son de los momentos que hacen
volver a jugar.

**La rampa de dificultad ataca la economía, no la estética.** Fue el hallazgo
importante de la fase. La primera versión solo subía la velocidad de los puntos
con el tiempo, y eso **no amenaza a nadie**: un jugador competente que espera
clusters saca ~7.5 s de barra por cada 1.5 s que gasta, y con ese 4x de retorno
la barra jamás lo alcanza. Medido: 4 minutos de partida sin una sola muerte, y
sin señal de que fuera a terminar nunca.

Un techo inmortal es el mismo defecto que el bucle de v0 con otra cara — sin
final no hay tensión y no hay razón para volver a intentarlo. La solución es
`drain_ramp_per_min`: el desagüe de la barra se acelera con los minutos, hasta
superar lo que cualquier ritmo de cosecha puede devolver.

## Medición

3 partidas por perfil, densidad equivalente al campo real, tope de 300 s:

| Perfil | Sobrevive | Puntúa |
|---|---|---|
| Descuidado (toca al azar en cuanto le baja la barra) | ~26 s | ~37 |
| Bueno (espera a ver 6 juntos) | ~185 s | ~462 |

7x de diferencia en supervivencia, 12x en puntuación, y **ambos mueren**. Es
la forma que se buscaba: el tap descuidado es pérdida neta, el tap paciente es
ganancia neta, y la rampa termina alcanzando a los dos.

Con una advertencia al leerlo: el jugador "bueno" simulado es sobrehumano —
busca el mejor cluster de toda la pantalla cada frame y reacciona sin latencia.
Un humano bueno quedará bastante por debajo de esos 3 minutos, que es
justamente donde debería estar una partida de arcade móvil.

## Valores actuales

| Parámetro | Valor |
|---|---|
| `time_start` / `time_max` | 10 s / 15 s |
| `tap_cost` | 1.5 s |
| `reward_base` | 0.6 s |
| `reward_step` (extra por punto de la misma cascada) | 0.12 s |
| `respawn_interval` | 0.4 s |
| `speed_ramp_per_min` | 40 px/s |
| `drain_ramp_per_min` | 0.5 |

## Pendiente

- **La aceleración del desagüe es invisible.** El jugador ve la barra bajar más
  rápido pero no sabe por qué. Hay que comunicarlo — es material de v2, junto
  al resto del game feel.
- Todo lo anterior mide reparto y supervivencia, **no diversión**. Si esperar
  al cluster resulta aburrido en vez de tenso, los números están bien y el
  juego está mal. Eso solo se sabe con el pulgar.
