<# 
 Archivo creado por: Rachid Harkaoui Rabhi
 Descripcion: Modulo para diagnostico avanzado del equipo, eventos y servicios.
#>

function Show-DiagnosticoMenu {
    Clear-Host
    Write-Host "========== DIAGNOSTICO AVANZADO ==========" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1) TODOS los programas instalados"
    Write-Host "2) Carga del sistema (CPU, RAM, disco)"
    Write-Host "3) Errores recientes del sistema"
    Write-Host "4) Apagados y reinicios no controlados"
    Write-Host "5) Estado de unidades de disco"
    Write-Host "6) Servicios en estado anomalo"
    Write-Host "7) Aplicaciones que arrancan al iniciar"
    Write-Host ""
    Write-Host "0) Volver"
    Write-Host ""

    $opcion = Read-Host "Selecciona una opcion"

    switch ($opcion) {
        '1' { Show-ProgramasInstalados }
        '2' { Show-CargaSistema }
        '3' { Show-ErroresRecientes }
        '4' { Show-ApagadosNoControlados }
        '5' { Show-EstadoDiscos }
        '6' { Show-ServiciosAnomalos }
        '7' { Show-AplicacionesArranque }
        default { return }
    }

    Write-Host ""
    Write-Host "Pulsa Enter para volver al menu de Diagnostico."
    [void][Console]::ReadLine()
    Show-DiagnosticoMenu
}

# --- FUNCION 1: TODOS LOS PROGRAMAS ---
function Show-ProgramasInstalados {
    Write-SoporteITLog -Mensaje "Consulta de TODOS los programas instalados"

    $programas = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*, HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* -ErrorAction SilentlyContinue | 
        Where-Object { $_.DisplayName -and $_.SystemComponent -ne 1 } | 
        Select-Object DisplayName, DisplayVersion, Publisher, InstallDate |
        Sort-Object DisplayName

    Write-Host "Programas encontrados: $($programas.Count)" -ForegroundColor Cyan
    $programas | Format-Table -AutoSize
}

# --- FUNCION 7: APLICACIONES DE ARRANQUE ---
function Show-AplicacionesArranque {
    Write-SoporteITLog -Mensaje "Consulta de aplicaciones de arranque"

    Write-Host "--- APLICACIONES QUE INICIAN CON WINDOWS ---" -ForegroundColor Cyan
    
    # 1. Registro (HKLM - Para todos los usuarios)
    Write-Host "`n>>> Inicio Automatico (Máquina / HKLM)" -ForegroundColor Yellow
    Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Run -ErrorAction SilentlyContinue |
        Select-Object * -ExcludeProperty PSPath, PSParentPath, PSChildName, PSDrive, PSProvider | Format-List
        
    # 2. Registro (HKCU - Solo el usuario actual)
    Write-Host "`n>>> Inicio Automatico (Usuario Actual / HKCU)" -ForegroundColor Yellow
    Get-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Run -ErrorAction SilentlyContinue |
        Select-Object * -ExcludeProperty PSPath, PSParentPath, PSChildName, PSDrive, PSProvider | Format-List
        
    # 3. Carpetas de Inicio
    Write-Host "`n>>> Carpetas de Inicio (ProgramData - Todos los usuarios)" -ForegroundColor Yellow
    Get-ChildItem "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup" -ErrorAction SilentlyContinue
    
    Write-Host "`n>>> Carpetas de Inicio (APPDATA - Usuario Actual)" -ForegroundColor Yellow
    Get-ChildItem "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup" -ErrorAction SilentlyContinue
}

# --- FUNCIONES ORIGINALES RESTANTES ---

function Show-CargaSistema {
    Write-SoporteITLog -Mensaje "Consulta de carga de sistema"

    Write-Host "Muestra rapida de carga de CPU y memoria:" -ForegroundColor Yellow
    $cpuLoad = Get-Counter "\Processor(_Total)\% Processor Time"
    $cpu = [math]::Round($cpuLoad.CounterSamples[0].CookedValue, 2)

    $cs = Get-CimInstance Win32_ComputerSystem
    $os = Get-CimInstance Win32_OperatingSystem
    $ramTotal = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
    $ramLibre = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
    $ramUsada = [math]::Round($ramTotal - ($ramLibre / 1024), 2)

    Write-Host "CPU usada approx: $cpu`%"
    Write-Host "RAM total       : $ramTotal GB"
    Write-Host "RAM usada       : $ramUsada GB"
}

function Show-ErroresRecientes {
    Write-SoporteITLog -Mensaje "Consulta de errores recientes en el sistema"

    Write-Host "Errores recientes en el registro de Sistema:" -ForegroundColor Yellow
    Get-WinEvent -LogName System -ErrorAction SilentlyContinue |
        Where-Object { $_.LevelDisplayName -in @("Error", "Critical") } |
        Select-Object TimeCreated, Id, LevelDisplayName, Message -First 20 |
        Format-Table -AutoSize

    Write-Host "`nErrores recientes en el registro de Aplicacion:" -ForegroundColor Yellow
    Get-WinEvent -LogName Application -ErrorAction SilentlyContinue |
        Where-Object { $_.LevelDisplayName -in @("Error", "Critical") } |
        Select-Object TimeCreated, Id, LevelDisplayName, Message -First 20 |
        Format-Table -AutoSize
}

function Show-ApagadosNoControlados {
    Write-SoporteITLog -Mensaje "Consulta de apagados y reinicios no controlados"

    Write-Host "Eventos de Apagado Inesperado (ID 41 y 6008):" -ForegroundColor Yellow
    Get-WinEvent -LogName System -ErrorAction SilentlyContinue |
        Where-Object { $_.Id -in 41, 6008 } |
        Select-Object TimeCreated, Id, LevelDisplayName, Message -First 20 |
        Format-Table -AutoSize
}

function Show-EstadoDiscos {
    Write-SoporteITLog -Mensaje "Consulta de estado de discos"

    $discos = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"
    foreach ($d in $discos) {
        $totalGB = [math]::Round($d.Size / 1GB, 2)
        $freeGB = [math]::Round($d.FreeSpace / 1GB, 2)
        $usedGB = $totalGB - $freeGB
        $percentFree = [math]::Round(($freeGB / $totalGB) * 100, 2)

        Write-Host ""
        Write-Host "Unidad $($d.DeviceID)" -ForegroundColor Cyan
        Write-Host "Total : $totalGB GB"
        Write-Host "Usado : $usedGB GB"
        Write-Host "Libre : $freeGB GB ($percentFree`%)"
    }
}

function Show-ServiciosAnomalos {
    Write-SoporteITLog -Mensaje "Consulta de servicios en estado anomalo"

    $servicios = Get-Service | Where-Object { $_.Status -ne "Running" -and $_.StartType -eq "Automatic" }
    if (-not $servicios) {
        Write-Host "No se han encontrado servicios automaticos detenidos." -ForegroundColor Green
        return
    }

    Write-Host "Servicios automaticos detenidos:" -ForegroundColor Red
    $servicios | Select-Object Name, DisplayName, Status, StartType | Format-Table -AutoSize
}

# [REVISADO OK] Exportamos la función de menú para que base.psm1 la pueda llamar.
Export-ModuleMember -Function Show-DiagnosticoMenu