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

## Biomas que NO se importan, con el motivo.
##
## En Asedio y Lluvia de meteoros el dibujo define DONDE SE PIERDE: el tejado
## mas alto es la linea de derrota y el disco de la Tierra es la zona de
## impacto. El arte de esta tanda no coincide con las constantes de fondo.gd, y
## meterlo dejaria al jugador perdiendo por tocar algo que no esta donde se ve.
## Se importan cuando cuadren las cifras.
EXCLUIDOS = {
    "asedio": "el tejado del arte esta a 136 y ARTE_TEJADO vale 104",
    "lluvia_de_meteoros": "el planeta del arte es (62,-60,150) y ARTE_PLANETA es (26,-8,96)",
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
## A cuantas veces su tamano se rasteriza el azulejo.
ESCALA_AZULEJO = 3


def sin_metadatos(svg):
    """Fuera la firma C2PA: son kilobytes que no dibujan nada."""
    return re.sub(r"<metadata>.*?</metadata>", "", svg, flags=re.S)


def atributo(etiqueta, nombre):
    m = re.search(r'\b%s="([^"]+)"' % nombre, etiqueta)
    return m.group(1) if m else None


def main():
    os.makedirs(OUT, exist_ok=True)
    print("%-20s %-11s %-11s %s" % ("bioma", "elastica", "azulejo", "capa rigida"))
    hechos = fuera = 0
    for ruta in sorted(glob.glob(os.path.join(SRC, "*.svg"))):
        bioma = os.path.splitext(os.path.basename(ruta))[0]
        if bioma in EXCLUIDOS:
            print("%-20s -- NO SE IMPORTA: %s" % (bioma, EXCLUIDOS[bioma]))
            fuera += 1
            continue

        svg = sin_metadatos(io.open(ruta, encoding="utf-8").read())
        caja = atributo(svg[:svg.index(">")], "viewBox") or "0 0 208 500"
        ancho, alto = [float(v) for v in caja.replace(",", " ").split()[2:4]]

        defs = ""
        m = re.search(r"<defs>.*?</defs>", svg, re.S)
        if m:
            defs = m.group(0)

        el = re.search(r'<rect id="elastica"[^>]*></rect>', svg)
        az = re.search(r'<rect id="azulejo"[^>]*></rect>', svg)
        if el is None or az is None:
            print("%-20s -- SIN id=elastica o id=azulejo, no se puede trocear" % bioma)
            fuera += 1
            continue

        # 1 · elastica: el degradado solo, en una tira estrecha.
        alto_el = int(round(ANCHO_ELASTICA * alto / ancho)) * 4
        io.open(os.path.join(OUT, bioma + "__elastica.svg"), "w", encoding="utf-8").write(
            (CABECERA % (ANCHO_ELASTICA, alto_el, caja)) + defs + el.group(0) + "</svg>")

        # 2 · azulejo: UNA repeticion del patron, sin color de fondo debajo.
        #     Sin color porque va encima de la elastica: si lo llevara, la
        #     taparia y la capa de abajo no serviria de nada.
        relleno = atributo(az.group(0), "fill") or ""
        pid = re.search(r"url\(#([^)]+)\)", relleno)
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
        io.open(os.path.join(OUT, bioma + "__azulejo.svg"), "w", encoding="utf-8").write(
            (CABECERA % (pw * ESCALA_AZULEJO, ph * ESCALA_AZULEJO, "0 0 %g %g" % (pw, ph)))
            + defs
            + '<rect width="%g" height="%g" fill="url(#%s)"></rect></svg>' % (pw, ph, pid.group(1)))

        # 3 · rigida: lo que va tras el azulejo, sobre fondo transparente.
        resto = svg[az.end():-len("</svg>")].strip()
        if resto:
            io.open(os.path.join(OUT, bioma + "__rigida.svg"), "w", encoding="utf-8").write(
                (CABECERA % (ancho * 3, alto * 3, caja)) + defs + resto + "</svg>")

        print("%-20s %-11s %-11s %s" % (
            bioma, "%dx%d" % (ANCHO_ELASTICA, alto_el),
            "%gx%g" % (pw * ESCALA_AZULEJO, ph * ESCALA_AZULEJO),
            "no tiene" if not resto else "%d bytes" % len(resto)))
        hechos += 1

    print("")
    print("%d biomas troceados, %d fuera" % (hechos, fuera))


if __name__ == "__main__":
    main()
