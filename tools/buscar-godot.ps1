<#
.SYNOPSIS
    Devuelve la ruta del ejecutable de Godot.

.DESCRIPTION
    Extraido de run.ps1 para que vigilar.ps1 no duplique la busqueda. Existe
    porque una terminal abierta antes de instalar Godot hereda el PATH viejo y
    'godot' no se resuelve, aunque la entrada ya este en el registro.

    Se prefiere la build _console: la normal es GUI y NO escribe nada en la
    terminal, asi que ni los print() de GDScript ni los errores de runtime se
    ven. Depurar a ciegas no es una opcion.
#>
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
    Write-Error "No encontre Godot. Instalalo con: winget install GodotEngine.GodotEngine"
}

$godot
