function Get-VMwarePropValue {
    <#
        .SYNOPSIS
            Reads one key from a property hashtable, with a default.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$Properties,
        [Parameter(Mandatory)][string]$Name,
        $Default = $null
    )

    if (-not $Properties.ContainsKey($Name)) { return $Default }
    $value = $Properties[$Name]
    if ($null -eq $value -or $value -eq '') { return $Default }
    return $value
}

function ConvertTo-VMwareInt64 {
    <#
        .SYNOPSIS
            Tolerant numeric conversion; vSphere returns everything as text.
    #>
    [CmdletBinding()]
    param([AllowNull()]$Value, [long]$Default = 0)

    if ($null -eq $Value) { return $Default }
    $parsed = [long]0
    if ([long]::TryParse([string]$Value, [ref]$parsed)) { return $parsed }
    return $Default
}

function Get-VMwareUsagePercent {
    <#
        .SYNOPSIS
            Used/Total as a percentage, rounded, guarded against divide-by-zero.
        .NOTES
            Pure function - covered by the unit tests.
    #>
    [CmdletBinding()]
    param(
        [double]$Used,
        [double]$Total,
        [int]$Decimals = 0
    )

    if ($Total -le 0) { return 0 }
    $percent = ($Used / $Total) * 100
    if ($percent -lt 0)   { $percent = 0 }
    if ($percent -gt 100) { $percent = 100 }
    return [math]::Round($percent, $Decimals)
}

function Get-VMwareVM {
    <#
        .SYNOPSIS
            Lists virtual machines with power state, sizing and guest details.

        .PARAMETER IncludeTemplates
            Templates are excluded by default - they cannot be powered on and
            only clutter the list.

        .PARAMETER Name
            Optional wildcard filter, e.g. -Name 'DC*'.

        .EXAMPLE
            Get-VMwareVM -Connection $c | Where-Object PowerState -eq 'poweredOn'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Connection,
        [string]$Name,
        [switch]$IncludeTemplates
    )

    $properties = @(
        'name'
        'config.template'
        'config.guestFullName'
        'config.hardware.numCPU'
        'config.hardware.memoryMB'
        'runtime.powerState'
        'runtime.host'
        'guest.ipAddress'
        'guest.hostName'
        'guest.toolsStatus'
        'guest.toolsRunningStatus'
        'summary.quickStats.overallCpuUsage'
        'summary.quickStats.guestMemoryUsage'
        'summary.config.annotation'
    )

    $raw = Get-VMwarePropertySet -Connection $Connection -Type 'VirtualMachine' -Properties $properties

    # Resolve host MoRefs to names so the UI can show where a VM runs. One call
    # for the whole inventory rather than one per VM.
    $hostNames = @{}
    if ($Connection.IsVCenter) {
        try {
            foreach ($h in (Get-VMwarePropertySet -Connection $Connection -Type 'HostSystem' -Properties @('name'))) {
                $hostNames[$h.MoRef] = [string]$h['name']
            }
        } catch {
            Write-Verbose "Could not resolve host names: $($_.Exception.Message)"
        }
    }

    $results = foreach ($props in $raw) {
        $isTemplate = ([string](Get-VMwarePropValue $props 'config.template' 'false')) -eq 'true'
        if ($isTemplate -and -not $IncludeTemplates) { continue }

        $vmName = [string](Get-VMwarePropValue $props 'name' '(unnamed)')
        if ($Name -and $vmName -notlike $Name) { continue }

        $hostRef  = Get-VMwarePropValue $props 'runtime.host'
        $hostName = $null
        if ($hostRef) {
            $key = if ($hostRef -is [string]) { $hostRef } else { $hostRef.InnerText }
            if ($key -and $hostNames.ContainsKey($key)) { $hostName = $hostNames[$key] }
        }

        $memoryMB = ConvertTo-VMwareInt64 (Get-VMwarePropValue $props 'config.hardware.memoryMB')

        [pscustomobject]@{
            Name           = $vmName
            MoRef          = $props.MoRef
            PowerState     = [string](Get-VMwarePropValue $props 'runtime.powerState' 'unknown')
            IsTemplate     = $isTemplate
            GuestOS        = [string](Get-VMwarePropValue $props 'config.guestFullName' '')
            NumCpu         = [int](ConvertTo-VMwareInt64 (Get-VMwarePropValue $props 'config.hardware.numCPU'))
            MemoryMB       = $memoryMB
            MemoryGB       = [math]::Round($memoryMB / 1024, 1)
            IPAddress      = [string](Get-VMwarePropValue $props 'guest.ipAddress' '')
            GuestHostName  = [string](Get-VMwarePropValue $props 'guest.hostName' '')
            ToolsStatus    = [string](Get-VMwarePropValue $props 'guest.toolsStatus' 'toolsNotInstalled')
            ToolsRunning   = [string](Get-VMwarePropValue $props 'guest.toolsRunningStatus' '')
            CpuUsageMhz    = [int](ConvertTo-VMwareInt64 (Get-VMwarePropValue $props 'summary.quickStats.overallCpuUsage'))
            MemUsageMB     = [int](ConvertTo-VMwareInt64 (Get-VMwarePropValue $props 'summary.quickStats.guestMemoryUsage'))
            HostName       = $hostName
            Annotation     = [string](Get-VMwarePropValue $props 'summary.config.annotation' '')
        }
    }

    return @($results | Sort-Object Name)
}

function Get-VMwareHost {
    <#
        .SYNOPSIS
            Lists ESXi hosts with health, capacity and utilisation.
        .DESCRIPTION
            Against a standalone ESXi host this returns exactly one object -
            the host itself.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Connection)

    $properties = @(
        'name'
        'summary.overallStatus'
        'summary.hardware.cpuMhz'
        'summary.hardware.numCpuCores'
        'summary.hardware.numCpuPkgs'
        'summary.hardware.memorySize'
        'summary.hardware.model'
        'summary.hardware.vendor'
        'summary.quickStats.overallCpuUsage'
        'summary.quickStats.overallMemoryUsage'
        'summary.quickStats.uptime'
        'config.product.fullName'
        'config.product.version'
        'config.product.build'
        'runtime.inMaintenanceMode'
        'runtime.connectionState'
        'runtime.powerState'
    )

    $raw = Get-VMwarePropertySet -Connection $Connection -Type 'HostSystem' -Properties $properties

    $results = foreach ($props in $raw) {
        $cpuMhz     = ConvertTo-VMwareInt64 (Get-VMwarePropValue $props 'summary.hardware.cpuMhz')
        $cores      = ConvertTo-VMwareInt64 (Get-VMwarePropValue $props 'summary.hardware.numCpuCores')
        $memBytes   = ConvertTo-VMwareInt64 (Get-VMwarePropValue $props 'summary.hardware.memorySize')
        $cpuUsed    = ConvertTo-VMwareInt64 (Get-VMwarePropValue $props 'summary.quickStats.overallCpuUsage')
        $memUsedMB  = ConvertTo-VMwareInt64 (Get-VMwarePropValue $props 'summary.quickStats.overallMemoryUsage')
        $uptimeSec  = ConvertTo-VMwareInt64 (Get-VMwarePropValue $props 'summary.quickStats.uptime')

        $cpuTotal = $cpuMhz * $cores
        $memTotalMB = [math]::Round($memBytes / 1MB, 0)

        [pscustomobject]@{
            Name              = [string](Get-VMwarePropValue $props 'name' '(unnamed)')
            MoRef             = $props.MoRef
            OverallStatus     = [string](Get-VMwarePropValue $props 'summary.overallStatus' 'gray')
            ConnectionState   = [string](Get-VMwarePropValue $props 'runtime.connectionState' 'unknown')
            PowerState        = [string](Get-VMwarePropValue $props 'runtime.powerState' 'unknown')
            InMaintenanceMode = ([string](Get-VMwarePropValue $props 'runtime.inMaintenanceMode' 'false')) -eq 'true'
            Product           = [string](Get-VMwarePropValue $props 'config.product.fullName' '')
            Version           = [string](Get-VMwarePropValue $props 'config.product.version' '')
            Build             = [string](Get-VMwarePropValue $props 'config.product.build' '')
            Vendor            = [string](Get-VMwarePropValue $props 'summary.hardware.vendor' '')
            Model             = [string](Get-VMwarePropValue $props 'summary.hardware.model' '')
            CpuCores          = [int]$cores
            CpuSockets        = [int](ConvertTo-VMwareInt64 (Get-VMwarePropValue $props 'summary.hardware.numCpuPkgs'))
            CpuTotalMhz       = [long]$cpuTotal
            CpuUsedMhz        = [long]$cpuUsed
            CpuPercent        = Get-VMwareUsagePercent -Used $cpuUsed -Total $cpuTotal
            MemoryTotalMB     = [long]$memTotalMB
            MemoryUsedMB      = [long]$memUsedMB
            MemoryPercent     = Get-VMwareUsagePercent -Used $memUsedMB -Total $memTotalMB
            MemoryTotalGB     = [math]::Round($memBytes / 1GB, 1)
            UptimeSeconds     = [long]$uptimeSec
            UptimeText        = Format-VMwareUptime -Seconds $uptimeSec
        }
    }

    return @($results | Sort-Object Name)
}

function Get-VMwareDatastore {
    <#
        .SYNOPSIS
            Lists datastores with capacity and free space.
        .DESCRIPTION
            A full datastore is one of the most common causes of VMs refusing to
            power on, so this gets its own view in the TUI.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Connection)

    $properties = @(
        'summary.name'
        'summary.capacity'
        'summary.freeSpace'
        'summary.type'
        'summary.accessible'
        'summary.maintenanceMode'
    )

    $raw = Get-VMwarePropertySet -Connection $Connection -Type 'Datastore' -Properties $properties

    $results = foreach ($props in $raw) {
        $capacity = ConvertTo-VMwareInt64 (Get-VMwarePropValue $props 'summary.capacity')
        $free     = ConvertTo-VMwareInt64 (Get-VMwarePropValue $props 'summary.freeSpace')
        $used     = $capacity - $free

        [pscustomobject]@{
            Name         = [string](Get-VMwarePropValue $props 'summary.name' '(unnamed)')
            MoRef        = $props.MoRef
            Type         = [string](Get-VMwarePropValue $props 'summary.type' '')
            Accessible   = ([string](Get-VMwarePropValue $props 'summary.accessible' 'false')) -eq 'true'
            CapacityGB   = [math]::Round($capacity / 1GB, 1)
            FreeGB       = [math]::Round($free / 1GB, 1)
            UsedGB       = [math]::Round($used / 1GB, 1)
            UsedPercent  = Get-VMwareUsagePercent -Used $used -Total $capacity
        }
    }

    return @($results | Sort-Object Name)
}

function Format-VMwareUptime {
    <#
        .SYNOPSIS
            Renders a second count as a compact uptime string ("12d 4h").
        .NOTES
            Pure function - covered by the unit tests.
    #>
    [CmdletBinding()]
    param([long]$Seconds)

    if ($Seconds -le 0) { return '-' }

    $span = [TimeSpan]::FromSeconds($Seconds)
    if ($span.Days -gt 0)  { return ('{0}d {1}h' -f $span.Days, $span.Hours) }
    if ($span.Hours -gt 0) { return ('{0}h {1}m' -f $span.Hours, $span.Minutes) }
    return ('{0}m' -f $span.Minutes)
}
