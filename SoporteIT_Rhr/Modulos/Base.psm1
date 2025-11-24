<# 
 Archivo creado por: Rachid Harkaoui Rabhi
 Descripcion: Modulo base de SoporteIT. Controla el menu principal, el log y la navegacion entre modulos.
#>

if (-not $Global:SoporteIT_LogPath) {
    $Global:SoporteIT_LogPath = Join-Path $PSScriptRoot "soporteit.log"
}

function Write-SoporteITLog {
    param(
        [string]$Mensaje,
        [string]$Nivel = "INFO"
    )

    try {
        $fecha = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $equipo = $env:COMPUTERNAME
        $linea = "$fecha [$Nivel] [$equipo] $Mensaje"
        Add-Content -Path $Global:SoporteIT_LogPath -Value $linea
    }
    catch {
        Write-Host "No se ha podido escribir en el log."
    }
}

function Show-SoporteITBanner {
    Clear-Host
    Write-Host "============================================="
    Write-Host "           SoporteIT - Rachid"
    Write-Host "============================================="
    Write-Host ""
    if ($Global:SoporteIT_ReadOnly) {
        Write-Host "Modo actual: SOLO LECTURA"
    }
    else {
        Write-Host "Modo actual: COMPLETO (permiso administrador)"
    }
    Write-Host ""
}

function Show-SoporteITMenu {
    Write-Host "1) Ficha del equipo"
    Write-Host "2) Mantenimiento"
    Write-Host "3) Reparacion de Windows"
    Write-Host "4) Red y conectividad"
    Write-Host "5) Diagnostico avanzado"
    Write-Host "6) Informe completo"
    Write-Host "7) Registro de intervenciones"
    Write-Host ""
    Write-Host "0) Salir"
    Write-Host ""
}

function Show-SoporteITLogView {
    Clear-Host
    Write-Host "========== REGISTRO DE INTERVENCIONES =========="
    Write-Host ""

    if (Test-Path $Global:SoporteIT_LogPath) {
        Get-Content -Path $Global:SoporteIT_LogPath | Select-Object -Last 200
    }
    else {
        Write-Host "Todavia no existe archivo de log."
    }

    Write-Host ""
    Write-Host "Fin del registro."
}

function Start-SoporteIT {

    Write-SoporteITLog -Mensaje "Inicio de SoporteIT"

    do {
        Show-SoporteITBanner
        Show-SoporteITMenu
        $opcion = Read-Host "Selecciona una opcion"

        switch ($opcion) {

            '1' {
                Write-SoporteITLog -Mensaje "Acceso a Ficha del equipo"
                if (Get-Command -Name Show-InfoMenu -ErrorAction SilentlyContinue) {
                    Show-InfoMenu
                }
                else {
                    Write-Host "El modulo info.psm1 no esta disponible."
                    Write-SoporteITLog -Mensaje "Modulo info no disponible" -Nivel "WARN"
                }
            }

            '2' {
                Write-SoporteITLog -Mensaje "Acceso a Mantenimiento"
                if (Get-Command -Name Show-MantenimientoMenu -ErrorAction SilentlyContinue) {
                    Show-MantenimientoMenu
                }
                else {
                    Write-Host "El modulo mantenimiento.psm1 no esta disponible."
                    Write-SoporteITLog -Mensaje "Modulo mantenimiento no disponible" -Nivel "WARN"
                }
            }

            '3' {
                Write-SoporteITLog -Mensaje "Acceso a Reparacion de Windows"
                if (Get-Command -Name Show-ReparacionMenu -ErrorAction SilentlyContinue) {
                    Show-ReparacionMenu
                }
                else {
                    Write-Host "El modulo reparacion.psm1 no esta disponible."
                    Write-SoporteITLog -Mensaje "Modulo reparacion no disponible" -Nivel "WARN"
                }
            }

            '4' {
                Write-SoporteITLog -Mensaje "Acceso a Red y conectividad"
                if (Get-Command -Name Show-RedMenu -ErrorAction SilentlyContinue) {
                    Show-RedMenu
                }
                else {
                    Write-Host "El modulo red.psm1 no esta disponible."
                    Write-SoporteITLog -Mensaje "Modulo red no disponible" -Nivel "WARN"
                }
            }

            '5' {
                Write-SoporteITLog -Mensaje "Acceso a Diagnostico avanzado"
                if (Get-Command -Name Show-DiagnosticoMenu -ErrorAction SilentlyContinue) {
                    Show-DiagnosticoMenu
                }
                else {
                    Write-Host "El modulo diagnostico.psm1 no esta disponible."
                    Write-SoporteITLog -Mensaje "Modulo diagnostico no disponible" -Nivel "WARN"
                }
            }

            '6' {
                Write-SoporteITLog -Mensaje "Generacion de informe completo solicitada"
                if (Get-Command -Name New-SoporteITInforme -ErrorAction SilentlyContinue) {
                    New-SoporteITInforme
                }
                else {
                    Write-Host "El modulo informe.psm1 no esta disponible."
                    Write-SoporteITLog -Mensaje "Modulo informe no disponible" -Nivel "WARN"
                }
            }

            '7' {
                Write-SoporteITLog -Mensaje "Consulta del registro de intervenciones"
                Show-SoporteITLogView
                Write-Host ""
                Write-Host "Pulsa Enter para volver al menu principal."
                [void][Console]::ReadLine()
            }

            '0' {
                Write-SoporteITLog -Mensaje "Salida de SoporteIT"
                Write-Host "Saliendo de SoporteIT..."
            }

            default {
                Write-Host "Opcion no valida. Intentalo de nuevo."
            }
        }

        if ($opcion -notin @('0', '7')) {
            Write-Host ""
            Write-Host "Pulsa Enter para volver al menu principal."
            [void][Console]::ReadLine()
        }

    } while ($opcion -ne '0')
}

Export-ModuleMember -Function Write-SoporteITLog, Start-SoporteIT
