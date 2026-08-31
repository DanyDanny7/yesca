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


def escribir(nombre, muestras):
    os.makedirs(SALIDA, exist_ok=True)
    ruta = os.path.join(SALIDA, nombre)
    with wave.open(ruta, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(TASA)
        datos = b"".join(
            struct.pack("<h", int(max(-1.0, min(1.0, v)) * 32000)) for v in muestras
        )
        w.writeframes(datos)
    print("  %-14s %5.0f ms  %6d bytes" % (nombre, len(muestras) / TASA * 1000, len(datos)))


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


TAU = math.pi * 2.0

if __name__ == "__main__":
    print("generando en", SALIDA)
    escribir("pop.wav", pop())
    escribir("fallo.wav", fallo())
    escribir("cadena.wav", cadena())
    escribir("fin.wav", fin())
