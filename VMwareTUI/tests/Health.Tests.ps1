function New-TestHost {
    param(
        [string]$Name = 'esxi01',
        [string]$OverallStatus = 'green',
        [string]$ConnectionState = 'connected',
        [bool]$InMaintenanceMode = $false,
        [double]$CpuPercent = 10,
        [double]$MemoryPercent = 20
    )
    return [pscustomobject]@{
        Name = $Name; OverallStatus = $OverallStatus; ConnectionState = $ConnectionState
        InMaintenanceMode = $InMaintenanceMode; CpuPercent = $CpuPercent; MemoryPercent = $MemoryPercent
        CpuUsedMhz = 1000; CpuTotalMhz = 10000; MemoryUsedMB = 2048; MemoryTotalMB = 10240
    }
}

function New-TestDatastore {
    param([string]$Name = 'datastore1', [bool]$Accessible = $true, [double]$UsedPercent = 10)
    return [pscustomobject]@{
        Name = $Name; Accessible = $Accessible; UsedPercent = $UsedPercent
        FreeGB = 900; CapacityGB = 1000
    }
}

Describe 'Get-VMwareUsagePercent' {

    It 'computes a straightforward percentage' {
        Assert-Equal 50 (Get-VMwareUsagePercent -Used 50 -Total 100)
    }

    It 'returns zero rather than dividing by zero' {
        Assert-Equal 0 (Get-VMwareUsagePercent -Used 10 -Total 0)
    }

    It 'clamps above one hundred' {
        Assert-Equal 100 (Get-VMwareUsagePercent -Used 150 -Total 100)
    }

    It 'clamps below zero' {
        Assert-Equal 0 (Get-VMwareUsagePercent -Used -10 -Total 100)
    }

    It 'rounds to the requested precision' {
        Assert-Equal 33.3 (Get-VMwareUsagePercent -Used 1 -Total 3 -Decimals 1)
    }
}

Describe 'Get-VMwareUsageSeverity' {

    It 'reports Ok below the warning threshold' {
        Assert-Equal 'Ok' (Get-VMwareUsageSeverity -Percent 50 -WarningAt 75 -CriticalAt 90)
    }

    It 'reports Warning at exactly the warning threshold' {
        Assert-Equal 'Warning' (Get-VMwareUsageSeverity -Percent 75 -WarningAt 75 -CriticalAt 90)
    }

    It 'reports Critical at exactly the critical threshold' {
        Assert-Equal 'Critical' (Get-VMwareUsageSeverity -Percent 90 -WarningAt 75 -CriticalAt 90)
    }

    It 'reports Critical above the critical threshold' {
        Assert-Equal 'Critical' (Get-VMwareUsageSeverity -Percent 99 -WarningAt 75 -CriticalAt 90)
    }
}

Describe 'Get-VMwareWorstSeverity' {

    It 'returns Ok for an empty set' {
        Assert-Equal 'Ok' (Get-VMwareWorstSeverity -Severity @())
    }

    It 'lets Critical win over Warning' {
        Assert-Equal 'Critical' (Get-VMwareWorstSeverity -Severity @('Ok', 'Warning', 'Critical'))
    }

    It 'lets Warning win over Ok' {
        Assert-Equal 'Warning' (Get-VMwareWorstSeverity -Severity @('Ok', 'Warning'))
    }
}

Describe 'Get-VMwareHostFinding' {

    It 'reports nothing for a healthy host' {
        Assert-Equal 0 @(Get-VMwareHostFinding -VMHost (New-TestHost)).Count
    }

    It 'flags a disconnected host as critical' {
        $f = @(Get-VMwareHostFinding -VMHost (New-TestHost -ConnectionState 'notResponding'))
        Assert-Equal 1 $f.Count
        Assert-Equal 'Critical' $f[0].Severity
    }

    It 'flags maintenance mode as a warning' {
        $f = @(Get-VMwareHostFinding -VMHost (New-TestHost -InMaintenanceMode $true))
        Assert-Equal 'Warning' $f[0].Severity
    }

    It 'flags a red overall status as critical' {
        $f = @(Get-VMwareHostFinding -VMHost (New-TestHost -OverallStatus 'red'))
        Assert-Equal 'Critical' $f[0].Severity
    }

    It 'flags high CPU as critical' {
        $f = @(Get-VMwareHostFinding -VMHost (New-TestHost -CpuPercent 95))
        Assert-True ($f.Count -ge 1)
        Assert-Equal 'Critical' $f[0].Severity
    }

    It 'flags elevated memory as a warning' {
        $f = @(Get-VMwareHostFinding -VMHost (New-TestHost -MemoryPercent 88))
        Assert-Equal 'Warning' $f[0].Severity
    }

    It 'reports several findings at once for a badly degraded host' {
        $f = @(Get-VMwareHostFinding -VMHost (New-TestHost -OverallStatus 'red' -CpuPercent 99 -MemoryPercent 99))
        Assert-Equal 3 $f.Count
    }
}

Describe 'Get-VMwareDatastoreFinding' {

    It 'reports nothing for a healthy datastore' {
        Assert-Equal 0 @(Get-VMwareDatastoreFinding -Datastore (New-TestDatastore)).Count
    }

    It 'flags an inaccessible datastore as critical' {
        $f = @(Get-VMwareDatastoreFinding -Datastore (New-TestDatastore -Accessible $false))
        Assert-Equal 'Critical' $f[0].Severity
    }

    It 'does not also report capacity for an inaccessible datastore' {
        $f = @(Get-VMwareDatastoreFinding -Datastore (New-TestDatastore -Accessible $false -UsedPercent 99))
        Assert-Equal 1 $f.Count
    }

    It 'flags a nearly full datastore as critical' {
        $f = @(Get-VMwareDatastoreFinding -Datastore (New-TestDatastore -UsedPercent 97))
        Assert-Equal 'Critical' $f[0].Severity
    }
}

Describe 'Test-VMwareToolsReady' {

    It 'accepts running current tools' {
        Assert-True (Test-VMwareToolsReady -ToolsStatus 'toolsOk' -ToolsRunningStatus 'guestToolsRunning')
    }

    It 'accepts out-of-date tools, which still answer shutdown requests' {
        Assert-True (Test-VMwareToolsReady -ToolsStatus 'toolsOld' -ToolsRunningStatus 'guestToolsRunning')
    }

    It 'rejects tools that are not installed' {
        Assert-False (Test-VMwareToolsReady -ToolsStatus 'toolsNotInstalled' -ToolsRunningStatus 'guestToolsNotRunning')
    }

    It 'rejects installed but stopped tools' {
        Assert-False (Test-VMwareToolsReady -ToolsStatus 'toolsOk' -ToolsRunningStatus 'guestToolsNotRunning')
    }

    It 'rejects a null status' {
        Assert-False (Test-VMwareToolsReady -ToolsStatus $null -ToolsRunningStatus $null)
    }
}

Describe 'Get-VMwareFilteredVM' {

    $vms = @(
        [pscustomobject]@{ Name = 'DC01';     GuestOS = 'Windows Server 2022'; IPAddress = '10.0.0.10' }
        [pscustomobject]@{ Name = 'WEB01';    GuestOS = 'Ubuntu Linux 22.04';  IPAddress = '10.0.0.20' }
        [pscustomobject]@{ Name = 'BACKUP01'; GuestOS = 'Windows Server 2019'; IPAddress = '192.168.1.5' }
    )

    It 'returns everything when no filter is set' {
        Assert-Equal 3 @(Get-VMwareFilteredVM -VMs $vms -Filter '').Count
    }

    It 'returns everything for a whitespace filter' {
        Assert-Equal 3 @(Get-VMwareFilteredVM -VMs $vms -Filter '   ').Count
    }

    It 'matches on VM name' {
        $r = @(Get-VMwareFilteredVM -VMs $vms -Filter 'DC')
        Assert-Equal 1 $r.Count
        Assert-Equal 'DC01' $r[0].Name
    }

    It 'matches on guest OS' {
        Assert-Equal 2 @(Get-VMwareFilteredVM -VMs $vms -Filter 'Windows').Count
    }

    It 'matches on an IP prefix' {
        Assert-Equal 2 @(Get-VMwareFilteredVM -VMs $vms -Filter '10.0.0.').Count
    }

    It 'is case insensitive' {
        Assert-Equal 1 @(Get-VMwareFilteredVM -VMs $vms -Filter 'dc01').Count
    }

    It 'returns nothing when there is no match' {
        Assert-Equal 0 @(Get-VMwareFilteredVM -VMs $vms -Filter 'zzzz').Count
    }
}
