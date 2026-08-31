"""Genera los efectos de sonido del juego por síntesis.

No hay assets externos y no hace falta ninguno: los cuatro sonidos que pide el
juego son cortos y sintéticos, así que se escriben aquí y quedan versionados
como código en vez de como binarios opacos. Cambiar el timbre es editar una
fórmula, no volver a buscar un sample.

Uso:
    python tools/generar_audio.py
"""

import math
import os
import random
import struct
import wave

TASA = 44100
SALIDA = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "audio")


def envolvente(t, dur, ataque=0.005):
    """Ataque muy corto y caída exponencial. El ataque casi instantáneo es lo
    que hace que el sonido se lea como un golpe y no como una nota."""
    if t < ataque:
        return t / ataque
    return math.exp(-5.0 * (t - ataque) / max(dur - ataque, 1e-6))


def escribir(nombre, muestras, tasa=TASA):
    os.makedirs(SALIDA, exist_ok=True)
    ruta = os.path.join(SALIDA, nombre)
    with wave.open(ruta, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(tasa)
        datos = b"".join(
            struct.pack("<h", int(max(-1.0, min(1.0, v)) * 32000)) for v in muestras
        )
        w.writeframes(datos)
    print("  %-18s %6.0f ms  %8d bytes" % (nombre, len(muestras) / tasa * 1000, len(datos)))


def pop(dur=0.09):
    """El contagio. Barrido descendente corto: suena a 'plop' seco."""
    n = int(TASA * dur)
    out = []
    for i in range(n):
        t = i / TASA
        f = 700.0 - 260.0 * (t / dur)
        out.append(math.sin(TAU * f * t) * 0.5 * envolvente(t, dur))
    return out


def fallo(dur=0.16):
    """El tap fallado. Grave y con ruido: se lee como error sin ser molesto."""
    n = int(TASA * dur)
    rnd = random.Random(7)
    out = []
    for i in range(n):
        t = i / TASA
        tono = math.sin(TAU * 130.0 * t) * 0.55
        ruido = (rnd.random() * 2.0 - 1.0) * 0.25
        out.append((tono + ruido) * envolvente(t, dur, 0.002))
    return out


def cadena(dur=0.35):
    """El hito de cadena larga. Dos voces en quinta, que suena a premio."""
    n = int(TASA * dur)
    out = []
    for i in range(n):
        t = i / TASA
        v = math.sin(TAU * 880.0 * t) * 0.4 + math.sin(TAU * 1320.0 * t) * 0.25
        out.append(v * envolvente(t, dur, 0.004))
    return out


def fin(dur=0.6):
    """El final de partida. Caída larga de tono: se lee como derrota."""
    n = int(TASA * dur)
    out = []
    for i in range(n):
        t = i / TASA
        f = 420.0 * math.pow(0.25, t / dur)
        out.append(math.sin(TAU * f * t) * 0.5 * envolvente(t, dur, 0.01))
    return out


# --- música ----------------------------------------------------------------
#
# 22050 Hz basta: un pad y un bajo no tienen contenido agudo que perder, y a
# 44100 el fichero pesaría el doble por nada.
TASA_MUS = 22050

# La (menor). Do sostenido nada, todo natural.
NOTAS = {"A2": 110.00, "C3": 130.81, "E3": 164.81, "F2": 87.31, "G2": 98.00,
         "A3": 220.00, "B3": 246.94, "C4": 261.63, "D4": 293.66, "E4": 329.63,
         "F4": 349.23, "G4": 392.00, "A4": 440.00, "C5": 523.25}

# Am - F - C - G. La progresión más manida que existe, y por eso funciona de
# fondo: nadie le presta atención, que es justo lo que se le pide a la música
# de un juego donde el sonido importante son los eslabones de la cadena.
PROGRESION = [
    ("A2", ["C4", "E4", "A4"]),
    ("F2", ["A3", "C4", "F4"]),
    ("C3", ["E4", "G4", "C5"]),
    ("G2", ["B3", "D4", "G4"]),
]


def musica(bpm=80.0, compases=4):
    """Bucle de fondo, sin batería y en volumen bajo.

    Tiene que caber por debajo de los efectos sin pelearse con ellos: los pops
    del juego son agudos y con ataque seco, así que la música es grave, de
    ataque lento y sin nada que compita en esa banda.

    La duración sale exacta a propósito (80 bpm, 4 tiempos por compás = 3 s por
    compás) para que el bucle cierre sin salto. Y todas las envolventes mueren
    dentro de su compás, o al empalmar el final con el principio se oiría un
    chasquido.
    """
    dur_compas = 60.0 / bpm * 4.0
    n_compas = int(TASA_MUS * dur_compas)
    out = []
    for c in range(compases):
        raiz, triada = PROGRESION[c % len(PROGRESION)]
        f_raiz = NOTAS[raiz]
        for i in range(n_compas):
            t = i / TASA_MUS
            v = 0.0

            # Bajo: una nota por compás, con cuerpo y caída lenta.
            env_bajo = math.exp(-2.2 * t / dur_compas) * (1.0 - math.exp(-t * 40.0))
            v += math.sin(TAU * f_raiz * t) * 0.30 * env_bajo

            # Pad: la tríada con ataque lento. Dos osciladores por nota,
            # ligeramente desafinados, que es lo que le da anchura.
            env_pad = math.sin(math.pi * min(t / dur_compas, 1.0)) ** 1.4
            for f in (NOTAS[n] for n in triada):
                v += math.sin(TAU * f * t) * 0.055 * env_pad
                v += math.sin(TAU * f * 1.004 * t) * 0.045 * env_pad

            # Pulso: una nota pulsada por tiempo, subiendo por la tríada. Es lo
            # único que marca el ritmo.
            tiempo = dur_compas / 4.0
            k = int(t / tiempo)
            tt = t - k * tiempo
            f_arp = NOTAS[triada[k % len(triada)]] * 2.0
            v += math.sin(TAU * f_arp * tt) * 0.10 * math.exp(-9.0 * tt / tiempo)

            out.append(v * 0.85)
    return out


def alarma(dur=0.11):
    """Pitido de tiempo bajo.

    Tiene que cortar por encima de la musica y de los pops sin taparlos: por eso
    es corto, agudo y con un armonico impar que lo hace nasal. Un tono limpio a
    este volumen se confundiria con un eslabon mas de la cadena.
    """
    n = int(TASA * dur)
    out = []
    for i in range(n):
        t = i / TASA
        v = math.sin(TAU * 1180.0 * t) * 0.5
        v += math.sin(TAU * 3540.0 * t) * 0.12
        out.append(v * envolvente(t, dur, 0.003))
    return out


def exito(dur=0.75):
    """Fanfarria de victoria: arpegio ascendente de Do mayor y acorde final.

    Sube, que es lo unico que hace falta para que se lea como logro. El acorde
    del final sostiene para que la celebracion no se corte en seco.
    """
    n = int(TASA * dur)
    notas = [523.25, 659.25, 783.99, 1046.50]  # do mi sol do
    paso = dur * 0.16
    out = []
    for i in range(n):
        t = i / TASA
        v = 0.0
        for k, f in enumerate(notas):
            inicio = k * paso
            if t < inicio:
                continue
            tt = t - inicio
            v += math.sin(TAU * f * tt) * 0.22 * math.exp(-2.6 * tt)
        # acorde sostenido por debajo, para que no quede hueco al final
        if t > paso * 3.0:
            ta = t - paso * 3.0
            for f in (523.25, 659.25, 783.99):
                v += math.sin(TAU * f * ta) * 0.07 * math.exp(-1.6 * ta)
        out.append(v * 0.9)
    return out


TAU = math.pi * 2.0

if __name__ == "__main__":
    print("generando en", SALIDA)
    escribir("pop.wav", pop())
    escribir("fallo.wav", fallo())
    escribir("cadena.wav", cadena())
    escribir("fin.wav", fin())
    escribir("alarma.wav", alarma())
    escribir("exito.wav", exito())
    # Nombrada por bioma desde ya: cuando cada bioma tenga su pista, basta con
    # añadir funciones al lado y una entrada en el diccionario de main.gd.
    escribir("musica_campo.wav", musica(), TASA_MUS)
