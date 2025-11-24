<# 
 Archivo creado por: Rachid Harkaoui Rabhi
 Descripcion: Modulo para generar un informe completo en HTML del equipo.
#>

function New-SoporteITInforme {
    Write-SoporteITLog -Mensaje "Generacion de informe HTML completa iniciada"

    $equipo = $env:COMPUTERNAME
    $fecha = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    $os = Get-CimInstance Win32_OperatingSystem
    $cs = Get-CimInstance Win32_ComputerSystem
    $discos = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"

    $adapter = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1
    $ip = ""
    $gw = ""
    $dns = ""
    if ($adapter) {
        $ipconfig = Get-NetIPConfiguration -InterfaceIndex $adapter.ifIndex
        if ($ipconfig.IPv4Address) {
            $ip = $ipconfig.IPv4Address.IPAddress
            $gw = $ipconfig.IPv4DefaultGateway.NextHop
            $dns = $ipconfig.DnsServer.ServerAddresses -join ", "
        }
    }

    $erroresSistema = Get-WinEvent -LogName System -ErrorAction SilentlyContinue |
        Where-Object { $_.LevelDisplayName -in @("Error", "Critical") } |
        Select-Object TimeCreated, Id, LevelDisplayName, Message -First 20

    $erroresAplicacion = Get-WinEvent -LogName Application -ErrorAction SilentlyContinue |
        Where-Object { $_.LevelDisplayName -in @("Error", "Critical") } |
        Select-Object TimeCreated, Id, LevelDisplayName, Message -First 20

    $serviciosAnomalos = Get-Service | Where-Object { $_.Status -ne "Running" -and $_.StartType -eq "Automatic" } |
        Select-Object Name, DisplayName, Status, StartType

    $programas = Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" |
        Select-Object DisplayName, DisplayVersion, Publisher, InstallDate |
        Where-Object { $_.DisplayName } |
        Sort-Object DisplayName

    $rutaInforme = Join-Path $Global:SoporteIT_BasePath ("Informe_SoporteIT_{0}_{1}.html" -f $equipo, (Get-Date -Format "yyyyMMdd_HHmmss"))

    $html = @"
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>Informe SoporteIT - $equipo</title>
<style>
body { font-family: Arial, sans-serif; font-size: 14px; background-color: #f4f4f4; margin: 0; padding: 0; }
h1, h2, h3 { color: #333333; }
.container { width: 95%; margin: 10px auto; background-color: #ffffff; padding: 15px; border-radius: 4px; box-shadow: 0 0 5px rgba(0,0,0,0.1); }
table { width: 100%; border-collapse: collapse; margin-bottom: 15px; }
th, td { border: 1px solid #dddddd; padding: 6px; text-align: left; vertical-align: top; }
th { background-color: #f0f0f0; }
.section { margin-bottom: 20px; }
.badge-ok { color: #ffffff; background-color: #2ecc71; padding: 2px 6px; border-radius: 3px; }
.badge-warn { color: #ffffff; background-color: #f1c40f; padding: 2px 6px; border-radius: 3px; }
.badge-error { color: #ffffff; background-color: #e74c3c; padding: 2px 6px; border-radius: 3px; }
</style>
</head>
<body>
<div class="container">
<h1>Informe SoporteIT</h1>
<p><strong>Equipo:</strong> $equipo<br>
<strong>Fecha:</strong> $fecha</p>

<div class="section">
<h2>1. Sistema</h2>
<table>
<tr><th>Campo</th><th>Valor</th></tr>
<tr><td>Sistema operativo</td><td>$($os.Caption) $($os.OSArchitecture)</td></tr>
<tr><td>Version</td><td>$($os.Version)</td></tr>
<tr><td>Fabricante</td><td>$($cs.Manufacturer)</td></tr>
<tr><td>Modelo</td><td>$($cs.Model)</td></tr>
<tr><td>Dominio o grupo trabajo</td><td>$($cs.Domain)</td></tr>
</table>
</div>

<div class="section">
<h2>2. Hardware y almacenamiento</h2>
<table>
<tr><th>Campo</th><th>Valor</th></tr>
<tr><td>RAM total</td><td>$([math]::Round($cs.TotalPhysicalMemory / 1GB, 2)) GB</td></tr>
</table>

<h3>Unidades de disco</h3>
<table>
<tr><th>Unidad</th><th>Total (GB)</th><th>Usado (GB)</th><th>Libre (GB)</th><th>Libre (%)</th></tr>
"@

    foreach ($d in $discos) {
        $totalGB = [math]::Round($d.Size / 1GB, 2)
        $freeGB = [math]::Round($d.FreeSpace / 1GB, 2)
        $usedGB = $totalGB - $freeGB
        $percentFree = [math]::Round(($freeGB / $totalGB) * 100, 2)
        $html += "<tr><td>$($d.DeviceID)</td><td>$totalGB</td><td>$usedGB</td><td>$freeGB</td><td>$percentFree</td></tr>"
    }

    $html += @"
</table>
</div>

<div class="section">
<h2>3. Red</h2>
<table>
<tr><th>Campo</th><th>Valor</th></tr>
<tr><td>Adaptador principal</td><td>$($adapter.Name)</td></tr>
<tr><td>IP</td><td>$ip</td></tr>
<tr><td>Puerta de enlace</td><td>$gw</td></tr>
<tr><td>DNS</td><td>$dns</td></tr>
</table>
</div>

<div class="section">
<h2>4. Eventos criticos recientes</h2>
<h3>Sistema</h3>
<table>
<tr><th>Fecha</th><th>Id</th><th>Nivel</th><th>Mensaje</th></tr>
"@

    foreach ($e in $erroresSistema) {
        $msg = ($e.Message -replace "`r`n", " ")
        if ($msg.Length -gt 200) { $msg = $msg.Substring(0,200) + "..." }
        $html += "<tr><td>$($e.TimeCreated)</td><td>$($e.Id)</td><td>$($e.LevelDisplayName)</td><td>$msg</td></tr>"
    }

    $html += @"
</table>

<h3>Aplicacion</h3>
<table>
<tr><th>Fecha</th><th>Id</th><th>Nivel</th><th>Mensaje</th></tr>
"@

    foreach ($e in $erroresAplicacion) {
        $msg = ($e.Message -replace "`r`n", " ")
        if ($msg.Length -gt 200) { $msg = $msg.Substring(0,200) + "..." }
        $html += "<tr><td>$($e.TimeCreated)</td><td>$($e.Id)</td><td>$($e.LevelDisplayName)</td><td>$msg</td></tr>"
    }

    $html += @"
</table>
</div>

<div class="section">
<h2>5. Servicios automaticos detenidos</h2>
<table>
<tr><th>Nombre</th><th>Descripcion</th><th>Estado</th><th>Tipo inicio</th></tr>
"@

    foreach ($s in $serviciosAnomalos) {
        $html += "<tr><td>$($s.Name)</td><td>$($s.DisplayName)</td><td>$($s.Status)</td><td>$($s.StartType)</td></tr>"
    }

    $html += @"
</table>
</div>

<div class="section">
<h2>6. Programas instalados (resumen)</h2>
<table>
<tr><th>Nombre</th><th>Version</th><th>Fabricante</th><th>Fecha instalacion</th></tr>
"@

    foreach ($p in $programas) {
        $html += "<tr><td>$($p.DisplayName)</td><td>$($p.DisplayVersion)</td><td>$($p.Publisher)</td><td>$($p.InstallDate)</td></tr>"
    }

    $html += @"
</table>
</div>

</div>
</body>
</html>
"@

    $html | Out-File -FilePath $rutaInforme -Encoding UTF8

    Write-Host "Informe generado en:"
    Write-Host $rutaInforme

    Write-SoporteITLog -Mensaje "Informe HTML generado en $rutaInforme"

    try {
        Start-Process $rutaInforme
    }
    catch {
    }
}

Export-ModuleMember -Function New-SoporteITInforme
