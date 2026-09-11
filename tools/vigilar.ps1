<#
.SYNOPSIS
    Deja el juego corriendo y lo relanza solo cada vez que cambia un archivo.

.DESCRIPTION
    Sirve para tener una terminal desplegada al lado mientras se edita: aqui se
    ve QUE archivo cambio y, acto seguido, el juego arrancado de nuevo con ese
    cambio dentro. Los print() y los errores de Godot salen en esta misma
    terminal porque se usa la build _console y se lanza sin ventana propia.

    Por que relanzar en vez de recargar en caliente: el hot reload de GDScript
    solo funciona cuando el juego lo lanza el EDITOR de Godot. Desde una
    terminal no hay editor que avise, asi que la unica forma fiable de ver un
    cambio es volver a arrancar. Este proyecto arranca en ~1 s, y ademas se
    reinicia siempre desde el nivel 1, que es justo lo que se quiere al
    comparar dos versiones de un ajuste.

    Si el juego se cierra por su cuenta -crash o cerrar la ventana- NO se
    relanza: el vigilante se queda esperando el siguiente cambio para que el
    mensaje de error siga a la vista y se pueda leer.

    Ctrl+C corta el vigilante y se lleva el juego por delante.

.EXAMPLE
    .\tools\vigilar.ps1                        # vigila y relanza el juego
    .\tools\vigilar.ps1 -Nivel 12              # cada reinicio cae en el nivel 12
    .\tools\vigilar.ps1 -SinFin -SinMorir      # sin fin, sin que te maten
    .\tools\vigilar.ps1 -Pantalla derrota      # deja esa pantalla a la vista
    .\tools\vigilar.ps1 -Retardo 800           # espera mas antes de relanzar
#>
param(
    # Donde cae el juego al arrancar, para no repetir los clics del menu en cada
    # reinicio. Ver _arranque_directo() en scripts/main.gd.
    [int]$Nivel = 0,
    [switch]$SinFin,
    [ValidateSet('menu', 'seleccion', 'listo', 'jugando', 'derrota', 'victoria',
                 'final', 'pausa', 'log', 'briefing')]
    [string]$Pantalla,
    # Para mirar una pantalla con calma sin que la partida te mate debajo.
    [switch]$SinMorir,
    # Margen tras el ultimo cambio antes de relanzar. Guardar varios archivos
    # seguidos -lo normal cuando un ajuste toca main.gd y niveles.gd- debe
    # contar como UN reinicio, no como tres.
    [int]$Retardo = 400
)

$ErrorActionPreference = 'Stop'
$raiz = Split-Path -Parent $PSScriptRoot
$godot = & "$PSScriptRoot\buscar-godot.ps1"

# Los argumentos del juego van detras de un "--" suelto: hasta ahi son de Godot,
# a partir de ahi los recoge OS.get_cmdline_user_args().
$destino = @()
if ($Nivel -gt 0) { $destino += "--nivel=$Nivel" }
if ($SinFin)      { $destino += '--sinfin' }
if ($Pantalla)    { $destino += "--pantalla=$Pantalla" }
if ($SinMorir)    { $destino += '--sin-morir' }

$argumentos = @('--path', $raiz)
# Dos lineas y no `+= '--' + $destino`: sumar una cadena y un array los pega en
# UN solo argumento -"----nivel=12 --sin-morir"- que Godot ignora sin quejarse,
# y el juego arranca en el menu como si no hubieras pedido nada.
if ($destino) {
    $argumentos += '--'
    $argumentos += $destino
}

Write-Host "godot: $godot" -ForegroundColor DarkGray
Write-Host "vigilando: $raiz  (Ctrl+C para salir)" -ForegroundColor DarkGray
if ($destino) {
    Write-Host "arranque: $($destino -join ' ')" -ForegroundColor DarkGray
}

# Lo que se vigila. project.godot entra porque tocar la resolucion o el
# renderizador tambien exige reiniciar. .godot/ y build/ quedan fuera: son
# cache y salida, cambian solos y provocarian un bucle de reinicios.
$extensiones = @('*.gd', '*.tscn', '*.tres', '*.godot', '*.png', '*.svg', '*.ogg', '*.wav')
$excluidos = @(".godot", ".git", "build", "arte_exportado", "entregas")

function Get-Estado {
    $mapa = @{}
    Get-ChildItem -Path $raiz -Recurse -File -Include $extensiones -ErrorAction SilentlyContinue |
        Where-Object { $excluidos -notcontains $_.FullName.Substring($raiz.Length + 1).Split([char]92)[0] } |
        ForEach-Object { $mapa[$_.FullName] = "$($_.LastWriteTimeUtc.Ticks):$($_.Length)" }
    $mapa
}

function Get-Cambios($antes, $ahora) {
    $lista = @()
    foreach ($ruta in $ahora.Keys) {
        if (-not $antes.ContainsKey($ruta)) { $lista += "+ $ruta" }
        elseif ($antes[$ruta] -ne $ahora[$ruta]) { $lista += "~ $ruta" }
    }
    foreach ($ruta in $antes.Keys) {
        if (-not $ahora.ContainsKey($ruta)) { $lista += "- $ruta" }
    }
    $lista | ForEach-Object { $_ -replace [regex]::Escape("$raiz\"), '' }
}

$proc = $null

function Detener-Juego {
    if (-not $proc -or $proc.HasExited) { return }
    # taskkill /T y no Stop-Process: la build _console de Godot es un ENVOLTORIO
    # que arranca el ejecutable real como proceso hijo. Stop-Process mata solo
    # el envoltorio y deja viva la ventana del juego, asi que tras unos cuantos
    # cambios la pantalla acaba llena de copias del mismo juego, y la que se ve
    # encima no es la ultima. /T se lleva el arbol entero.
    & taskkill.exe /PID $proc.Id /T /F 2>$null | Out-Null
    $proc.WaitForExit(3000) | Out-Null
}

function Lanzar-Juego {
    Detener-Juego
    Write-Host ""
    Write-Host "==> $(Get-Date -Format 'HH:mm:ss')  lanzando" -ForegroundColor Cyan
    # -NoNewWindow es lo que hace que la salida de Godot caiga en ESTA terminal
    # en vez de en una ventana aparte que nadie mira.
    $script:proc = Start-Process -FilePath $godot -ArgumentList $argumentos -NoNewWindow -PassThru
}

try {
    $estado = Get-Estado
    Lanzar-Juego

    while ($true) {
        Start-Sleep -Milliseconds 250
        $nuevo = Get-Estado
        $cambios = Get-Cambios $estado $nuevo
        if (-not $cambios) { continue }

        # Se espera a que la rafaga de guardados amaine: mientras siga habiendo
        # cambios nuevos, no se reinicia. Asi un editor que reescribe un archivo
        # en dos pasadas no cuenta como dos ediciones.
        do {
            Start-Sleep -Milliseconds $Retardo
            $ultimo = $nuevo
            $nuevo = Get-Estado
            $extra = Get-Cambios $ultimo $nuevo
            $cambios += $extra
        } while ($extra)

        Write-Host ""
        foreach ($c in ($cambios | Sort-Object -Unique)) {
            Write-Host "    $c" -ForegroundColor Yellow
        }
        $estado = $nuevo
        Lanzar-Juego
    }
}
finally {
    Detener-Juego
}
