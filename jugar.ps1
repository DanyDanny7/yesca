<#
.SYNOPSIS
    Atajo para jugar. Un solo argumento: donde quieres caer.

.DESCRIPTION
    Envoltorio fino sobre tools/vigilar.ps1. Existe porque el comando util de
    verdad -vigilar y relanzar cayendo en un nivel concreto- se escribe muchas
    veces al dia, y ".\tools\vigilar.ps1 -Nivel 12 -SinMorir" tiene demasiadas
    piezas que recordar para algo tan repetido.

    El argumento acepta las dos cosas, numero de nivel o nombre de pantalla,
    a proposito: tener que acordarse de cual lleva -Nivel y cual -Pantalla es
    exactamente la friccion que este atajo viene a quitar.

.EXAMPLE
    .\jugar.ps1              # vigila y relanza, entrando por el menu
    .\jugar.ps1 12           # igual, pero cada reinicio cae en el nivel 12
    .\jugar.ps1 derrota      # igual, con la pantalla de derrota a la vista
    .\jugar.ps1 12 -SinMorir # el nivel 12 sin que te maten mientras miras
    .\jugar.ps1 12 -Una      # una sola ejecucion, sin vigilante
    .\jugar.ps1 derrota -Nivel 5   # esa pantalla, con datos del nivel 5
#>
param(
    # Numero de nivel -contando desde 1, como los ensena el juego- o nombre de
    # pantalla: menu, seleccion, listo, jugando, derrota, victoria, final,
    # pausa, log, briefing.
    [Parameter(Position = 0)]
    [string]$Donde = '',
    # Solo hace falta para combinar pantalla Y nivel: las pantallas que ensenan
    # datos de partida -derrota, victoria, pausa- se leen distinto segun el
    # nivel que haya debajo.
    [int]$Nivel = 0,
    # Ejecuta y sale, en vez de quedarse vigilando cambios.
    [switch]$Una,
    [switch]$SinFin,
    [switch]$SinMorir
)

$ErrorActionPreference = 'Stop'

$extra = @{}
if ($Donde -match '^[0-9]+$') {
    $extra['Nivel'] = [int]$Donde
} elseif ($Donde) {
    $extra['Pantalla'] = $Donde
}
# -Nivel explicito manda sobre el numero posicional: si se escriben los dos, el
# que lleva nombre es el que se puso a proposito.
if ($Nivel -gt 0) { $extra['Nivel'] = $Nivel }
if ($SinFin)   { $extra['SinFin'] = $true }
if ($SinMorir) { $extra['SinMorir'] = $true }

if ($Una) {
    & "$PSScriptRoot\tools\run.ps1" @extra
} else {
    & "$PSScriptRoot\tools\vigilar.ps1" @extra
}
