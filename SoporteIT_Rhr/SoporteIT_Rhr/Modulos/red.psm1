<# 
 Archivo creado por: Rachid Harkaoui Rabhi
 Descripcion: Modulo para diagnostico y reparacion basica de red y conectividad.
#>

function Show-RedMenu {
    Clear-Host
    Write-Host "========== RED Y CONECTIVIDAD =========="
    Write-Host ""
    Write-Host "1) Mostrar informacion de red"
    Write-Host "2) Renovar configuracion IP y DNS"
    Write-Host "3) Restablecer configuracion de red"
    Write-Host "4) Reiniciar adaptadores de red"
    Write-Host "5) Ver conexiones de red activas"
    Write-Host "6) Resumen de red para soporte"
    Write-Host ""
    Write-Host "0) Volver"
    Write-Host ""

    $opcion = Read-Host "Selecciona una opcion"

    switch ($opcion) {
        '1' { Show-RedInfo }
        '2' { Invoke-RenovarIP }
        '3' { Invoke-RestaurarRedProfunda }
        '4' { Invoke-ReiniciarAdaptadores }
        '5' { Show-ConexionesActivas }
        '6' { Show-ResumenRedSoporte }
        default { return }
    }

    Write-Host ""
    Write-Host "Pulsa Enter para volver al menu de Red."
    [void][Console]::ReadLine()
    Show-RedMenu
}

# [REVISADO OK] Test-SoporteITCanWrite se obtiene de base.psm1

function Show-RedInfo {
    Write-SoporteITLog -Mensaje "Consulta de informacion de red completa"
    Write-Host "========== CONFIGURACIÓN IP COMPLETA ==========" -ForegroundColor Cyan
    Get-NetIPConfiguration | Format-List
    Write-Host ""
    Write-Host "Tablas de rutas:"
    Get-NetRoute | Format-Table -AutoSize
}

function Invoke-RenovarIP {
    if (-not (Test-SoporteITCanWrite)) { return }

    Write-SoporteITLog -Mensaje "Renovacion de IP y DNS"

    Write-Host "Reiniciando IP y DNS..."
    try {
        ipconfig /release | Out-Null
        ipconfig /renew | Out-Null
        ipconfig /flushdns | Out-Null
        Write-Host "IP renovada y cache DNS vaciada correctamente."
    }
    catch {
        Write-Host "Error al renovar la IP. Revisa la conexion fisica."
    }
}

function Invoke-RestaurarRedProfunda {
    if (-not (Test-SoporteITCanWrite)) { return }

    Write-SoporteITLog -Mensaje "Restauracion de configuracion de red profunda"

    Write-Host "Se va a restaurar el catalogo de Winsock y el protocolo TCP/IP."
    $confirm = Read-Host "Escribe SI para continuar. El equipo DEBE REINICIARSE despues."

    if ($confirm -ne "SI") {
        Write-Host "Restauracion cancelada."
        return
    }

    try {
        netsh winsock reset | Out-Null
        netsh int ip reset | Out-Null
        Write-Host "Catalogo Winsock y TCP/IP restaurados. Por favor, reinicia el equipo."
    }
    catch {
        Write-Host "Error al restaurar la configuracion de red."
    }
}

function Invoke-ReiniciarAdaptadores {
    if (-not (Test-SoporteITCanWrite)) { return }

    Write-SoporteITLog -Mensaje "Reinicio de adaptadores de red"

    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
    if (-not $adapters) {
        Write-Host "No hay adaptadores activos para reiniciar."
        return
    }

    foreach ($a in $adapters) {
        Write-Host "Reiniciando adaptador $($a.Name)..."
        Disable-NetAdapter -Name $a.Name -Confirm:$false -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        Enable-NetAdapter -Name $a.Name -Confirm:$false -ErrorAction SilentlyContinue
    }

    Write-Host "Adaptadores reiniciados."
}

function Show-ConexionesActivas {
    Write-SoporteITLog -Mensaje "Consulta de conexiones de red activas"

    Write-Host "Conexiones de red mas habituales (TCP):" -ForegroundColor Yellow
    netstat -ano | Select-String "TCP"
}

function Show-ResumenRedSoporte {
    Write-SoporteITLog -Mensaje "Generacion de resumen de red para soporte"

    $adapter = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1
    if (-not $adapter) {
        Write-Host "No hay adaptadores de red activos."
        return
    }

    $ipconfig = Get-NetIPConfiguration -InterfaceIndex $adapter.ifIndex
    $ip = $ipconfig.IPv4Address.IPAddress
    $gw = $ipconfig.IPv4DefaultGateway.NextHop
    $dns = $ipconfig.DnsServer.ServerAddresses -join ", "
    $mac = $adapter.MacAddress

    Write-Host "========== RESUMEN DE RED ==========" -ForegroundColor Cyan
    Write-Host "Adaptador : $($adapter.Name)"
    Write-Host "Estado    : $($adapter.Status)"
    Write-Host "IP Local  : $ip"
    Write-Host "Gateway   : $gw"
    Write-Host "DNS       : $dns"
    Write-Host "MAC       : $mac"
    Write-Host "===================================="
}

# [REVISADO OK] Exportamos la función de menú para que base.psm1 la pueda llamar.
Export-ModuleMember -Function Show-RedMenu