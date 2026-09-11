<#
.SYNOPSIS
    Lanza el proyecto sin depender de que 'godot' esté en el PATH.

.DESCRIPTION
    La búsqueda del ejecutable vive en buscar-godot.ps1, compartida con
    vigilar.ps1.

.EXAMPLE
    .\tools\run.ps1              # ejecuta el juego
    .\tools\run.ps1 -Editor      # abre el editor
    .\tools\run.ps1 -Calibrar    # corre el banco de calibración headless
    .\tools\run.ps1 -Nivel 12    # arranca ya dentro del nivel 12
    .\tools\vigilar.ps1          # ejecuta y relanza a cada cambio
#>
param(
    [switch]$Editor,
    [switch]$Calibrar,
    # Donde cae el juego al arrancar. Ver _arranque_directo() en scripts/main.gd.
    [int]$Nivel = 0,
    [switch]$SinFin,
    [ValidateSet('menu', 'seleccion', 'listo', 'jugando', 'derrota', 'victoria',
                 'final', 'pausa', 'log', 'briefing')]
    [string]$Pantalla,
    [switch]$SinMorir
)

$ErrorActionPreference = 'Stop'
$proyecto = Split-Path -Parent $PSScriptRoot
$godot = & "$PSScriptRoot\buscar-godot.ps1"

Write-Host "godot: $godot" -ForegroundColor DarkGray

# Detras de un "--" suelto empiezan los argumentos del juego, que Godot ya no
# interpreta y recoge OS.get_cmdline_user_args().
$destino = @()
if ($Nivel -gt 0) { $destino += "--nivel=$Nivel" }
if ($SinFin)      { $destino += '--sinfin' }
if ($Pantalla)    { $destino += "--pantalla=$Pantalla" }
if ($SinMorir)    { $destino += '--sin-morir' }

if ($Calibrar) {
    & $godot --headless --path $proyecto --script res://tools/calibracion.gd
} elseif ($Editor) {
    & $godot -e --path $proyecto
} elseif ($destino) {
    & $godot --path $proyecto -- @destino
} else {
    & $godot --path $proyecto
}
