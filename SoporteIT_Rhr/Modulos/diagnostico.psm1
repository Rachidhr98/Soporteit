<# 
 Archivo creado por: Rachid Harkaoui Rabhi
 Descripcion: Modulo para diagnostico avanzado del equipo, eventos y servicios.
#>

function Show-DiagnosticoMenu {
    Clear-Host
    Write-Host "========== DIAGNOSTICO AVANZADO =========="
    Write-Host ""
    Write-Host "1) Resumen de programas instalados"
    Write-Host "2) Carga del sistema (CPU, RAM, disco)"
    Write-Host "3) Errores recientes del sistema"
    Write-Host "4) Apagados y reinicios no controlados"
    Write-Host "5) Estado de unidades de disco"
    Write-Host "6) Servicios en estado anomalo"
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
        default { return }
    }

    Write-Host ""
    Write-Host "Pulsa Enter para volver al menu de Diagnostico."
    [void][Console]::ReadLine()
    Show-DiagnosticoMenu
}

function Show-ProgramasInstalados {
    Write-SoporteITLog -Mensaje "Consulta de programas instalados"

    Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" |
        Select-Object DisplayName, DisplayVersion, Publisher, InstallDate |
        Where-Object { $_.DisplayName } |
        Sort-Object DisplayName |
        Format-Table -AutoSize
}

function Show-CargaSistema {
    Write-SoporteITLog -Mensaje "Consulta de carga de sistema"

    Write-Host "Muestra rapida de carga de CPU y memoria:"
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

    Write-Host "Errores recientes en el registro de Sistema:"
    Get-WinEvent -LogName System -ErrorAction SilentlyContinue |
        Where-Object { $_.LevelDisplayName -in @("Error", "Critical") } |
        Select-Object TimeCreated, Id, LevelDisplayName, Message -First 20 |
        Format-Table -AutoSize

    Write-Host ""
    Write-Host "Errores recientes en el registro de Aplicacion:"
    Get-WinEvent -LogName Application -ErrorAction SilentlyContinue |
        Where-Object { $_.LevelDisplayName -in @("Error", "Critical") } |
        Select-Object TimeCreated, Id, LevelDisplayName, Message -First 20 |
        Format-Table -AutoSize
}

function Show-ApagadosNoControlados {
    Write-SoporteITLog -Mensaje "Consulta de apagados y reinicios no controlados"

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
        Write-Host "Unidad $($d.DeviceID)"
        Write-Host "Total : $totalGB GB"
        Write-Host "Usado : $usedGB GB"
        Write-Host "Libre : $freeGB GB ($percentFree`%)"
    }
}

function Show-ServiciosAnomalos {
    Write-SoporteITLog -Mensaje "Consulta de servicios en estado anomalo"

    $servicios = Get-Service | Where-Object { $_.Status -ne "Running" -and $_.StartType -eq "Automatic" }
    if (-not $servicios) {
        Write-Host "No se han encontrado servicios automaticos detenidos."
        return
    }

    $servicios | Select-Object Name, DisplayName, Status, StartType | Format-Table -AutoSize
}

Export-ModuleMember -Function Show-DiagnosticoMenu
