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

function Test-SoporteITCanWrite {
    if ($Global:SoporteIT_ReadOnly) {
        Write-Host "Modo solo lectura. Esta opcion requiere permisos de administrador."
        Write-SoporteITLog -Mensaje "Opcion de escritura bloqueada por modo solo lectura" -Nivel "WARN"
        return $false
    }
    return $true
}

function Show-RedInfo {
    Write-SoporteITLog -Mensaje "Consulta de informacion de red"

    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }

    if (-not $adapters) {
        Write-Host "No hay adaptadores de red activos."
        return
    }

    foreach ($a in $adapters) {
        Write-Host ""
        Write-Host "Nombre       : $($a.Name)"
        Write-Host "Descripcion  : $($a.InterfaceDescription)"
        Write-Host "Estado       : $($a.Status)"
        Write-Host "Velocidad    : $($a.LinkSpeed)"

        $ipconfig = Get-NetIPConfiguration -InterfaceIndex $a.ifIndex
        if ($ipconfig.IPv4Address) {
            $ip = $ipconfig.IPv4Address.IPAddress
            $gw = $ipconfig.IPv4DefaultGateway.NextHop
            $dns = $ipconfig.DnsServer.ServerAddresses -join ", "
            Write-Host "IP           : $ip"
            Write-Host "Puerta enlace: $gw"
            Write-Host "DNS          : $dns"
        }
        else {
            Write-Host "Sin direccion IPv4 configurada."
        }
    }

    Write-Host ""
    Write-Host "Probando conectividad basica..."

    try {
        $gateway = (Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway } | Select-Object -First 1).IPv4DefaultGateway.NextHop
        if ($gateway) {
            $pingGw = Test-Connection -ComputerName $gateway -Count 1 -Quiet -ErrorAction SilentlyContinue
            Write-Host "Ping a puerta de enlace ($gateway): " -NoNewline
            if ($pingGw) { Write-Host "OK" } else { Write-Host "FALLO" }
        }
    }
    catch {
    }

    try {
        $pingInternet = Test-Connection -ComputerName "8.8.8.8" -Count 1 -Quiet -ErrorAction SilentlyContinue
        Write-Host "Ping a internet (8.8.8.8): " -NoNewline
        if ($pingInternet) { Write-Host "OK" } else { Write-Host "FALLO" }
    }
    catch {
        Write-Host "No se ha podido realizar la prueba de internet."
    }
}

function Invoke-RenovarIP {
    if (-not (Test-SoporteITCanWrite)) { return }

    Write-SoporteITLog -Mensaje "Renovacion de configuracion IP y DNS"

    Write-Host "Liberando y renovando configuracion IP y limpiando cache DNS."
    cmd.exe /c "ipconfig /release"
    cmd.exe /c "ipconfig /renew"
    cmd.exe /c "ipconfig /flushdns"

    Write-Host "Renovacion de IP y limpieza de DNS completadas."
}

function Invoke-RestaurarRedProfunda {
    if (-not (Test-SoporteITCanWrite)) { return }

    Write-SoporteITLog -Mensaje "Restablecimiento profundo de red"

    Write-Host "Se va a restablecer la configuracion de red. Puede requerir reinicio del equipo."
    $confirm = Read-Host "Escribe SI para continuar"

    if ($confirm -ne "SI") {
        Write-Host "Operacion cancelada."
        Write-SoporteITLog -Mensaje "Restablecimiento de red cancelado por el usuario" -Nivel "WARN"
        return
    }

    cmd.exe /c "netsh int ip reset"
    cmd.exe /c "netsh winsock reset"

    Write-Host "Restablecimiento basico de red completado. Reinicia el equipo para aplicar todos los cambios."
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

    Write-Host "Conexiones de red mas habituales (TCP):"
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

    Write-Host "========== RESUMEN DE RED =========="
    Write-Host "Equipo    : $($env:COMPUTERNAME)"
    Write-Host "Adaptador : $($adapter.Name)"
    Write-Host "IP        : $ip"
    Write-Host "Gateway   : $gw"
    Write-Host "DNS       : $dns"
}

Export-ModuleMember -Function Show-RedMenu
