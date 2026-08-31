<#
.SYNOPSIS
    Captura el log de Android mientras se reproduce un fallo en el teléfono.

.DESCRIPTION
    Sin el log, diagnosticar un cierre que solo ocurre en el móvil es adivinar.
    Este script limpia el buffer, se queda escuchando y guarda todo en un
    fichero. Se para con Ctrl+C.

.EXAMPLE
    .\tools\capturar-crash.ps1
    # 1. conecta el telefono por USB con la depuracion USB activada
    # 2. lanza este script
    # 3. abre el juego y reproduce el cierre
    # 4. Ctrl+C, y comparte build\crash.txt
#>
$ErrorActionPreference = 'Stop'
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
if (-not (Test-Path $adb)) { Write-Error "No encontre adb en $adb" }

$dispositivos = & $adb devices | Select-String -Pattern "device$"
if (-not $dispositivos) {
    Write-Error "Ningun telefono conectado. Conectalo por USB, activa la depuracion USB y acepta el aviso que sale en pantalla."
}
Write-Host "Dispositivo detectado." -ForegroundColor Green

$salida = Join-Path (Split-Path -Parent $PSScriptRoot) 'build\crash.txt'
New-Item -ItemType Directory -Force (Split-Path $salida) | Out-Null

& $adb logcat -c
Write-Host "Buffer limpio. Abre el juego y reproduce el cierre."
Write-Host "Cuando se cierre, pulsa Ctrl+C aqui.`n" -ForegroundColor Yellow
Write-Host "Guardando en: $salida" -ForegroundColor DarkGray

# godot: los print y errores del juego. AndroidRuntime y DEBUG: el volcado del
# crash nativo. *:E: cualquier otro error del sistema.
& $adb logcat -v time godot:V GodotEngine:V AndroidRuntime:E DEBUG:V libc:E *:E |
    Tee-Object -FilePath $salida
