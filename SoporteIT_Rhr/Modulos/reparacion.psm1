<# 
 Archivo creado por: Rachid Harkaoui Rabhi
 Descripcion: Modulo para ejecutar tareas de reparacion tipicas de Windows.
#>

function Show-ReparacionMenu {
    Clear-Host
    Write-Host "========== REPARACION DE WINDOWS =========="
    Write-Host ""
    Write-Host "1) Comprobar integridad de archivos de sistema"
    Write-Host "2) Reparar imagen de Windows"
    Write-Host "3) Reparar Windows Update"
    Write-Host "4) Restaurar configuraciones recomendadas basicas"
    Write-Host "5) Programar comprobacion de disco al reiniciar"
    Write-Host "6) Reparacion completa (SFC + imagen + Update)"
    Write-Host ""
    Write-Host "0) Volver"
    Write-Host ""

    $opcion = Read-Host "Selecciona una opcion"

    switch ($opcion) {
        '1' { Invoke-ComprobarIntegridadSistema }
        '2' { Invoke-RepararImagenWindows }
        '3' { Invoke-RepararWindowsUpdate }
        '4' { Invoke-RestaurarConfiguracionesRecomendadas }
        '5' { Invoke-ProgramarCHKDSK }
        '6' { Invoke-ReparacionCompleta }
        default { return }
    }

    Write-Host ""
    Write-Host "Pulsa Enter para volver al menu de Reparacion."
    [void][Console]::ReadLine()
    Show-ReparacionMenu
}

function Test-SoporteITCanWrite {
    if ($Global:SoporteIT_ReadOnly) {
        Write-Host "Modo solo lectura. Esta opcion requiere permisos de administrador."
        Write-SoporteITLog -Mensaje "Opcion de escritura bloqueada por modo solo lectura" -Nivel "WARN"
        return $false
    }
    return $true
}

function Invoke-ComprobarIntegridadSistema {
    if (-not (Test-SoporteITCanWrite)) { return }

    Write-SoporteITLog -Mensaje "Comprobacion de integridad de archivos del sistema iniciada"

    Write-Host "Se va a ejecutar una comprobacion de archivos de sistema. Puede tardar varios minutos."
    Write-Host "No cierre la ventana hasta que finalice."
    cmd.exe /c "sfc /scannow"
}

function Invoke-RepararImagenWindows {
    if (-not (Test-SoporteITCanWrite)) { return }

    Write-SoporteITLog -Mensaje "Reparacion de imagen de Windows iniciada"

    Write-Host "Se va a intentar reparar la imagen de Windows. Puede tardar varios minutos."
    cmd.exe /c "DISM /Online /Cleanup-Image /RestoreHealth"
}

function Invoke-RepararWindowsUpdate {
    if (-not (Test-SoporteITCanWrite)) { return }

    Write-SoporteITLog -Mensaje "Reparacion de Windows Update iniciada"

    Write-Host "Reiniciando servicios y limpiando componentes de Windows Update."

    net stop wuauserv
    net stop bits
    net stop cryptsvc

    Remove-Item -Path "$env:WINDIR\SoftwareDistribution\*" -Force -Recurse -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:WINDIR\System32\catroot2\*" -Force -Recurse -ErrorAction SilentlyContinue

    net start cryptsvc
    net start bits
    net start wuauserv

    Write-Host "Proceso basico de reparacion de Windows Update completado."
}

function Invoke-RestaurarConfiguracionesRecomendadas {
    if (-not (Test-SoporteITCanWrite)) { return }

    Write-SoporteITLog -Mensaje "Restauracion de configuraciones basicas recomendadas"

    Write-Host "Restaurando configuraciones basicas de energia y firewall de Windows."

    try {
        powercfg -restoredefaultschemes | Out-Null
    }
    catch {
    }

    try {
        netsh advfirewall reset | Out-Null
    }
    catch {
    }

    Write-Host "Configuraciones basicas restauradas. Revise ajustes especificos de la empresa si aplica."
}

function Invoke-ProgramarCHKDSK {
    if (-not (Test-SoporteITCanWrite)) { return }

    Write-SoporteITLog -Mensaje "Programacion de comprobacion de disco"

    Write-Host "Se va a programar un CHKDSK en la unidad C: en el proximo reinicio."
    Write-Host "Guarda el trabajo antes de reiniciar. Esto puede tardar."

    cmd.exe /c "chkdsk C: /F /R /X"
}

function Invoke-ReparacionCompleta {
    if (-not (Test-SoporteITCanWrite)) { return }

    Write-Host "Se va a ejecutar una reparacion completa que incluye:"
    Write-Host "- Comprobacion de archivos de sistema"
    Write-Host "- Reparacion de imagen de Windows"
    Write-Host "- Reparacion de Windows Update"
    Write-Host ""
    $confirm = Read-Host "Escribe SI para continuar"

    if ($confirm -ne "SI") {
        Write-Host "Reparacion completa cancelada."
        Write-SoporteITLog -Mensaje "Reparacion completa cancelada por el usuario" -Nivel "WARN"
        return
    }

    Write-SoporteITLog -Mensaje "Reparacion completa iniciada"

    Invoke-ComprobarIntegridadSistema
    Invoke-RepararImagenWindows
    Invoke-RepararWindowsUpdate

    Write-Host "Reparacion completa finalizada."
}

Export-ModuleMember -Function Show-ReparacionMenu
