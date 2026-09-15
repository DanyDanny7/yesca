"""Trocea los fondos entregados en las tres capas que usa el juego.

    python tools/separar_fondos.py entregas/<lote>
    godot --path . --headless --script tools/importar_fondos.gd -- entregas/<lote>

El primer paso escribe SVG en <lote>/_split/; el segundo los rasteriza a PNG en
arte/elasticas/, arte/fondos/ y arte/telones/, que es de donde lee el juego.

LAS TRES CAPAS
--------------
Se separan por CUANTA DEFORMACION TOLERA cada una, no por lo que son. Declarado
eso por adelantado, cualquier proporcion de pantalla se llena sin recortar nada
que importe.

  elastica  se estira a pantalla completa. Degradados, cielo, agua: cosas sin
            forma reconocible, que estiradas al doble de alto no las nota nadie.
  azulejo   se repite y se desplaza. Es lo que hace que la nieve caiga y el rio
            corra.
  rigida    se ancla abajo y NO se deforma. Banera, ciudad, planeta, horizonte.

COMO SE RECONOCEN
-----------------
El formato de entrega marca las dos primeras con un id explicito:

    <rect id="elastica" ...>   fondo que se estira
    <rect id="azulejo" ...>    el que lleva el patron

y todo lo que va DESPUES del azulejo es la capa rigida. Antes se adivinaba por
posicion -"el ultimo rect a lienzo completo"- y eso se rompia en cuanto un fondo
cambiaba de estructura. Con id explicito, no.

Un bioma puede no tener capa rigida: si no queda nada tras el azulejo, no se
escribe fichero y el bioma se dibuja con dos capas. Es lo normal en los biomas
que no tienen nada anclado.
"""
import glob
import io
import os
import re
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LOTE = sys.argv[1] if len(sys.argv) > 1 else "entregas/2026-09-02-ajuste-contrato"
SRC = os.path.join(RAIZ, LOTE, "fondos")
OUT = os.path.join(RAIZ, LOTE, "_split")

## Copias de un bioma que NO se trocean, con el motivo.
##
## La clave es `<lote>/<bioma>` cuando lo que sobra es esa copia concreta, y
## `<bioma>` a secas cuando el bioma no entra desde ningun lote. La diferencia
## importa: un bioma reentregado tiene una copia vieja que hay que saltarse y una
## nueva que hay que trocear, y las dos se llaman igual.
##
## En Asedio y Lluvia de meteoros el dibujo define DONDE SE PIERDE: el tejado
## mas alto es la linea de derrota y el disco de la Tierra es la zona de
## impacto. El arte de esta tanda no coincide con las constantes de fondo.gd, y
## meterlo dejaria al jugador perdiendo por tocar algo que no esta donde se ve.
## Se importan cuando cuadren las cifras.
AJUSTE = "2026-09-02-ajuste-contrato"
EXCLUIDOS = {
    "asedio": "el tejado del arte esta a 136 y ARTE_TEJADO vale 104",
    "lluvia_de_meteoros": "el planeta del arte es (62,-60,150) y ARTE_PLANETA es (26,-8,96)",
    # Estos cinco llegan YA PARTIDOS en la tanda por bioma, con las capas en
    # carpetas separadas. Trocearlos aqui los sobrescribiria con una version
    # peor: la del SVG unico, que es la que la revision vino a sustituir.
    AJUSTE + "/cielo_abierto": "viene ya partido en la tanda por bioma",
    AJUSTE + "/invierno": "viene ya partido en la tanda por bioma",
    AJUSTE + "/rio": "viene ya partido en la tanda por bioma",
    AJUSTE + "/hormigas": "viene ya partido en la tanda por bioma",
    AJUSTE + "/basico": "viene ya partido en la tanda por bioma",
    # Fiesta se reentrego entera el 09-14, con fondo de tres capas y dos piezas
    # rigidas. Trocear el boceto del 09-02 la pisaria con la version vieja.
    AJUSTE + "/fiesta": "la tanda del 09-14 trae el bioma entero",
    AJUSTE + "/billar": "la tanda del 09-14 trae el bioma entero",
}


def motivo_para_saltar(lote, bioma):
    """Por que no se trocea esta copia, o None si si se trocea."""
    corto = lote.strip("/").split("/")[-1]
    return EXCLUIDOS.get(corto + "/" + bioma) or EXCLUIDOS.get(bioma)

## A que capa va cada pieza rigida con nombre.
##
## La guirnalda es el unico caso del juego que cuelga de arriba en vez de
## apoyarse abajo, y por eso necesita capa propia: la rigida se ancla al borde
## inferior por definicion.
SUFIJO_PIEZA = {
    "suelo": "rigida",
    "guirnalda": "dosel",
}

CABECERA = ('<svg xmlns="http://www.w3.org/2000/svg" '
            'width="%d" height="%d" viewBox="%s">')
## Ancho al que se rasteriza la elastica.
##
## Estrecho a proposito: los degradados de fondo son verticales, asi que una
## tira fina contiene toda la informacion y el juego la estira a lo ancho de
## todos modos. Rasterizarla a 624 px de ancho seria diecisiete veces mas peso
## para el mismo resultado.
ANCHO_ELASTICA = 24
## A cuantas veces se rasteriza la tira elastica.
##
## El degradado se estira luego a la altura de la pantalla, asi que con pocas
## filas se bandea. Cuatro veces el ancho declarado da altura de sobra sin que
## la tira pese: un degradado vertical se comprime a casi nada.
RESOLUCION_ELASTICA = 4
## A cuantas veces su tamano se rasteriza el azulejo.
ESCALA_AZULEJO = 3


def sin_metadatos(svg):
    """Fuera la firma C2PA: son kilobytes que no dibujan nada."""
    return re.sub(r"<metadata>.*?</metadata>", "", svg, flags=re.S)


def atributo(etiqueta, nombre):
    m = re.search(r'\b%s="([^"]+)"' % nombre, etiqueta)
    return m.group(1) if m else None


def contenido_patron(svg, pid):
    """Las figuras de dentro de un <pattern>, para copiarlas al lienzo.

    Citar el patron con `fill="url(#id)"` es lo correcto en SVG y lo que hace el
    fichero entregado, pero el rasterizador de Godot no lo resuelve y devuelve un
    PNG transparente sin quejarse. Copiando las figuras se rasteriza una celda,
    que es justo lo que el juego repite luego.
    """
    m = re.search(r'<pattern id="%s"[^>]*>(.*?)</pattern>' % re.escape(pid), svg, re.S)
    if m is None or not m.group(1).strip():
        return None
    return m.group(1)


def azulejo_por_patron(svg):
    """El azulejo es el rect relleno con un <pattern>, lleve id o no lo lleve.

    Reconocerlo por lo que es y no por como se llama deja pasar entregas que no
    usan el id sin tener que negociar el formato cada vez.
    """
    for m in re.finditer(r'<rect[^>]*fill="url\(#([^)]+)\)"[^>]*></rect>', svg):
        if re.search(r'<pattern id="%s"' % re.escape(m.group(1)), svg):
            return m
    return None


def main():
    os.makedirs(OUT, exist_ok=True)
    print("%-20s %-11s %-11s %s" % ("bioma", "elastica", "azulejo", "capa rigida"))
    hechos = fuera = 0
    for ruta in sorted(glob.glob(os.path.join(SRC, "*.svg"))):
        bioma = os.path.splitext(os.path.basename(ruta))[0]
        salto = motivo_para_saltar(LOTE, bioma)
        if salto:
            print("%-20s -- NO SE IMPORTA: %s" % (bioma, salto))
            fuera += 1
            continue

        svg = sin_metadatos(io.open(ruta, encoding="utf-8").read())
        caja = atributo(svg[:svg.index(">")], "viewBox") or "0 0 208 500"
        ancho, alto = [float(v) for v in caja.replace(",", " ").split()[2:4]]

        defs = ""
        m = re.search(r"<defs>.*?</defs>", svg, re.S)
        if m:
            defs = m.group(0)

        az = re.search(r'<rect id="azulejo"[^>]*></rect>', svg) or azulejo_por_patron(svg)
        el = re.search(r'<rect id="elastica"[^>]*></rect>', svg)

        # 1 · elastica: lo que va ANTES del azulejo.
        #
        # Con `id="elastica"` es un solo rect y basta una tira estrecha: un
        # degradado vertical cabe entero en 24 px de ancho. Fiesta mete ademas
        # dos focos, que tienen sitio a lo ancho, y en una tira de 24 px se
        # convertirian en dos manchas del ancho de la pantalla. Cuando hay mas
        # de una figura se rasteriza al ancho del lienzo.
        cuerpo = svg[svg.index("</defs>") + len("</defs>"):] if defs else svg[svg.index(">") + 1:]
        # Sin azulejo, la elastica llega hasta donde empiecen las piezas rigidas,
        # y si tampoco las hay, hasta el final: el bioma es una sola capa.
        if el is not None:
            antes = el.group(0)
        elif az is not None:
            antes = cuerpo[:cuerpo.index(az.group(0))].strip()
        else:
            corte = cuerpo.find('<g id="pieza_')
            antes = (cuerpo if corte < 0 else cuerpo[:corte]).replace("</svg>", "").strip()
        figuras = len(re.findall(r"<[a-zA-Z]", antes))
        # Los dos ejes con la MISMA escala. Deformar el lienzo no da resolucion,
        # da una banda centrada con vacio arriba y abajo: el SVG encaja el
        # dibujo dentro sin estirarlo.
        esc = float(ANCHO_ELASTICA * RESOLUCION_ELASTICA) / ancho if figuras <= 1 else 1.0
        ancho_el = int(round(ancho * esc))
        alto_el = int(round(alto * esc))
        io.open(os.path.join(OUT, bioma + "__elastica.svg"), "w", encoding="utf-8").write(
            (CABECERA % (ancho_el, alto_el, caja)) + defs + antes + "</svg>")

        # 2 · azulejo: UNA repeticion del patron, sin color de fondo debajo.
        #     Sin color porque va encima de la elastica: si lo llevara, la
        #     taparia y la capa de abajo no serviria de nada.
        pw = ph = 0.0
        relleno = atributo(az.group(0), "fill") if az is not None else ""
        if az is not None:
            pid = re.search(r"url\(#([^)]+)\)", relleno or "")
            etiqueta = None
            if pid:
                m = re.search(r'<pattern id="%s"[^>]*>' % re.escape(pid.group(1)), svg)
                etiqueta = m.group(0) if m else None
            if etiqueta is None:
                print("%-20s -- el azulejo no apunta a un <pattern>" % bioma)
                fuera += 1
                continue
            pw = float(atributo(etiqueta, "width"))
            ph = float(atributo(etiqueta, "height"))
            dentro = contenido_patron(svg, pid.group(1))
            if dentro is None:
                print("%-20s -- el <pattern> esta vacio" % bioma)
                fuera += 1
                continue
            io.open(os.path.join(OUT, bioma + "__azulejo.svg"), "w", encoding="utf-8").write(
                (CABECERA % (pw * ESCALA_AZULEJO, ph * ESCALA_AZULEJO, "0 0 %g %g" % (pw, ph)))
                + defs + dentro + "</svg>")

        # 3 · rigidas: lo que va tras el azulejo, sobre fondo transparente.
        #
        # Si vienen con nombre, cada una a su capa: el suelo se ancla abajo como
        # siempre y la guirnalda arriba. Sin nombre, todo junto es la de abajo,
        # que es como se entrego hasta ahora.
        desde = az.end() if az is not None else svg.find('<g id="pieza_')
        resto = svg[desde:-len("</svg>")].strip() if desde >= 0 else ""
        piezas = dict(re.findall(
            r'<g id="pieza_(\w+)">(.*?)</g>', resto, re.S)) if resto else {}
        salidas = []
        if piezas:
            for nombre, dentro in sorted(piezas.items()):
                sufijo = SUFIJO_PIEZA.get(nombre)
                if sufijo is None:
                    print("%-20s -- pieza_%s sin capa asignada, se salta" % (bioma, nombre))
                    continue
                salidas.append((sufijo, dentro))
        elif resto:
            salidas.append(("rigida", resto))
        for sufijo, dentro in salidas:
            io.open(os.path.join(OUT, "%s__%s.svg" % (bioma, sufijo)), "w",
                    encoding="utf-8").write(
                (CABECERA % (ancho * 3, alto * 3, caja)) + defs + dentro + "</svg>")

        print("%-20s %-11s %-11s %s" % (
            bioma, "%dx%d" % (ancho_el, alto_el),
            "no lleva" if az is None else "%gx%g" % (pw * ESCALA_AZULEJO, ph * ESCALA_AZULEJO),
            "no tiene" if not salidas else "+".join(x[0] for x in salidas)))
        hechos += 1

    print("")
    print("%d biomas troceados, %d fuera" % (hechos, fuera))


if __name__ == "__main__":
    main()
