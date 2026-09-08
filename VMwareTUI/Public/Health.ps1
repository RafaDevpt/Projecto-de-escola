# Health evaluation.
#
# The goal is to answer "is anything wrong right now?" without the operator
# having to read numbers off a dashboard. Every rule produces a Finding with a
# severity, and the worst severity becomes the overall verdict.

$script:VMwareThresholds = @{
    CpuWarning        = 75
    CpuCritical       = 90
    MemoryWarning     = 85
    MemoryCritical    = 95
    DatastoreWarning  = 85
    DatastoreCritical = 95
}

function New-VMwareFinding {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][ValidateSet('Ok', 'Warning', 'Critical')][string]$Severity,
        [Parameter(Mandatory)][string]$Scope,
        [Parameter(Mandatory)][string]$Subject,
        [Parameter(Mandatory)][string]$Message
    )

    return [pscustomobject]@{
        Severity = $Severity
        Scope    = $Scope
        Subject  = $Subject
        Message  = $Message
    }
}

function Get-VMwareWorstSeverity {
    <#
        .SYNOPSIS
            Reduces a set of severities to the most serious one.
        .NOTES
            Pure function - covered by the unit tests.
    #>
    [CmdletBinding()]
    param([string[]]$Severity)

    if (-not $Severity -or $Severity.Count -eq 0) { return 'Ok' }
    if ($Severity -contains 'Critical') { return 'Critical' }
    if ($Severity -contains 'Warning')  { return 'Warning' }
    return 'Ok'
}

function Get-VMwareUsageSeverity {
    <#
        .SYNOPSIS
            Maps a utilisation percentage onto a severity using two thresholds.
        .NOTES
            Pure function - covered by the unit tests.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][double]$Percent,
        [Parameter(Mandatory)][double]$WarningAt,
        [Parameter(Mandatory)][double]$CriticalAt
    )

    if ($Percent -ge $CriticalAt) { return 'Critical' }
    if ($Percent -ge $WarningAt)  { return 'Warning' }
    return 'Ok'
}

function Get-VMwareHostFinding {
    <#
        .SYNOPSIS
            Applies the host rules to one host object.
        .NOTES
            Takes plain objects rather than a connection, so it is unit testable.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)]$VMHost)

    $findings = New-Object System.Collections.Generic.List[object]

    if ($VMHost.ConnectionState -and $VMHost.ConnectionState -ne 'connected') {
        $findings.Add((New-VMwareFinding -Severity 'Critical' -Scope 'Host' -Subject $VMHost.Name `
            -Message "Host is $($VMHost.ConnectionState)."))
    }

    if ($VMHost.InMaintenanceMode) {
        $findings.Add((New-VMwareFinding -Severity 'Warning' -Scope 'Host' -Subject $VMHost.Name `
            -Message 'Host is in maintenance mode.'))
    }

    switch ($VMHost.OverallStatus) {
        'red'    { $findings.Add((New-VMwareFinding -Severity 'Critical' -Scope 'Host' -Subject $VMHost.Name -Message 'Host reports a red alarm.')) }
        'yellow' { $findings.Add((New-VMwareFinding -Severity 'Warning'  -Scope 'Host' -Subject $VMHost.Name -Message 'Host reports a yellow alarm.')) }
    }

    $cpuSeverity = Get-VMwareUsageSeverity -Percent $VMHost.CpuPercent `
        -WarningAt $script:VMwareThresholds.CpuWarning -CriticalAt $script:VMwareThresholds.CpuCritical
    if ($cpuSeverity -ne 'Ok') {
        $findings.Add((New-VMwareFinding -Severity $cpuSeverity -Scope 'Host' -Subject $VMHost.Name `
            -Message ("CPU at {0}% ({1} of {2} MHz)." -f $VMHost.CpuPercent, $VMHost.CpuUsedMhz, $VMHost.CpuTotalMhz)))
    }

    $memSeverity = Get-VMwareUsageSeverity -Percent $VMHost.MemoryPercent `
        -WarningAt $script:VMwareThresholds.MemoryWarning -CriticalAt $script:VMwareThresholds.MemoryCritical
    if ($memSeverity -ne 'Ok') {
        $findings.Add((New-VMwareFinding -Severity $memSeverity -Scope 'Host' -Subject $VMHost.Name `
            -Message ("Memory at {0}% ({1} of {2} MB)." -f $VMHost.MemoryPercent, $VMHost.MemoryUsedMB, $VMHost.MemoryTotalMB)))
    }

    return $findings.ToArray()
}

function Get-VMwareDatastoreFinding {
    <#
        .SYNOPSIS
            Applies the datastore rules to one datastore object.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Datastore)

    $findings = New-Object System.Collections.Generic.List[object]

    if (-not $Datastore.Accessible) {
        $findings.Add((New-VMwareFinding -Severity 'Critical' -Scope 'Datastore' -Subject $Datastore.Name `
            -Message 'Datastore is not accessible.'))
        return $findings.ToArray()
    }

    $severity = Get-VMwareUsageSeverity -Percent $Datastore.UsedPercent `
        -WarningAt $script:VMwareThresholds.DatastoreWarning -CriticalAt $script:VMwareThresholds.DatastoreCritical
    if ($severity -ne 'Ok') {
        $findings.Add((New-VMwareFinding -Severity $severity -Scope 'Datastore' -Subject $Datastore.Name `
            -Message ("{0}% full, {1} GB free of {2} GB." -f $Datastore.UsedPercent, $Datastore.FreeGB, $Datastore.CapacityGB)))
    }

    return $findings.ToArray()
}

function Get-VMwareHealthReport {
    <#
        .SYNOPSIS
            Evaluates the overall state of the connected server.

        .DESCRIPTION
            Collects hosts, datastores and VMs, runs every rule, and returns a
            single verdict plus the findings behind it. This is what the TUI's
            health view renders, and it is useful on its own for a scheduled
            check.

        .EXAMPLE
            $report = Get-VMwareHealthReport -Connection $c
            if ($report.Verdict -ne 'Ok') { $report.Findings | Format-Table }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Connection,
        $VMHosts,
        $Datastores,
        $VMs
    )

    if ($null -eq $VMHosts)    { $VMHosts    = Get-VMwareHost -Connection $Connection }
    if ($null -eq $Datastores) { $Datastores = Get-VMwareDatastore -Connection $Connection }
    if ($null -eq $VMs)        { $VMs        = Get-VMwareVM -Connection $Connection }

    $findings = New-Object System.Collections.Generic.List[object]

    foreach ($h in @($VMHosts))    { foreach ($f in (Get-VMwareHostFinding -VMHost $h))          { $findings.Add($f) } }
    foreach ($d in @($Datastores)) { foreach ($f in (Get-VMwareDatastoreFinding -Datastore $d)) { $findings.Add($f) } }

    # VMware Tools that is missing on a running VM is not an outage, but it does
    # mean this tool cannot shut that VM down gracefully - worth surfacing.
    $toolsMissing = @(@($VMs) | Where-Object {
        $_.PowerState -eq 'poweredOn' -and -not (Test-VMwareToolsReady -ToolsStatus $_.ToolsStatus -ToolsRunningStatus $_.ToolsRunning)
    })
    if ($toolsMissing.Count -gt 0) {
        $names = ($toolsMissing | Select-Object -First 5 | ForEach-Object { $_.Name }) -join ', '
        $suffix = if ($toolsMissing.Count -gt 5) { ", +$($toolsMissing.Count - 5) more" } else { '' }
        $findings.Add((New-VMwareFinding -Severity 'Warning' -Scope 'VM' -Subject 'VMware Tools' `
            -Message ("{0} powered-on VM(s) cannot be shut down gracefully: {1}{2}." -f $toolsMissing.Count, $names, $suffix)))
    }

    $poweredOn = @(@($VMs) | Where-Object { $_.PowerState -eq 'poweredOn' }).Count

    return [pscustomobject]@{
        Server        = $Connection.Server
        Product       = $Connection.ProductName
        IsVCenter     = $Connection.IsVCenter
        GeneratedAt   = Get-Date
        Verdict       = Get-VMwareWorstSeverity -Severity @($findings | ForEach-Object { $_.Severity })
        Findings      = $findings.ToArray()
        HostCount     = @($VMHosts).Count
        VMCount       = @($VMs).Count
        VMPoweredOn   = $poweredOn
        VMPoweredOff  = @($VMs).Count - $poweredOn
        DatastoreCount = @($Datastores).Count
        Hosts         = @($VMHosts)
        Datastores    = @($Datastores)
    }
}
