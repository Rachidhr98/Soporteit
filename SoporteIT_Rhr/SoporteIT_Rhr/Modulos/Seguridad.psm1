<# 
 Archivo: seguridad.psm1
 Descripcion: Modulo de Ciberseguridad, Auditoria Forense y Escaneo Inteligente.
 Nota: Esta version contiene la logica generica y multi-subred.
#>

function Show-SeguridadMenu {
    Clear-Host
    Write-Host "========== SUITE DE CIBERSEGURIDAD ==========" -ForegroundColor Cyan
    Write-Host ""
    Write-Host " [AUDITORIA LOCAL]" -ForegroundColor Yellow
    Write-Host "1) Detectar Administradores Ocultos"
    Write-Host "2) Analisis Forense (Inicio, Procesos, HOSTS)"
    Write-Host "3) Historial de USBs"
    Write-Host "4) Estado de proteccion (Antivirus/Bitlocker)"
    Write-Host ""
    Write-Host " [AUDITORIA DE RED AVANZADA]" -ForegroundColor Magenta
    Write-Host "5) ESCANER INTELIGENTE (Detecta Rutas y Subredes vecinas)"
    Write-Host "6) ESCANER MASIVO POR RANGO (Ej: 192.168.0.x a 192.168.50.x)"
    Write-Host "7) Ver conexiones RDP recientes"
    Write-Host ""
    Write-Host "0) Volver"
    Write-Host ""

    $opcion = Read-Host "Selecciona una opcion"

    switch ($opcion) {
        '1' { Show-AdminOcultos }
        '2' { Show-AnalisisForense }
        '3' { Show-USBHistory }
        '4' { Show-EstadoProteccionCompleto }
        '5' { Invoke-EscaneoInteligente }
        '6' { Invoke-EscaneoMasivo }
        '7' { Show-RDPLogs }
        default { return }
    }

    Write-Host "`nPulsa Enter para volver."
    [void][Console]::ReadLine()
    Show-SeguridadMenu
}

# --- FUNCIONES AUXILIARES DE ESCANEO ---
function Test-SMBTarget ($target) {
    if (Test-Connection -ComputerName $target -Count 1 -Quiet -BufferSize 16 -ErrorAction SilentlyContinue) {
        if (Test-NetConnection -ComputerName $target -Port 445 -InformationLevel Quiet -WarningAction SilentlyContinue) {
            Write-Host "`n [!] DETECTADO: $target (SMB Abierto)" -ForegroundColor Green
            try {
                $smbConf = Invoke-Command -ComputerName $target -ErrorAction Stop -ScriptBlock { Get-SmbServerConfiguration }
                if ($smbConf.EnableSMB1Protocol) { Write-Host "     [CRITICO] SMB1 PROTOCOLO ACTIVADO (Vulnerable a WannaCry)" -ForegroundColor Red }
            } catch {}
            try {
                $shares = Get-WmiObject -Class Win32_Share -ComputerName $target -ErrorAction Stop | Where-Object { $_.Type -eq 0 }
                if ($shares) { Write-Host "     -> CARPETAS: $(($shares.Name) -join ", ")" -ForegroundColor Yellow }
            } catch {}
        }
    }
}

function Get-SubredBase ($ip) { return $ip.Substring(0, $ip.LastIndexOf('.')) }

# --- FUNCION 5: ESCANEO INTELIGENTE ---
function Invoke-EscaneoInteligente {
    Write-SoporteITLog -Mensaje "Escaneo de red inteligente iniciado"
    Write-Host "`n--- RECOPILANDO INFORMACION DE RED ---" -ForegroundColor Cyan
    $ListaSubredes = @()

    $miIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -notmatch "Loopback|vEthernet"} | Select-Object -First 1).IPAddress
    if ($miIP) { $base = Get-SubredBase $miIP; $ListaSubredes += $base; Write-Host " [detectado] Tu red local: $base.x" -ForegroundColor Green }

    try {
        $rutas = Get-NetRoute -AddressFamily IPv4 | Where-Object { $_.DestinationPrefix -match "^192\.|^10\.|^172\." -and $_.DestinationPrefix -notmatch "255" }
        foreach ($r in $rutas) {
            $base = Get-SubredBase ($r.DestinationPrefix.Split("/")[0])
            if ($base -notin $ListaSubredes -and $base -ne $null) { $ListaSubredes += $base; Write-Host " [detectado] Ruta conocida: $base.x (via Tabla de Rutas)" -ForegroundColor Yellow }
        }
    } catch {}

    Write-Host "`nSe han encontrado $($ListaSubredes.Count) subredes distintas."
    if ((Read-Host "¿Iniciar escaneo? (S/N)") -eq "S") {
        foreach ($red in $ListaSubredes) {
            Write-Host "`n>>> Analizando Subred: $red.1 - $red.254" -ForegroundColor Magenta
            1..254 | ForEach-Object { Write-Host "." -NoNewline -ForegroundColor DarkGray; Test-SMBTarget "$red.$_" }
        }
    }
}

# --- FUNCION 6: ESCANEO MASIVO ---
function Invoke-EscaneoMasivo {
    Write-SoporteITLog -Mensaje "Escaneo masivo de rangos iniciado"
    $baseIP = Read-Host "Introduce la base de IP (Ej: 192.168)"; if ([string]::IsNullOrWhiteSpace($baseIP)) { $baseIP = "192.168" }
    $inicio = Read-Host "Desde subred (numero) [Defecto: 0]"; if ([string]::IsNullOrWhiteSpace($inicio)) { $inicio = 0 }
    $fin = Read-Host "Hasta subred (numero) [Defecto: 5]"; if ([string]::IsNullOrWhiteSpace($fin)) { $fin = 5 }

    for ($s = [int]$inicio; $s -le [int]$fin; $s++) {
        Write-Host "`n>>> Escaneando Subred: $baseIP.$s.x" -ForegroundColor Magenta
        1..254 | ForEach-Object { Write-Host "." -NoNewline -ForegroundColor DarkGray; Test-SMBTarget "$baseIP.$s.$_" }
    }
}

# --- FUNCION 1: ADMIN OCULTOS ---
function Show-AdminOcultos {
    Write-SoporteITLog -Mensaje "Busqueda de administradores ocultos"
    Write-Host "`n--- ANALISIS DE CUENTAS PRIVILEGIADAS ---" -ForegroundColor Cyan
    try {
        $admins = Get-LocalGroupMember -Group "Administradores" -ErrorAction SilentlyContinue 
        foreach ($user in $admins) {
            Write-Host "Usuario: $($user.Name)" -NoNewline
            if ($user.ObjectClass -eq "User") {
                $detalles = Get-LocalUser -Name ($user.Name -replace ".*\\", "") -ErrorAction SilentlyContinue
                if ($detalles.Enabled) { Write-Host " [ACTIVO]" -ForegroundColor Red } else { Write-Host " [Deshabilitado]" -ForegroundColor Gray }
            } else { Write-Host " (Grupo/Dominio)" -ForegroundColor Gray }
        }
    } catch { Write-Host "Requiere permisos de Administrador." -ForegroundColor Red }
}

# --- FUNCION 2: FORENSE ---
function Show-AnalisisForense {
    Write-SoporteITLog -Mensaje "Analisis forense generico"
    Write-Host "`n[ARCHIVO HOSTS]" -ForegroundColor Yellow
    $hosts = Get-Content "$env:SystemRoot\System32\drivers\etc\hosts" -ErrorAction SilentlyContinue | Where {$_ -notmatch "^#" -and $_ -ne ""}
    if ($hosts) { Write-Host "ALERTA: Modificaciones detectadas:" -ForegroundColor Red; $hosts | ForEach { Write-Host $_ -ForegroundColor Red } } else { Write-Host "Limpio" -ForegroundColor Green }
    
    Write-Host "`n[REGISTRO DE INICIO]" -ForegroundColor Yellow
    Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Run | ForEach-Object {
        $_.PSObject.Properties | Where Name -notin "PSPath","PSParentPath","PSChildName","PSDrive","PSProvider" | ForEach { Write-Host "$($_.Name): $($_.Value)" }
    }
}

# --- FUNCION 3: USB ---
function Show-USBHistory {
    Write-SoporteITLog -Mensaje "Auditoria de historial USB"
    Write-Host "`n--- HISTORIAL DE USB ---" -ForegroundColor Cyan
    Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Enum\USBSTOR\*\*' -ErrorAction SilentlyContinue | Select FriendlyName | Format-Table -AutoSize
}

# --- FUNCION 4: PROTECCION ---
function Show-EstadoProteccionCompleto {
    Write-SoporteITLog -Mensaje "Consulta de estado de proteccion"
    Write-Host "--- ESTADO DE PROTECCION ---" -ForegroundColor Cyan
    Write-Host "`n[Antivirus]" -ForegroundColor Yellow
    try { Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntivirusProduct | Select displayName | Format-Table } catch { Write-Host "No disponible." }
    Write-Host "`n[BitLocker]" -ForegroundColor Yellow
    try { Get-BitLockerVolume -MountPoint "C:" | Select MountPoint, ProtectionStatus | Format-Table } catch { Write-Host "No disponible." }
}

# --- FUNCION 7: RDP LOGS ---
function Show-RDPLogs {
    Write-SoporteITLog -Mensaje "Consulta de Logs RDP"
    Write-Host "`n--- CONEXIONES REMOTAS RECIENTES (RDP) ---" -ForegroundColor Cyan
    Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4624} -MaxEvents 10 -ErrorAction SilentlyContinue | Where {$_.Properties[8].Value -eq 10} | Select TimeCreated, @{N='User';E={$_.Properties[5].Value}}, @{N='IP';E={$_.Properties[18].Value}} | Format-Table
}

# [REVISADO OK] Exportamos la función para que el módulo base.psm1 la pueda ver
Export-ModuleMember -Function Show-SeguridadMenu, Show-AdminOcultos, Invoke-EscaneoInteligente, Show-AnalisisForense