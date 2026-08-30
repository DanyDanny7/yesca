# Criterios de diseño

Checklist. Cualquier concepto que siga en pie tiene que poder cumplir todo
esto, y cualquier decisión de implementación se valida contra esta lista.

## El bucle pegajoso

- [ ] **Menos de 3 segundos hasta jugar.** Sin logo animado, sin menú previo,
      sin tutorial. Se abre la app y se está dentro.
- [ ] **Reinicio en un tap.** Muere → toca → juega. Nada de pantalla de
      resultados con animación de dos segundos: eso mata el impulso.
- [ ] **La muerte es culpa del jugador y es legible.** Tiene que saber
      exactamente qué hizo mal. Si siente que fue el juego, cierra la app.
- [ ] **Un número y un récord siempre visibles.** El motor del reintento es
      la cercanía al propio best.
- [ ] **Techo de habilidad real.** Se tiene que notar que uno mejora. Si el
      resultado depende del azar, se agota en diez minutos.
- [ ] **La dificultad sube dentro de la partida**, no entre partidas.

## Game feel

Aquí vive literalmente lo adictivo. Dos juegos con la misma mecánica exacta,
uno enganchado y otro muerto, se diferencian solo en esto. Va a llevar más
tiempo del que parece y no es una fase de pulido final: es la mecánica.

- Impacto: hit stop de 2-4 frames en el golpe
- Screen shake proporcional al evento (y con tope, o marea)
- Partículas y feedback de color por estado
- Vibración háptica corta
- Sonido con variación de pitch para que no canse a la repetición 200
- Curvas de easing en todo lo que se mueva en la UI

## Monetización (solo si engancha)

Modelo compatible con sesión corta y repetida:

- **Video recompensado** para revivir en el punto de muerte
- **Video recompensado** para doblar las monedas de la partida
- **Intersticial** cada N partidas, nunca al inicio
- Requiere una meta-progresión mínima (monedas → skins) para sostener la
  retención del día 3 y para darle sentido al video recompensado

No se implementa nada de esto hasta que el prototipo demuestre que engancha.

## Restricciones de producción

- **El arte es el cuello de botella, no el código.** El estilo se elige para
  ser producible por una persona sin habilidad de dibujo, y tiene que verse
  intencional: siluetas monocromas, geométrico plano, un solo color de
  acento, wireframe. Nunca "arte malo con excusa".
- **Un solo gancho bien pulido** antes que cinco sistemas a medias.
