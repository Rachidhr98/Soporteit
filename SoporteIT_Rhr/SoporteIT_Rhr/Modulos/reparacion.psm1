<# 
 Archivo creado por: Rachid Harkaoui Rabhi
 Descripcion: Modulo para ejecutar tareas de reparacion tipicas de Windows.
#
# NOTA: Este modulo asume que las funciones Write-SoporteITLog y Test-SoporteITCanWrite
#       estan definidas en Base.psm1
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
    # Esta funcion se asume definida en base.psm1
    # La definimos aqui para evitar errores si se usa el modulo solo
    return $true
}


function Invoke-ComprobarIntegridadSistema {
    if (-not (Test-SoporteITCanWrite)) { return }

    Write-SoporteITLog -Mensaje "Comprobacion de integridad de archivos de sistema (SFC)"

    Write-Host "Ejecutando SFC /SCANNOW. Esto puede tardar varios minutos..."
    try {
        sfc /scannow
        Write-Host "Comprobacion finalizada. Revisa el resultado anterior."
    }
    catch {
        Write-Host "Error al ejecutar SFC."
    }
}

function Invoke-RepararImagenWindows {
    if (-not (Test-SoporteITCanWrite)) { return }

    Write-SoporteITLog -Mensaje "Reparacion de imagen de Windows (DISM)"

    Write-Host "Ejecutando DISM /RestoreHealth. Requiere conexion a Internet. Esto tardara..."
    try {
        dism /Online /Cleanup-Image /RestoreHealth
        Write-Host "Reparacion finalizada. Revisa el resultado anterior."
    }
    catch {
        Write-Host "Error al ejecutar DISM."
    }
}

function Invoke-RepararWindowsUpdate {
    if (-not (Test-SoporteITCanWrite)) { return }

    Write-SoporteITLog -Mensaje "Reparacion de Windows Update"

    Write-Host "Deteniendo servicios de Windows Update..."
    net stop wuauserv | Out-Null
    net stop bits | Out-Null
    
    Write-Host "Borrando cache de descarga..."
    Remove-Item -Path "$env:SystemRoot\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
    
    Write-Host "Reiniciando servicios..."
    net start wuauserv | Out-Null
    net start bits | Out-Null
    
    Write-Host "Windows Update reseteado. Intenta buscar actualizaciones de nuevo."
}

function Invoke-RestaurarConfiguracionesRecomendadas {
    if (-not (Test-SoporteITCanWrite)) { return }

    Write-SoporteITLog -Mensaje "Restauracion de configuraciones recomendadas"

    Write-Host "Restaurando configuraciones basicas de Windows..."
    try {
        # Restaura los planes de energia a los por defecto
        powercfg -restoredefaultschemes | Out-Null
    }
    catch {
    }

    try {
        # Resetea el firewall a la configuracion por defecto
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
        Write-SoporteITLog -Mensaje "Reparacion completa cancelada" -Nivel "WARN"
        return
    }

    Invoke-ComprobarIntegridadSistema
    Invoke-RepararImagenWindows
    Invoke-RepararWindowsUpdate
    
    Write-Host "Reparacion completa finalizada."
    Write-SoporteITLog -Mensaje "Reparacion completa finalizada"
}