<# 
 Archivo creado por: Rachid Harkaoui Rabhi
 Descripcion: Modulo base de SoporteIT. Controla el menu principal, el log y la navegacion entre modulos.
#>

if (-not $Global:SoporteIT_LogPath) {
    $Global:SoporteIT_LogPath = Join-Path $PSScriptRoot "soporteit.log"
}

function Write-SoporteITLog {
    param(
        [string]$Mensaje, # Mensaje a escribir en el log
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

function Test-SoporteITCanWrite {
    if ($Global:SoporteIT_ReadOnly) {
        Write-Host "Esta operacion requiere permisos de administrador." -ForegroundColor Red
        Write-SoporteITLog -Mensaje "Operacion de escritura bloqueada por modo solo lectura" -Nivel "WARN"
        return $false
    }
    return $true
}

function Show-SoporteITMenu {
    do {
        Show-SoporteITBanner
        Write-Host "1) Ficha del equipo (Hardware/Software)"
        Write-Host "2) Mantenimiento (Limpieza/Optimizacion)"
        Write-Host "3) Reparacion de Windows (SFC/Update/Imagen)"
        Write-Host "4) Red y conectividad"
        Write-Host "5) Diagnostico avanzado"
        Write-Host "6) Generar informe HTML"
        Write-Host "7) Ver registro de intervenciones"
        
        # [REVISADO OK] Opción de Seguridad
        Write-Host "8) SUITE DE CIBERSEGURIDAD Y FORENSE" -ForegroundColor Cyan

        Write-Host ""
        Write-Host "0) Salir"
        Write-Host ""

        $opcion = Read-Host "Selecciona una opcion"

        switch ($opcion) {
            '1' { Show-InfoMenu }
            '2' { Show-MantenimientoMenu }
            '3' { Show-ReparacionMenu }
            '4' { Show-RedMenu }
            '5' { Show-DiagnosticoMenu }
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
                if (Test-Path $Global:SoporteIT_LogPath) {
                    Get-Content $Global:SoporteIT_LogPath -Tail 20
                } else {
                    Write-Host "El registro esta vacio."
                }
                [void][Console]::ReadLine()
            }
            
            '8' { Show-SeguridadMenu } # [REVISADO OK] Llama a la función correcta
            
            '0' {
                Write-SoporteITLog -Mensaje "Salida de SoporteIT"
                Write-Host "Saliendo de SoporteIT..."
                exit
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

# [REVISADO OK] Exportamos la función de log por si es necesaria fuera.
Export-ModuleMember -Function Write-SoporteITLog, Show-SoporteITMenu, Test-SoporteITCanWrite