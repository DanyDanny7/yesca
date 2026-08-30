<#
.SYNOPSIS
    Lanza el proyecto sin depender de que 'godot' esté en el PATH.

.DESCRIPTION
    Existe porque una terminal abierta antes de instalar Godot hereda el PATH
    viejo y 'godot' no se resuelve, aunque la entrada ya esté en el registro.
    Este script busca el ejecutable en los sitios habituales.

.EXAMPLE
    .\tools\run.ps1              # ejecuta el juego
    .\tools\run.ps1 -Editor      # abre el editor
    .\tools\run.ps1 -Calibrar    # corre el banco de calibración headless
#>
param(
    [switch]$Editor,
    [switch]$Calibrar
)

$ErrorActionPreference = 'Stop'
$proyecto = Split-Path -Parent $PSScriptRoot

# Se prefiere la build _console: la normal es GUI y NO escribe nada en la
# terminal, así que ni los print() de GDScript ni los errores de runtime se
# ven. Depurar a ciegas no es una opción.
$candidatos = @(
    "$env:LOCALAPPDATA\Microsoft\WinGet\Links\godot_console.exe"
    (Get-Command godot_console -ErrorAction SilentlyContinue).Source
    (Get-Command godot -ErrorAction SilentlyContinue).Source
    "$env:LOCALAPPDATA\Microsoft\WinGet\Links\godot.exe"
) + (
    Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Filter 'Godot_v*_win64_console.exe' `
        -Recurse -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
)

$godot = $candidatos | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1

if (-not $godot) {
    Write-Error "No encontré Godot. Instálalo con: winget install GodotEngine.GodotEngine"
}

Write-Host "godot: $godot" -ForegroundColor DarkGray

if ($Calibrar) {
    & $godot --headless --path $proyecto --script res://tools/calibracion.gd
} elseif ($Editor) {
    & $godot -e --path $proyecto
} else {
    & $godot --path $proyecto
}
