# Decisiones

Actualizado: 2026-08-30

## Cerradas

**Motor: Godot 4.x (GDScript).**
Razones: 2D de primera clase, editor ligero y portable, sin licencias ni
royalties, APK de salida pequeño (~25-30 MB), export a Android directo desde
el editor. Se descarta Unity por peso y fricción de setup, Flutter/Flame por
no aportar nada aquí, Unreal por sobredimensionado.
GDScript sobre C# porque el export a Android con .NET es más frágil.

**Plataforma: Android primero.**
Publicación en Google Play. iOS queda fuera de alcance por ahora.

**Objetivo: gusto propio, no portafolio.**
El criterio de éxito es que enganche. Si resulta pegajoso → Play Store con
publicidad. Si no → se publica igual, sin anuncios, para tenerlo terminado.
Esto significa que NO se optimiza para "quedar bien en un GIF" ni para
demostrar músculo técnico. Se optimiza para el "una más".

**Alcance: arcade endless con score.**
Consecuencia directa del objetivo. Quedan descartados los géneros con hambre
de contenido — puzzle con niveles a mano, RPG, cualquier cosa que exija
producir 40 niveles o texto. El contenido tiene que escalar solo:
procedural, endless, emergente.

## Contexto del desarrollador

Dev con experiencia. Ya conoce el flujo completo de publicación y testeo en
Play Store por otras apps, así que no hace falta un proyecto de prueba para
recorrerlo. Sin experiencia previa en desarrollo de juegos.

Lo que sí es terreno nuevo:
- Game loop y `delta` — todo movimiento escalado por tiempo de frame
- Composición por escenas y nodos en vez de herencia profunda
- Múltiples resoluciones y aspect ratios (`canvas_items` + `expand`)
- Input táctil: gestos, zona segura, notch, el dedo tapando la pantalla
- Game feel — es la disciplina central, no un detalle final

## Abiertas

- Concepto definitivo (ver `02-conceptos.md`)
- Nombre real del proyecto (depende del concepto)
- Estilo visual (depende del concepto)
