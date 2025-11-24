<# 
 Archivo creado por: Rachid Harkaoui Rabhi
 Descripcion: Herramienta generica para ayudar en el dia a dia del soporte de equipos Windows.
#>

param(
    [switch]$SoloLectura
)

# Comprobar si el proceso actual tiene permisos de administrador
$identidad = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identidad)
$esAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

$Global:SoporteIT_IsAdmin = $esAdmin
$Global:SoporteIT_ReadOnly = $false

if (-not $esAdmin -and -not $SoloLectura) {
    Clear-Host
    Write-Host "SoporteIT se va a ejecutar sin permisos de administrador."
    Write-Host ""
    Write-Host "1) Reintentar ejecutando como administrador"
    Write-Host "2) Continuar en modo solo lectura"
    Write-Host ""
    $opcionPermisos = Read-Host "Selecciona una opcion"

    if ($opcionPermisos -eq '1') {
        Write-Host "Reiniciando SoporteIT con permisos de administrador..."
        $argumentos = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
        Start-Process -FilePath "powershell.exe" -ArgumentList $argumentos -Verb RunAs
        exit
    }
    else {
        Write-Host "Continuando en modo solo lectura."
        $Global:SoporteIT_ReadOnly = $true
    }
}
elseif (-not $esAdmin -and $SoloLectura) {
    $Global:SoporteIT_ReadOnly = $true
}
else {
    $Global:SoporteIT_ReadOnly = $false
}

# Rutas globales
$Global:SoporteIT_BasePath = Split-Path -Parent $PSCommandPath
$Global:SoporteIT_ModulesPath = Join-Path $Global:SoporteIT_BasePath "Modulos"
$Global:SoporteIT_LogPath = Join-Path $Global:SoporteIT_BasePath "soporteit.log"

# Importar modulos
Import-Module (Join-Path $Global:SoporteIT_ModulesPath "base.psm1") -Force
Import-Module (Join-Path $Global:SoporteIT_ModulesPath "info.psm1") -Force
Import-Module (Join-Path $Global:SoporteIT_ModulesPath "mantenimiento.psm1") -Force
Import-Module (Join-Path $Global:SoporteIT_ModulesPath "reparacion.psm1") -Force
Import-Module (Join-Path $Global:SoporteIT_ModulesPath "red.psm1") -Force
Import-Module (Join-Path $Global:SoporteIT_ModulesPath "diagnostico.psm1") -Force
Import-Module (Join-Path $Global:SoporteIT_ModulesPath "informe.psm1") -Force

# Iniciar menu principal
Start-SoporteIT
