<#
.SYNOPSIS
    Genera el APK de depuración y verifica que quede bien firmado.

.EXAMPLE
    .\tools\build-apk.ps1
    .\tools\build-apk.ps1 -Release

.NOTES
    Requiere el entorno montado una sola vez (ver "Android" en el README):
    JDK 17, Android SDK con build-tools, keystore de depuración y las
    plantillas de exportación de Godot.
#>
param(
    [switch]$Release
)

$ErrorActionPreference = 'Stop'
$proyecto = Split-Path -Parent $PSScriptRoot
$salida = Join-Path $proyecto 'build\cadena-debug.apk'

# Se prefiere la build _console: la normal es GUI y no escribe nada en la
# terminal, así que los errores de exportación pasarían desapercibidos.
$candidatos = @(
    "$env:LOCALAPPDATA\Microsoft\WinGet\Links\godot_console.exe"
    (Get-Command godot_console -ErrorAction SilentlyContinue).Source
    (Get-Command godot -ErrorAction SilentlyContinue).Source
)
$godot = $candidatos | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
if (-not $godot) { Write-Error "No encontré Godot. Ver el README." }

New-Item -ItemType Directory -Force (Join-Path $proyecto 'build') | Out-Null

$modo = if ($Release) { '--export-release' } else { '--export-debug' }
Write-Host "Exportando ($modo)..." -ForegroundColor DarkGray
& $godot --headless --path $proyecto $modo 'Android' $salida
if ($LASTEXITCODE -ne 0) { Write-Error "La exportación falló con código $LASTEXITCODE" }

# Verificar la firma: un APK sin firmar se genera igual y solo falla al
# instalarlo en el teléfono, que es el peor momento para enterarse.
$buildTools = Get-ChildItem "$env:LOCALAPPDATA\Android\Sdk\build-tools" -Directory -ErrorAction SilentlyContinue |
    Sort-Object Name -Descending | Select-Object -First 1
if ($buildTools) {
    $apksigner = Join-Path $buildTools.FullName 'apksigner.bat'
    if (Test-Path $apksigner) {
        Write-Host "Verificando firma..." -ForegroundColor DarkGray
        & $apksigner verify $salida
        if ($LASTEXITCODE -ne 0) { Write-Error "El APK no está bien firmado" }
    }
}

$mb = [math]::Round((Get-Item $salida).Length / 1MB, 1)
Write-Host "`nListo: $salida  ($mb MB)" -ForegroundColor Green
