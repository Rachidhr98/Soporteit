<# 
 Archivo creado por: Rachid Harkaoui Rabhi
 Descripcion: Modulo para realizar tareas de mantenimiento tipicas en equipos Windows.
#>

function Show-MantenimientoMenu {
    Clear-Host
    Write-Host "========== MANTENIMIENTO =========="
    Write-Host ""
    Write-Host "1) Limpiar temporales del usuario"
    Write-Host "2) Limpiar temporales del sistema"
    Write-Host "3) Limpiar cache de navegadores"
    Write-Host "4) Vaciar Papelera de reciclaje"
    Write-Host "5) Liberacion de espacio rapida"
    Write-Host "6) Optimizar discos"
    Write-Host "7) Buscar actualizaciones de Windows"
    Write-Host "8) Puesta a punto completa"
    Write-Host ""
    Write-Host "0) Volver"
    Write-Host ""

    $opcion = Read-Host "Selecciona una opcion"

    switch ($opcion) {
        '1' { Invoke-LimpiarTemporalesUsuario }
        '2' { Invoke-LimpiarTemporalesSistema }
        '3' { Invoke-LimpiarCacheNavegadores }
        '4' { Invoke-VaciarPapelera }
        '5' { Invoke-LiberacionEspacioRapida }
        '6' { Invoke-OptimizarDiscos }
        '7' { Invoke-BuscarActualizacionesWindows }
        '8' { Invoke-PuestaAPuntoCompleta }
        default { return }
    }

    Write-Host ""
    Write-Host "Pulsa Enter para volver al menu de Mantenimiento."
    [void][Console]::ReadLine()
    Show-MantenimientoMenu
}

function Test-SoporteITCanWrite {
    if ($Global:SoporteIT_ReadOnly) {
        Write-Host "Modo solo lectura. Esta opcion requiere permisos de administrador."
        Write-SoporteITLog -Mensaje "Opcion de escritura bloqueada por modo solo lectura" -Nivel "WARN"
        return $false
    }
    return $true
}

function Invoke-LimpiarTemporalesUsuario {
    if (-not (Test-SoporteITCanWrite)) { return }

    Write-SoporteITLog -Mensaje "Limpieza de temporales de usuario"

    $paths = @(
        $env:TEMP,
        "$env:USERPROFILE\AppData\Local\Temp"
    )

    foreach ($p in $paths) {
        if (Test-Path $p) {
            Write-Host "Limpiando $p"
            Get-ChildItem -Path $p -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
        }
    }

    Write-Host "Limpieza de temporales de usuario finalizada."
}

function Invoke-LimpiarTemporalesSistema {
    if (-not (Test-SoporteITCanWrite)) { return }

    Write-SoporteITLog -Mensaje "Limpieza de temporales de sistema"

    $paths = @(
        "$env:WINDIR\Temp"
    )

    foreach ($p in $paths) {
        if (Test-Path $p) {
            Write-Host "Limpiando $p"
            Get-ChildItem -Path $p -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
        }
    }

    Write-Host "Limpieza de temporales del sistema finalizada."
}

function Invoke-LimpiarCacheNavegadores {
    if (-not (Test-SoporteITCanWrite)) { return }

    Write-SoporteITLog -Mensaje "Limpieza de cache de navegadores"

    $chrome = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache"
    $edge = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache"
    $firefoxBase = "$env:APPDATA\Mozilla\Firefox\Profiles"

    $rutas = @($chrome, $edge)

    foreach ($r in $rutas) {
        if (Test-Path $r) {
            Write-Host "Limpiando cache en $r"
            Get-ChildItem -Path $r -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
        }
    }

    if (Test-Path $firefoxBase) {
        Get-ChildItem $firefoxBase -Directory | ForEach-Object {
            $ffCache = Join-Path $_.FullName "cache2"
            if (Test-Path $ffCache) {
                Write-Host "Limpiando cache de Firefox en $ffCache"
                Get-ChildItem -Path $ffCache -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
            }
        }
    }

    Write-Host "Limpieza de cache de navegadores finalizada."
}

function Invoke-VaciarPapelera {
    if (-not (Test-SoporteITCanWrite)) { return }

    Write-SoporteITLog -Mensaje "Vaciado de Papelera de reciclaje"
    try {
        # Metodo nativo de Windows para vaciar Papelera
        cmd.exe /c "PowerShell -NoProfile -Command `"Clear-RecycleBin -Force -ErrorAction SilentlyContinue`""
        Write-Host "Papelera de reciclaje vaciada."
    }
    catch {
        Write-Host "No se ha podido vaciar la Papelera de reciclaje."
    }
}

function Invoke-LiberacionEspacioRapida {
    if (-not (Test-SoporteITCanWrite)) { return }

    Write-SoporteITLog -Mensaje "Liberacion de espacio rapida iniciada"

    Invoke-LimpiarTemporalesUsuario
    Invoke-LimpiarTemporalesSistema
    Invoke-VaciarPapelera
    Invoke-LimpiarCacheNavegadores

    Write-Host "Liberacion de espacio rapida completada."
}

function Invoke-OptimizarDiscos {
    if (-not (Test-SoporteITCanWrite)) { return }

    Write-SoporteITLog -Mensaje "Optimizacion de discos"

    try {
        Write-Host "Iniciando optimizacion de unidades. Esto puede tardar."
        Optimize-Volume -DriveLetter C -Verbose -ErrorAction SilentlyContinue
        Write-Host "Optimizacion solicitada. Revise el Visor de eventos si es necesario."
    }
    catch {
        Write-Host "No se ha podido optimizar el disco."
    }
}

function Invoke-BuscarActualizacionesWindows {
    if (-not (Test-SoporteITCanWrite)) { return }

    Write-SoporteITLog -Mensaje "Busqueda de actualizaciones de Windows"

    Write-Host "Abriendo configuracion de Windows Update."
    Start-Process "ms-settings:windowsupdate"
}

function Invoke-PuestaAPuntoCompleta {
    if (-not (Test-SoporteITCanWrite)) { return }

    Write-SoporteITLog -Mensaje "Puesta a punto completa iniciada"

    Invoke-LiberacionEspacioRapida
    Invoke-OptimizarDiscos

    Write-Host "Puesta a punto completa realizada."
}

Export-ModuleMember -Function Show-MantenimientoMenu
