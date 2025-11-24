# SoporteIT

Herramienta creada por **Rachid Harkaoui Rabhi** para facilitar el trabajo diario de los técnicos que atienden incidencias tanto en oficina como en visitas externas.

SoporteIT permite realizar diagnósticos, mantenimiento y generar informes completos de equipos Windows de forma rápida, clara y estandarizada.

---

## Características principales

### 1. Ficha del equipo
- Información del sistema operativo
- Fabricante y modelo
- CPU y memoria
- Unidades de disco
- Información de red
- Resumen rápido para tickets

### 2. Mantenimiento
- Limpieza de temporales
- Limpieza de cachés de navegadores
- Liberación de espacio
- Vaciar papelera
- Optimización de discos
- Puesta a punto completa

### 3. Reparación de Windows
- SFC (comprobación de integridad)
- DISM (reparación de imagen)
- Reparación de Windows Update
- Restauración de parámetros básicos
- Programar CHKDSK
- Reparación completa

### 4. Red y conectividad
- Ver configuración completa de red
- Renovar IP y DNS
- Reset Winsock y TCP/IP
- Reinicio de adaptadores
- Conexiones activas
- Resumen técnico

### 5. Diagnóstico avanzado
- Programas instalados
- Carga del sistema
- Errores críticos
- Apagados inesperados
- Servicios automáticos detenidos
- Estado de discos

### 6. Informe HTML completo
Genera un informe con toda la información del equipo, incluyendo:
- Sistema
- Hardware
- Red
- Eventos críticos
- Servicios con errores
- Programas instalados

---

## Estructura del proyecto

SoporteIT\
│  SoporteIT.ps1
│  LEEME.txt
└── Modulos\
       base.psm1
       info.psm1
       mantenimiento.psm1
       reparacion.psm1
       red.psm1
       diagnostico.psm1
       informe.psm1

---

## Modos de ejecución

### Modo completo
Si se ejecuta con permisos de administrador.

### Modo solo lectura
Si no se tienen permisos, permite:
- Diagnóstico
- Información del sistema
- Generación de informes

Pero bloquea acciones que modifican Windows.

---

## Compatibilidad
- Windows 10
- Windows 11
- PowerShell 5.1

---

## Versionado

- **1.0.0** – Versión inicial
- **1.1.0** – Nuevas funciones
- **1.1.1** – Correcciones menores

---

## Autor

**Rachid Harkaoui Rabhi**
Proyecto SoporteIT
