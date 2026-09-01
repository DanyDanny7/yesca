"""Trocea los fondos entregados en las dos capas que usa el juego.

    python tools/separar_fondos.py
    godot --path . --headless --script tools/importar_fondos.gd

El primer paso escribe SVG en arte/assets-yesca/_split/; el segundo los
rasteriza a PNG en arte/fondos/ y arte/telones/.

POR QUE DOS CAPAS
-----------------
Los fondos vienen compuestos en un lienzo de 208x336, y ese lienzo no tiene la
proporcion de ninguna pantalla. Estirarlos para que encajen no es una opcion:
cada fondo mezcla una parte que aguanta el estirado con otra que no.

  - El PATRON se repite. Estirarlo da igual, y ademas repitiendolo se puede
    desplazar, que es lo que hace que la nieve caiga y el rio corra.
  - La PIEZA ANCLADA -la banera de Ducha, la ciudad de Asedio, la Tierra de
    Meteoros- tiene sitio fijo. Una banera al doble de ancho deja de ser una
    banera.

Asi que se separan: el patron sale como azulejo y la pieza anclada como una
composicion que se ancla abajo y se escala solo por el ancho.

EL CORTE
--------
En el SVG las dos capas ya vienen separadas y en ese orden: primero los <rect>
a lienzo completo (color de fondo y patron), despues todo lo demas. El corte es
el ultimo rect a lienzo completo.

Siete de los diecisiete no traen <pattern>: su fondo esta dibujado forma a
forma. Esos no tienen nada que repetir y suben enteros como composicion; el
azulejo se lo sintetiza importar_fondos.gd con el color de su fila superior,
que es justo el que toca el hueco de arriba cuando la pantalla es mas alta.
"""
import io
import os
import re
import glob

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(RAIZ, "arte", "assets-yesca", "fondos")
OUT = os.path.join(RAIZ, "arte", "assets-yesca", "_split")

# Del nombre del fichero entregado al bioma del juego. Ojo con dos: el 05 se
# renombro a Basico, y el 09 lleva enye en el juego pero no en el fichero.
BIOMA = {
    "01_cielo_abierto": "cielo_abierto", "02_invierno": "invierno",
    "03_rio": "rio", "04_hormigas": "hormigas", "05_enjambre": "basico",
    "06_billar": "billar", "07_panal": "panal", "08_estampida": "estampida",
    "09_otono": "otono", "10_brasas": "brasas",
    "11_caza_de_robots": "caza_de_robots", "12_circuito": "circuito",
    "13_ciudad_de_papel": "ciudad_de_papel", "14_ducha": "ducha",
    "15_fiesta": "fiesta", "16_asedio": "asedio",
    "17_lluvia_de_meteoros": "lluvia_de_meteoros",
}
CABECERA = ('<svg xmlns="http://www.w3.org/2000/svg" '
            'width="%d" height="%d" viewBox="0 0 %s %s">')
LIENZO = (208, 336)


def main():
    os.makedirs(OUT, exist_ok=True)
    print("%-20s %-10s %s" % ("bioma", "azulejo", "capa de encima"))
    for ruta in sorted(glob.glob(os.path.join(SRC, "*.svg"))):
        base = os.path.splitext(os.path.basename(ruta))[0]
        if base not in BIOMA:
            print("  %s: no se a que bioma corresponde, se salta" % base)
            continue
        bioma = BIOMA[base]
        svg = io.open(ruta, encoding="utf-8").read()

        defs = ""
        m = re.search(r"<defs>.*?</defs>", svg, re.S)
        if m:
            defs = m.group(0)

        ultimo = None
        for r in re.finditer(r'<rect width="208" height="336"[^>]*></rect>', svg):
            ultimo = r
        resto = svg[ultimo.end():-len("</svg>")] if ultimo else ""

        solido = ""
        m = re.search(r'<rect width="208" height="336" fill="(#[0-9a-fA-F]+)"></rect>', svg)
        if m:
            solido = m.group(1)

        pat = re.search(r'<pattern id="([^"]+)" width="(\d+)" height="(\d+)"', svg)

        if pat:
            pid, pw, ph = pat.group(1), int(pat.group(2)), int(pat.group(3))
            # Una sola repeticion del patron, a 3x, que es la escala a la que
            # estan hechos los PNG de la entrega.
            tile = (CABECERA % (pw * 3, ph * 3, pw, ph)) + defs
            if solido:
                tile += '<rect width="%d" height="%d" fill="%s"></rect>' % (pw, ph, solido)
            tile += '<rect width="%d" height="%d" fill="url(#%s)"></rect></svg>' % (pw, ph, pid)
            io.open(os.path.join(OUT, bioma + "__tile.svg"), "w",
                    encoding="utf-8").write(tile)
            capa = (CABECERA % (624, 1008, LIENZO[0], LIENZO[1])) + defs + resto + "</svg>"
        else:
            capa = svg

        io.open(os.path.join(OUT, bioma + "__capa.svg"), "w",
                encoding="utf-8").write(capa)
        print("%-20s %-10s %s" % (
            bioma,
            "%dx%d" % (int(pat.group(2)), int(pat.group(3))) if pat else "—",
            "vacia" if not resto.strip() else "%d bytes" % len(resto)))


if __name__ == "__main__":
    main()
