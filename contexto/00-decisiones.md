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

**Cielo abierto mezcla estrellas y chispas.** (2026-08-31)
Decidido, sin construir. Dos formas en el mismo bioma, sorteadas por objetivo.

Es el primer sitio del juego donde un bioma no equivale a una silueta, y por eso
se prueba justo aquí: en el nivel más calmado, donde si dos formas confunden en
vez de enriquecer se ve enseguida y con poco en juego.

No es una línea como lo fue el misil. Hace falta que la paleta pueda declarar
varias formas y que se elija una por objetivo —en `_preparar_dot`, junto a la
variedad por instancia que ya existe— y acordarse del barrido del modo sin fin,
que reasigna la forma de cada objetivo al pasar y también tendría que sortear.

**Asedio dispara misiles, no balas.** (2026-08-31)
Aplicado. Una bala es munición de arma corta: se lee como algo disparado a
alguien, no como algo que cae sobre una ciudad. Un misil trae su propia
narrativa —viene de lejos, va dirigido, y explota al llegar— y es la que el
bioma ya cuenta con el horizonte roto ardiendo de fondo.

Costó una línea, porque `Dot.Forma.MISIL` llevaba tiempo dibujada y huérfana.
Se le bajó el dibujo un 12%: salía más largo y más plano que la bala y
desentonaba con el resto del campo. El ajuste va en el dibujo y no en el radio
de la paleta, que gobierna los contagios: cambiarlo movería el balance del bioma
por un motivo puramente estético.

**Nombre: Yesca.** (2026-08-31)
El proyecto se llamó `juego-test-1` mientras el concepto estaba sin validar, y
el concepto se llamó *Cadena* por su mecánica. Publicarlo obligó a separar las
dos cosas: si el juego se llama Cadena, entonces «mejor cadena ×7» dentro de la
partida es ambiguo, y las 168 menciones de la palabra en el repo no se pueden
leer sin contexto. Yesca nombra el producto y deja *cadena* para la mecánica.

De las candidatas —Traca, Mecha, Racha, Candela, Centella— pesó que Yesca es la
más corta, la más difícil de confundir con otra cosa y, por accidente, la que
mejor arranca en inglés: se lee *YES-kuh*.

**Concepto: Cadena.**
Detonación en cascada sobre un campo de puntos, con una barra de tiempo como
única economía: tocar cuesta, atrapar devuelve. Ver `03-concepto-cadena.md`.
Sigue sujeto a validación por prototipo — si v1 no genera tensión, se cae.

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

- Nombre real del proyecto (depende del concepto)
- Estilo visual (depende del concepto)
