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
    
    Write-Host "========== DATOS GENERALES ==========" -ForegroundColor Cyan
    Write-Host "Equipo: $($env:COMPUTERNAME)"
    Write-Host "Usuario: $($env:USERNAME)"
    Write-Host "SO: $($os.Caption) $($os.OSArchitecture) Version $($os.Version)"
    Write-Host "Fabricante PC: $($cs.Manufacturer)"
    Write-Host "Modelo PC: $($cs.Model)"
    Write-Host "Serial Number: $(Get-CimInstance Win32_Bios).SerialNumber"
    Write-Host "Ultimo arranque: $($os.LastBootUpTime)"
}

function Get-InfoHardware {
    Write-SoporteITLog -Mensaje "Consulta de hardware principal"

    Write-Host "========== HARDWARE ==========" -ForegroundColor Cyan
    Write-Host "Procesador: $(Get-CimInstance Win32_Processor).Name"
    
    $cs = Get-CimInstance Win32_ComputerSystem
    $ramTotalGB = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
    Write-Host "RAM Total: $ramTotalGB GB"

    $video = Get-CimInstance Win32_VideoController
    Write-Host "Tarjeta Grafica: $($video.Caption -join ', ')"
}

function Get-InfoAlmacenamiento {
    Write-SoporteITLog -Mensaje "Consulta de almacenamiento"

    Write-Host "========== ALMACENAMIENTO ==========" -ForegroundColor Cyan
    Write-Host "Unidades de Disco Fisico:"
    Get-CimInstance Win32_DiskDrive | Select-Object Caption, Size, MediaType | Format-List
    
    Write-Host "Particiones logicas (Unidades):"
    Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | Select-Object DeviceID, VolumeName, Size, FreeSpace | Format-Table
}

function Get-InfoRedBasica {
    Write-SoporteITLog -Mensaje "Consulta de red basica"

    Write-Host "========== RED BASICA ==========" -ForegroundColor Cyan
    Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object Name, Status, MacAddress | Format-Table

    Write-Host ""
    Write-Host "Configuracion IP principal:"
    Get-NetIPConfiguration | Select-Object InterfaceDescription, IPv4Address, IPv4DefaultGateway, DnsServer | Format-List
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

    Write-Host "========== RESUMEN PARA TICKET ==========" -ForegroundColor Cyan
    Write-Host "Equipo : $($env:COMPUTERNAME)"
    Write-Host "Usuario: $($env:USERNAME)"
    Write-Host "SO     : $($os.Caption) $($os.OSArchitecture) Version $($os.Version)"
    Write-Host "Modelo : $($cs.Model)"
    Write-Host "IP     : $ip"
    Write-Host "Gateway: $gw"
    Write-Host "Disco C: $freeGB GB libres de $totalGB GB"
    Write-Host "========================================="
}

# [REVISADO OK] Exportamos la función de menú para que base.psm1 la pueda llamar.
Export-ModuleMember -Function Show-InfoMenu