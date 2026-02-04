<# 
 Archivo modificado: informe.psm1
 Descripcion: Genera informe HTML completo, recopilando datos de todos los modulos.
 Nota: Output 100% en Español.
#>

function New-SoporteITInforme {
    Write-SoporteITLog -Mensaje "Generando informe HTML completo con Estilos"

    $computer = $env:COMPUTERNAME
    $date = Get-Date -Format "dd/MM/yyyy HH:mm"
    $reportPath = "$([Environment]::GetFolderPath('Desktop'))\Informe_$computer.html"

    # 1. --- RECOPILACION DE TODOS LOS DATOS ---
    $os = Get-CimInstance Win32_OperatingSystem
    $disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"
    $cs = Get-CimInstance Win32_ComputerSystem 

    # Datos de Peso (Llamamos a la función de mantenimiento)
    $weights = $null
    # [REVISADO OK] Esta comprobación ahora pasará gracias a la exportación en mantenimiento.psm1
    if (Get-Command -Name Get-PesoArchivosAnomalos -ErrorAction SilentlyContinue) {
        $weights = Get-PesoArchivosAnomalos
    }
    
    # Datos de Arranque
    $startupPrograms = @()
    try {
        $regRun = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Run, HKCU:\Software\Microsoft\Windows\CurrentVersion\Run -ErrorAction Stop
        $regRun | ForEach-Object {
            $_.PSObject.Properties | Where-Object { $_.Name -notin "PSPath","PSParentPath","PSChildName","PSDrive","PSProvider" } | ForEach-Object { 
                $origin = if ($_.PSPath -match "HKCU") { "Usuario" } else { "Sistema" }
                $startupPrograms += [PSCustomObject]@{Origin=$origin; Name=$_.Name; Path=$_.Value }
            }
        }
    } catch {}

    # Datos de Red
    $ip = ""; $gw = ""; $dns = ""
    $adapter = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1
    if ($adapter) {
        $ipconfig = Get-NetIPConfiguration -InterfaceIndex $adapter.ifIndex
        if ($ipconfig.IPv4Address) { $ip = $ipconfig.IPv4Address.IPAddress; $gw = $ipconfig.IPv4DefaultGateway.NextHop; $dns = $ipconfig.DnsServer.ServerAddresses -join ", " }
    }
    
    # Errores (Críticos y Errores de Sistema - Optimizados)
    $systemErrors = Get-WinEvent -FilterHashtable @{LogName='System'; Level=1,2} -ErrorAction SilentlyContinue | 
        Select-Object TimeCreated, Id, LevelDisplayName, Message -First 10

    # Servicios y Programas (TODOS)
    $anomalousServices = Get-Service | Where-Object { ($_.Status -eq "Stopped") -and ($_.StartType -eq "Automatic") } | Select-Object Name, DisplayName, Status, StartType
    $installedPrograms = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*, HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* -ErrorAction SilentlyContinue | 
        Where-Object { $_.DisplayName -and $_.SystemComponent -ne 1 } | 
        Select-Object DisplayName, DisplayVersion, Publisher
    
    # 2. Definir CSS (Estilos Profesionales)
    $css = @"
<style>
    body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f0f2f5; color: #333; margin: 0; padding: 20px; }
    .container { max-width: 900px; margin: 0 auto; background: white; padding: 40px; border-radius: 8px; box-shadow: 0 4px 15px rgba(0,0,0,0.1); }
    h1 { color: #0056b3; border-bottom: 3px solid #0056b3; padding-bottom: 10px; text-transform: uppercase; letter-spacing: 1px; }
    h2 { color: #444; margin-top: 30px; background-color: #e9ecef; padding: 10px; border-left: 5px solid #0056b3; border-radius: 4px; }
    table { width: 100%; border-collapse: collapse; margin-top: 15px; font-size: 0.9em; }
    th { background-color: #0056b3; color: white; padding: 12px; text-align: left; }
    td { padding: 12px; border-bottom: 1px solid #ddd; }
    tr:nth-child(even) { background-color: #f8f9fa; }
    tr:hover { background-color: #e2e6ea; }
    .status-ok { color: #28a745; font-weight: bold; background-color: #d4edda; padding: 4px 8px; border-radius: 4px; }
    .status-warning { color: #856404; font-weight: bold; background-color: #fff3cd; padding: 4px 8px; border-radius: 4px; }
    .status-danger { color: #721c24; font-weight: bold; background-color: #f8d7da; padding: 4px 8px; border-radius: 4px; }
    .footer { margin-top: 50px; font-size: 0.8em; text-align: center; color: #6c757d; border-top: 1px solid #ddd; padding-top: 20px; }
</style>
"@

    # 3. CONSTRUCCION DEL HTML
    $html = @"
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Informe Tecnico - $computer</title>
    $css
</head>
<body>
    <div class="container">
        <h1>INFORME TECNICO DEL SISTEMA</h1>
        <p><strong>Equipo:</strong> $computer | <strong>Fecha:</strong> $date | <strong>T&eacute;cnico:</strong> $($env:USERNAME)</p>

        <h2>1. Resumen del Sistema</h2>
        <table>
            <tr><th>Par&aacute;metro</th><th>Valor</th></tr>
            <tr><td>Sistema Operativo</td><td>$($os.Caption)</td></tr>
            <tr><td>Modelo PC</td><td>$($cs.Model)</td></tr>
            <tr><td>Usuario Logueado</td><td>$($cs.UserName)</td></tr>
            <tr><td>Memoria RAM Total</td><td>$([math]::Round($os.TotalVisibleMemorySize / 1MB, 2)) GB</td></tr>
        </table>

        <h2>2. Estado de Discos</h2>
        <table>
            <tr><th>Unidad</th><th>Capacidad Total</th><th>Espacio Libre</th><th>% Libre</th><th>Estado</th></tr>
"@

    foreach ($d in $disks) {
        $total = [math]::Round($d.Size / 1GB, 2)
        $free = [math]::Round($d.FreeSpace / 1GB, 2)
        $percentage = 0
        if ($total -gt 0) { $percentage = [math]::Round(($free / $total) * 100, 2) }
        
        $status = "<span class='status-ok'>Saludable</span>"
        if ($percentage -lt 10) { $status = "<span class='status-danger'>Cr&iacute;tico (<10%)</span>" }
        elseif ($percentage -lt 20) { $status = "<span class='status-warning'>Espacio Bajo</span>" }

        $html += "<tr><td>$($d.DeviceID)</td><td>$total GB</td><td>$free GB</td><td>$percentage %</td><td>$status</td></tr>"
    }

    $html += "</table>"
    
    # --- SECCION 3: RED ---
    $html += "<h2>3. Informaci&oacute;n de Red y Conexiones</h2><table>"
    $html += "<tr><th>Par&aacute;metro</th><th>Valor</th></tr>"
    $html += "<tr><td>IP Local</td><td>$ip</td></tr>"
    $html += "<tr><td>Puerta de Enlace</td><td>$gw</td></tr>"
    $html += "<tr><td>Servidores DNS</td><td>$dns</td></tr>"
    $html += "<tr><td>Adaptador Activo</td><td>$($adapter.Name)</td></tr>"
    $html += "</table>"
    
    # --- SECCION 4: ERRORES ---
    $html += "<h2>4. Errores Cr&iacute;ticos del Sistema (Ultimos 10)</h2><table>"
    $html += "<tr><th>Fecha</th><th>ID</th><th>Nivel</th><th>Mensaje</th></tr>"
    if ($systemErrors.Count -gt 0) {
        foreach ($e in $systemErrors) {
            $msg = ($e.Message -replace "`r`n", " ")
            if ($msg.Length -gt 150) { $msg = $msg.Substring(0,150) + "..." }
            $html += "<tr><td>$($e.TimeCreated)</td><td>$($e.Id)</td><td>$($e.LevelDisplayName)</td><td>$msg</td></tr>"
        }
    } else {
        $html += "<tr><td colspan='4'><span class='status-ok'>No se encontraron errores cr&iacute;ticos recientes en el Log del Sistema.</span></td></tr>"
    }
    $html += "</table>"

    # --- SECCION 5: PESO DE ARCHIVOS TEMPORALES ---
    $html += "<h2>5. Espacio Perdido (Temporales/Cach&eacute;)</h2><table>"
    $html += "<tr><th>Ubicaci&oacute;n</th><th>Peso Estimado (MB)</th><th>Acci&oacute;n Recomendada</th></tr>"
    if ($weights) {
        $html += "<tr><td>Temporales del Sistema</td><td>$($weights.Temp_System) MB</td><td>Limpieza con Opci&oacute;n 2.3</td></tr>"
        $html += "<tr><td>Temporales del Usuario</td><td>$($weights.Temp_User) MB</td><td>Limpieza con Opci&oacute;n 2.2</td></tr>"
        $html += "<tr><td>Cach&eacute; de Navegadores</td><td>$($weights.Browser_Cache) MB</td><td>Limpieza con Opci&oacute;n 2.4</td></tr>"
        $html += "<tr><td>Cach&eacute; de Windows Update</td><td>$($weights.WinUpdate_Cache) MB</td><td>Limpieza Adicional</td></tr>"
        $html += "<tr><td>Papelera/Cach&eacute; de Internet</td><td>$($weights.Recycler_User) MB</td><td>Limpieza con Opci&oacute;n 2.5</td></tr>"
    } else {
        $html += "<tr><td colspan='3'><span class='status-warning'>ADVERTENCIA: No se pudo calcular el peso de los archivos temporales (Requiere Opci&oacute;n 2.1).</span></td></tr>"
    }
    $html += "</table>"
    
    # --- SECCION 6: SERVICIOS ---
    $html += "<h2>6. Servicios Autom&aacute;ticos Detenidos</h2><table>"
    $html += "<tr><th>Nombre</th><th>Descripci&oacute;n</th><th>Estado</th><th>Tipo Inicio</th></tr>"
    if ($anomalousServices.Count -gt 0) {
        foreach ($s in $anomalousServices) {
            $html += "<tr><td>$($s.Name)</td><td>$($s.DisplayName)</td><td><span class='status-danger'>$($s.Status)</span></td><td>$($s.StartType)</td></tr>"
        }
    } else {
        $html += "<tr><td colspan='4'><span class='status-ok'>Ning&uacute;n servicio autom&aacute;tico cr&iacute;tico detenido.</span></td></tr>"
    }
    $html += "</table>"
    
    # --- SECCION 7: PROGRAMAS INSTALADOS Y ARRANQUE ---
    $html += "<h2>7. Programas Instalados y Arranque</h2>"
    
    $html += "<h3>Programas Instalados (Total: $($installedPrograms.Count) apps)</h3>"
    $html += "<table><tr><th>Nombre</th><th>Versi&oacute;n</th><th>Fabricante</th></tr>"
    foreach ($p in $installedPrograms) {
        $html += "<tr><td>$($p.DisplayName)</td><td>$($p.DisplayVersion)</td><td>$($p.Publisher)</td></tr>"
    }
    $html += "</table>"

    $html += "<h3>Aplicaciones de Arranque (Registro y Carpetas)</h3>"
    $html += "<table><tr><th>Origen</th><th>Nombre</th><th>Ruta de Ejecuci&oacute;n</th></tr>"
    foreach ($a in $startupPrograms) {
        $html += "<tr><td>$($a.Origin)</td><td>$($a.Name)</td><td>$($a.Path)</td></tr>"
    }
    $html += "</table>"


    $html += @"
        <div class="footer">
            Generado autom&aacute;ticamente por <strong>Rachid Harkaoui</strong><br>
            Ciberseguridad & Mantenimiento Profesional
        </div>
    </div>
</body>
</html>
"@

    $html | Out-File -FilePath $reportPath -Encoding UTF8
    Write-Host "Informe generado con exito en: $reportPath" -ForegroundColor Green
}