<# 
 Archivo creado por: Rachid Harkaoui Rabhi
 Descripcion: Modulo para realizar tareas de mantenimiento tipicas en equipos Windows.
#>

# --- FUNCION AUXILIAR: CALCULO DE PESO EN MB ---
function Get-FolderSize {
    param([string]$Path)
    if (Test-Path $Path) {
        try {
            # Mide el tamaño en MB
            $size = Get-ChildItem $Path -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum
            if ($size.Sum) { return [math]::Round($size.Sum / 1MB, 2) }
        }
        catch { return 0 }
    }
    return 0
}

# --- FUNCION DE RECOLECCION DE PESO PARA INFORME ---
function Get-PesoArchivosAnomalos {
    Write-SoporteITLog -Mensaje "Calculo de peso de archivos anómalos (Temporales/Papelera)"
    
    $tempUserPath = "$env:TEMP\*"
    $tempSystemPath = "$env:WINDIR\Temp\*"
    $winUpdateCachePath = "$env:WINDIR\SoftwareDistribution\Download\*"
    $recyclerPath = "C:\`$Recycle.Bin\*"
    $chromeCachePath = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache\*"
    $edgeCachePath = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache\*"
    
    $peso = New-Object PSObject -Property @{
        Temp_User = Get-FolderSize -Path $tempUserPath
        Temp_System = Get-FolderSize -Path $tempSystemPath
        WinUpdate_Cache = Get-FolderSize -Path $winUpdateCachePath
        Browser_Cache = (Get-FolderSize -Path $chromeCachePath) + (Get-FolderSize -Path $edgeCachePath)
        Recycler_User = Get-FolderSize -Path $recyclerPath 
    }
    
    return $peso
}

# --- FUNCION MOSTRAR RESUMEN (OPCION 1 DEL MENÚ) ---
function Show-ResumenEspacioPerdido {
    Write-SoporteITLog -Mensaje "Consulta de resumen de espacio perdido solicitada"

    $pesos = Get-PesoArchivosAnomalos
    
    Clear-Host
    Write-Host "========== RESUMEN DE ESPACIO PERDIDO ==========" -ForegroundColor Yellow
    Write-Host ""
    
    if (-not $pesos) {
        Write-Host "ERROR: No se pudieron obtener los datos de peso. Asegúrese de tener permisos de administrador." -ForegroundColor Red
        return
    }

    $total = 0
    Write-Host "Detalle del espacio (para decidir si limpiar):"
    Write-Host "----------------------------------------------------------------------"
    
    $datos = @(
        @{ Nombre = "Temporales del Usuario (TEMP)"; Valor = $pesos.Temp_User; Menu = "Opción 2" },
        @{ Nombre = "Temporales del Sistema (%WINDIR%\Temp)"; Valor = $pesos.Temp_System; Menu = "Opción 3" },
        @{ Nombre = "Caché de Navegadores (Chrome/Edge)"; Valor = $pesos.Browser_Cache; Menu = "Opción 4" },
        @{ Nombre = "Papelera de Reciclaje (C:\\\$Recycle.Bin)"; Valor = $pesos.Recycler_User; Menu = "Opción 5" },
        @{ Nombre = "Caché de Windows Update"; Valor = $pesos.WinUpdate_Cache; Menu = "Limpieza Adicional" }
    )
    
    foreach ($item in $datos) {
        $valor = 0
        if ($item.Valor -is [System.Double]) { $valor = $item.Valor }
        
        $total += $valor

        if ($valor -gt 0) {
            Write-Host ("{0,-38} : {1,8:N2} MB  ({2})" -f $item.Nombre, $valor, $item.Menu) -ForegroundColor Green
        } else {
             Write-Host ("{0,-38} : {1,8} MB" -f $item.Nombre, "0.00") -ForegroundColor DarkGray
        }
    }

    Write-Host "----------------------------------------------------------------------"
    Write-Host ("{0,-38} : {1,8:N2} MB" -f "TOTAL DE ESPACIO PERDIDO", $total) -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Recomendación: Si el TOTAL es superior a 1 GB (1024 MB), es bueno limpiar."
}


function Show-MantenimientoMenu {
    Clear-Host
    Write-Host "========== MANTENIMIENTO =========="
    Write-Host ""
    Write-Host "1) MOSTRAR RESUMEN DE ESPACIO PERDIDO (Para valorar limpieza)"
    Write-Host "2) Limpiar temporales del usuario"
    Write-Host "3) Limpiar temporales del sistema"
    Write-Host "4) Limpiar cache de navegadores"
    Write-Host "5) Vaciar Papelera de reciclaje"
    Write-Host "6) Liberacion de espacio rapida (Todas las opciones 2 a 5)"
    Write-Host "7) Optimizar discos"
    Write-Host "8) Buscar actualizaciones de Windows"
    Write-Host "9) Puesta a punto completa"
    Write-Host ""
    Write-Host "0) Volver"
    Write-Host ""

    $opcion = Read-Host "Selecciona una opcion"

    switch ($opcion) {
        '1' { Show-ResumenEspacioPerdido }
        '2' { Invoke-LimpiarTemporalesUsuario }
        '3' { Invoke-LimpiarTemporalesSistema }
        '4' { Invoke-LimpiarCacheNavegadores }
        '5' { Invoke-VaciarPapelera }
        '6' { Invoke-LiberacionEspacioRapida }
        '7' { Invoke-OptimizarDiscos }
        '8' { Invoke-BuscarActualizacionesWindows }
        '9' { Invoke-PuestaAPuntoCompleta }
        default { return }
    }

    Write-Host ""
    Write-Host "Pulsa Enter para volver al menu principal."
    [void][Console]::ReadLine()
    Show-MantenimientoMenu
}

function Invoke-LimpiarTemporalesUsuario {
    if (-not (Test-SoporteITCanWrite)) { return }

    Write-SoporteITLog -Mensaje "Limpieza de temporales del usuario"
    Write-Host "Eliminando archivos temporales de usuario..."

    $tempPath = "$env:TEMP\*"
    try {
        Remove-Item -Path $tempPath -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "Limpieza de temporales de usuario completada."
    }
    catch {
        Write-Host "Error al limpiar temporales de usuario. Algunos archivos estan en uso."
    }
}

function Invoke-LimpiarTemporalesSistema {
    if (-not (Test-SoporteITCanWrite)) { return }

    Write-SoporteITLog -Mensaje "Limpieza de temporales del sistema"
    Write-Host "Eliminando archivos temporales de sistema..."

    $tempPath = "$env:SystemRoot\Temp\*"
    try {
        Remove-Item -Path $tempPath -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "Limpieza de temporales de sistema completada."
    }
    catch {
        Write-Host "Error al limpiar temporales de sistema. Algunos archivos estan en uso."
    }
}

function Invoke-LimpiarCacheNavegadores {
    if (-not (Test-SoporteITCanWrite)) { return }

    Write-SoporteITLog -Mensaje "Limpieza de cache de navegadores"

    Write-Host "Limpiando cache de Edge/Internet Explorer..."
    Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\INetCache\Content.IE5\*" -Recurse -Force -ErrorAction SilentlyContinue
    
    Write-Host "Limpiando cache de Chrome..."
    Remove-Item -Path "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache\*" -Recurse -Force -ErrorAction SilentlyContinue

    Write-Host "Limpiando cache de Firefox..."
    Remove-Item -Path "$env:APPDATA\Mozilla\Firefox\Profiles\*\cache2\entries\*" -Recurse -Force -ErrorAction SilentlyContinue
    
    Write-Host "Limpieza de cache de navegadores completada."
}

function Invoke-VaciarPapelera {
    if (-not (Test-SoporteITCanWrite)) { return }

    Write-SoporteITLog -Mensaje "Vaciado de Papelera de reciclaje"

    Write-Host "Vaciando Papelera de reciclaje..."
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    
    Write-Host "Papelera de reciclaje vaciada."
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

    Write-Host "Se va a ejecutar una puesta a punto completa que incluye:"
    Write-Host "- Limpieza de temporales"
    Write-Host "- Vaciar papelera y cache"
    Write-Host "- Optimizar discos"
    Write-Host ""
    $confirm = Read-Host "Escribe SI para continuar"

    if ($confirm -ne "SI") {
        Write-Host "Puesta a punto completa cancelada."
        Write-SoporteITLog -Mensaje "Puesta a punto completa cancelada" -Nivel "WARN"
        return
    }

    Invoke-LimpiarTemporalesUsuario
    Invoke-LimpiarTemporalesSistema
    Invoke-VaciarPapelera
    Invoke-LimpiarCacheNavegadores
    Invoke-OptimizarDiscos
    
    Write-Host "Puesta a punto completa finalizada."
    Write-SoporteITLog -Mensaje "Puesta a punto completa finalizada"
}

# [SOLUCIÓN AL ERROR] Exportamos la función de cálculo de peso para que informe.psm1 la pueda ver.
Export-ModuleMember -Function Show-MantenimientoMenu, Get-PesoArchivosAnomalos