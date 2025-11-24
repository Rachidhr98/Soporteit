<# 
 Archivo creado por: Rachid Harkaoui Rabhi
 Descripcion: Modulo para mostrar informacion general del equipo y del sistema operativo.
#>

function Show-InfoMenu {
    Clear-Host
    Write-Host "========== FICHA DEL EQUIPO =========="
    Write-Host ""
    Write-Host "1) Datos generales del sistema"
    Write-Host "2) Hardware principal"
    Write-Host "3) Almacenamiento"
    Write-Host "4) Informacion de red basica"
    Write-Host "5) Resumen para ticket"
    Write-Host ""
    Write-Host "0) Volver"
    Write-Host ""

    $opcion = Read-Host "Selecciona una opcion"

    switch ($opcion) {
        '1' { Get-InfoDatosGenerales }
        '2' { Get-InfoHardware }
        '3' { Get-InfoAlmacenamiento }
        '4' { Get-InfoRedBasica }
        '5' { Get-InfoResumenTicket }
        default { return }
    }

    Write-Host ""
    Write-Host "Pulsa Enter para volver al menu de Ficha del equipo."
    [void][Console]::ReadLine()
    Show-InfoMenu
}

function Get-InfoDatosGenerales {
    Write-SoporteITLog -Mensaje "Consulta de datos generales del sistema"

    $os = Get-CimInstance Win32_OperatingSystem
    $cs = Get-CimInstance Win32_ComputerSystem
    $uptime = (Get-Date) - $os.LastBootUpTime

    Write-Host "Equipo          : $($env:COMPUTERNAME)"
    Write-Host "Usuario         : $($env:USERNAME)"
    Write-Host "Sistema         : $($os.Caption) $($os.OSArchitecture)"
    Write-Host "Version         : $($os.Version)"
    Write-Host "Fabricante      : $($cs.Manufacturer)"
    Write-Host "Modelo          : $($cs.Model)"
    Write-Host "Dominio/Grupo   : $($cs.Domain)"
    Write-Host "Tiempo encendido: {0:dd} dias {0:hh} horas {0:mm} minutos" -f $uptime
}

function Get-InfoHardware {
    Write-SoporteITLog -Mensaje "Consulta de hardware principal"

    $cs = Get-CimInstance Win32_ComputerSystem
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    $ramGB = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)

    Write-Host "CPU   : $($cpu.Name)"
    Write-Host "Nucleos logicos: $($cpu.NumberOfLogicalProcessors)"
    Write-Host "RAM   : $ramGB GB"

    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
    if ($disk) {
        $totalGB = [math]::Round($disk.Size / 1GB, 2)
        $freeGB = [math]::Round($disk.FreeSpace / 1GB, 2)
        $usedGB = $totalGB - $freeGB
        $percentFree = [math]::Round(($freeGB / $totalGB) * 100, 2)

        Write-Host ""
        Write-Host "Disco del sistema (C:)"
        Write-Host "Total : $totalGB GB"
        Write-Host "Usado : $usedGB GB"
        Write-Host "Libre : $freeGB GB ($percentFree`%)"
    }
}

function Get-InfoAlmacenamiento {
    Write-SoporteITLog -Mensaje "Consulta de almacenamiento"

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

function Get-InfoRedBasica {
    Write-SoporteITLog -Mensaje "Consulta de informacion de red basica"

    $adapters = Get-NetAdapter -Physical | Where-Object { $_.Status -eq "Up" }

    if (-not $adapters) {
        Write-Host "No hay adaptadores de red activos."
        return
    }

    foreach ($a in $adapters) {
        Write-Host ""
        Write-Host "Adaptador : $($a.Name) [$($a.InterfaceDescription)]"
        Write-Host "Tipo      : $($a.NdisPhysicalMedium)"
        $ipconfig = Get-NetIPConfiguration -InterfaceIndex $a.ifIndex
        if ($ipconfig.IPv4Address) {
            $ip = $ipconfig.IPv4Address.IPAddress
            $gw = $ipconfig.IPv4DefaultGateway.NextHop
            $dns = $ipconfig.DnsServer.ServerAddresses -join ", "
            Write-Host "IP        : $ip"
            Write-Host "Puerta enlace: $gw"
            Write-Host "DNS       : $dns"
        }
        else {
            Write-Host "Sin direccion IPv4 configurada."
        }
    }

    Write-Host ""
    Write-Host "Probando conectividad basica..."
    try {
        $ping = Test-Connection -ComputerName "8.8.8.8" -Count 1 -Quiet -ErrorAction SilentlyContinue
        if ($ping) {
            Write-Host "Conectividad a internet: OK"
        }
        else {
            Write-Host "Conectividad a internet: FALLO"
        }
    }
    catch {
        Write-Host "No se ha podido realizar la prueba de conectividad."
    }
}

function Get-InfoResumenTicket {
    Write-SoporteITLog -Mensaje "Generacion de resumen para ficha de ticket"

    $os = Get-CimInstance Win32_OperatingSystem
    $cs = Get-CimInstance Win32_ComputerSystem
    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
    $adapter = Get-NetAdapter -Physical | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1
    $ip = ""
    $gw = ""
    if ($adapter) {
        $ipconfig = Get-NetIPConfiguration -InterfaceIndex $adapter.ifIndex
        if ($ipconfig.IPv4Address) {
            $ip = $ipconfig.IPv4Address.IPAddress
            $gw = $ipconfig.IPv4DefaultGateway.NextHop
        }
    }

    $totalGB = ""
    $freeGB = ""
    if ($disk) {
        $totalGB = [math]::Round($disk.Size / 1GB, 2)
        $freeGB = [math]::Round($disk.FreeSpace / 1GB, 2)
    }

    Write-Host "========== RESUMEN PARA TICKET =========="
    Write-Host "Equipo : $($env:COMPUTERNAME)"
    Write-Host "Usuario: $($env:USERNAME)"
    Write-Host "SO     : $($os.Caption) $($os.OSArchitecture) Version $($os.Version)"
    Write-Host "Fabricante y modelo: $($cs.Manufacturer) $($cs.Model)"
    Write-Host "Dominio o grupo trabajo: $($cs.Domain)"
    Write-Host "Disco C: Total $totalGB GB Libre $freeGB GB"
    Write-Host "Red    : $($adapter.Name) IP $ip Gateway $gw"
}

Export-ModuleMember -Function Show-InfoMenu
