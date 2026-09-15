# -*- coding: utf-8 -*-
"""Busca texto visible que siga escrito dentro del codigo.

Un idioma nuevo se anade tocando solo `datos/idiomas/`. Cualquier palabra que se
quede en un .gd o en la escena rompe esa promesa sin avisar: no falla, sale en
castellano. Esto la encuentra.

    python tools/auditar-idioma.py

Sale con codigo 1 si encuentra algo, para poder colgarlo de una comprobacion.
"""
from __future__ import print_function
import io
import json
import os
import re
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# El titulo es el nombre del juego. No se traduce, igual que no se traduce en la
# tienda ni en el icono.
NOMBRE_PROPIO = ['UI/MenuScreen/Title']

# Lo que llega al jugador: una etiqueta de la escena o una llamada de dibujo.
VISIBLE = re.compile(
    r'(\.text\s*=|_texto_centrado(?:_px)?\(|_texto_en\(|draw_string\w*\('
    r'|_flash\(|_boton\(|_enlace\()')
LITERAL = re.compile(r'"((?:[^"\\]|\\.)*)"')

# Un literal sin letras no es texto: son formatos, simbolos y numeros.
TIENE_PALABRA = re.compile(u'[A-Za-zÀ-ſ]{3,}')
# Nombres de clave, rutas y llamadas no son texto que se lea.
EXENTO = re.compile(r'^[a-z0-9_]+$|^res://|^user://|%[ds]$')

ONREADY = re.compile(r'@onready var (\w+)[^=]*= \$(\S+)')
ESCRITA = r'%s(?:\.text)? *= *(?:Textos\.|Niveles\.|str\(|texto\b)'


def _cubiertos(main_gd):
    """Nodos de la escena cuyo texto fijo es solo un marcador de posicion.

    Estan cubiertos de dos maneras: porque `_rotular` los reescribe al arrancar,
    o porque el codigo los pisa a traves de una variable. Lo segundo hay que
    resolverlo, porque el nodo se llama por su ruta en la escena y por el nombre
    de la variable en el codigo.
    """
    fuera = set(NOMBRE_PROPIO)
    cuerpo = main_gd.split('func _rotular() -> void:')[1].split('\nfunc ')[0]
    for m in re.finditer(r'\$UI/([^.]+)\.text', cuerpo):
        fuera.add('UI/' + m.group(1))
    for m in ONREADY.finditer(main_gd):
        variable, ruta = m.group(1), m.group(2)
        if re.search(ESCRITA % re.escape(variable), main_gd):
            fuera.add(ruta)
            fuera.add(ruta + '/Text')
    return fuera


def main():
    fallos = []

    for nombre in sorted(os.listdir(os.path.join(RAIZ, 'scripts'))):
        if not nombre.endswith('.gd'):
            continue
        ruta = os.path.join('scripts', nombre)
        for i, linea in enumerate(
                io.open(os.path.join(RAIZ, ruta), encoding='utf-8'), 1):
            if linea.lstrip().startswith('#') or not VISIBLE.search(linea):
                continue
            for lit in LITERAL.findall(linea):
                if TIENE_PALABRA.search(lit) and not EXENTO.match(lit):
                    fallos.append((ruta, i, lit))

    main_gd = io.open(os.path.join(RAIZ, 'scripts/main.gd'), encoding='utf-8').read()
    cubiertos = _cubiertos(main_gd)

    nodo = None
    for i, linea in enumerate(
            io.open(os.path.join(RAIZ, 'main.tscn'), encoding='utf-8'), 1):
        m = re.match(r'\[node name="([^"]+)" type="\w+" parent="([^"]*)"', linea)
        if m:
            nodo = (m.group(2) + '/' + m.group(1)).lstrip('/')
        if linea.startswith('text = "'):
            lit = linea[8:].rstrip().rstrip('"')
            if TIENE_PALABRA.search(lit) and nodo not in cubiertos:
                fallos.append(('main.tscn', i, '%s = %s' % (nodo, lit)))

    # Y las tablas tienen que llevar exactamente las mismas claves.
    tablas = {}
    dir_idiomas = os.path.join(RAIZ, 'datos/idiomas')
    for nombre in sorted(os.listdir(dir_idiomas)):
        if nombre.endswith('.json'):
            tablas[nombre[:-5]] = json.load(
                io.open(os.path.join(dir_idiomas, nombre), encoding='utf-8'))
    referencia = set(tablas['es'])
    for codigo, tabla in sorted(tablas.items()):
        falta = referencia - set(tabla)
        sobra = set(tabla) - referencia
        if falta or sobra:
            fallos.append(('datos/idiomas/%s.json' % codigo, 0,
                           'faltan %s / sobran %s' % (sorted(falta), sorted(sobra))))

    if fallos:
        print('Texto sin traducir (%d):' % len(fallos))
        for ruta, linea, que in fallos:
            print('  %s:%s  %s' % (ruta, linea, que))
        return 1
    print('Sin texto suelto. %d claves x %d idiomas.' % (
        len(referencia), len(tablas)))
    return 0


if __name__ == '__main__':
    sys.exit(main())
