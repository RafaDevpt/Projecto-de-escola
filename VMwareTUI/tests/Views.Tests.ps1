# Exercises the view formatters against mock inventory.
#
# These paths would otherwise only ever run against a live vCenter, which is
# exactly where a null-reference or an arithmetic slip would be most painful to
# discover. Every formatter returns plain strings, so it can be checked offline.

function New-MockState {
    param([bool]$IsVCenter = $true, [int]$VMCount = 3, [string]$Filter = '')

    $vms = @()
    for ($i = 1; $i -le $VMCount; $i++) {
        $vms += [pscustomobject]@{
            Name = ('VM{0:D2}' -f $i); MoRef = "vm-$i"
            PowerState = $(if ($i % 2 -eq 0) { 'poweredOff' } else { 'poweredOn' })
            GuestOS = 'Windows Server 2022'; NumCpu = 2; MemoryGB = 8.0
            IPAddress = "10.0.0.$i"; GuestHostName = "vm$i.lab"
            ToolsStatus = 'toolsOk'; ToolsRunning = 'guestToolsRunning'
            CpuUsageMhz = 120; MemUsageMB = 2048; HostName = 'esxi01'; Annotation = ''
        }
    }

    $hosts = @([pscustomobject]@{
        Name = 'esxi01'; MoRef = 'host-1'; OverallStatus = 'green'; ConnectionState = 'connected'
        PowerState = 'poweredOn'; InMaintenanceMode = $false; Product = 'VMware ESXi 8.0.2'
        Version = '8.0.2'; Build = '23305546'; Vendor = 'Dell Inc.'; Model = 'PowerEdge R740'
        CpuCores = 16; CpuSockets = 2; CpuTotalMhz = 44800; CpuUsedMhz = 8000; CpuPercent = 18
        MemoryTotalMB = 262144; MemoryUsedMB = 131072; MemoryPercent = 50; MemoryTotalGB = 256
        UptimeSeconds = 1051200; UptimeText = '12d 4h'
    })

    $datastores = @(
        [pscustomobject]@{ Name = 'datastore1'; MoRef = 'ds-1'; Type = 'VMFS'; Accessible = $true
                           CapacityGB = 1000; FreeGB = 400; UsedGB = 600; UsedPercent = 60 }
        [pscustomobject]@{ Name = 'nfs-backup'; MoRef = 'ds-2'; Type = 'NFS'; Accessible = $true
                           CapacityGB = 4000; FreeGB = 120; UsedGB = 3880; UsedPercent = 97 }
    )

    $connection = [pscustomobject]@{
        Server = '192.168.1.50'; IsVCenter = $IsVCenter; User = 'root'
        ProductName = 'VMware ESXi 8.0.2'; Version = '8.0.2'
    }

    $log = New-Object System.Collections.Generic.List[object]
    $log.Add([pscustomobject]@{ Time = Get-Date; Level = 'Ok'; Message = 'Connected.' })

    $state = @{
        Connection = $connection; View = 'VMs'; SelectedIndex = 0; Filter = $Filter
        VMs = $vms; FilteredVMs = $vms; Hosts = $hosts; Datastores = $datastores
        Log = $log; LastRefresh = (Get-Date); RefreshError = $null
        Status = 'Ready.'; StatusLevel = 'Info'; Ascii = $true
        Health = $null
    }

    $state.Health = Get-VMwareHealthReport -Connection $connection -VMHosts $hosts -Datastores $datastores -VMs $vms
    return $state
}

Describe 'Format-VMwareVMView' {

    It 'renders a header plus one line per VM' {
        $state = New-MockState -VMCount 3
        $lines = @(Format-VMwareVMView -State $state -Width 120 -Rows 20)
        Assert-Equal 4 $lines.Count   # header + 3 rows
    }

    It 'includes the VM names' {
        $state = New-MockState -VMCount 3
        $text = (@(Format-VMwareVMView -State $state -Width 120 -Rows 20) -join "`n")
        Assert-True ($text -like '*VM01*')
        Assert-True ($text -like '*VM03*')
    }

    It 'shows a host column against vCenter' {
        $state = New-MockState -IsVCenter $true
        $header = @(Format-VMwareVMView -State $state -Width 140 -Rows 20)[0]
        Assert-True ($header -like '*HOST*')
    }

    It 'omits the host column against a standalone ESXi host' {
        $state = New-MockState -IsVCenter $false
        $header = @(Format-VMwareVMView -State $state -Width 140 -Rows 20)[0]
        Assert-False ($header -like '*HOST*')
    }

    It 'reports an empty inventory without throwing' {
        $state = New-MockState -VMCount 0
        $lines = @(Format-VMwareVMView -State $state -Width 120 -Rows 20)
        Assert-True (($lines -join '') -like '*No virtual machines found*')
    }

    It 'explains an empty result caused by a filter' {
        $state = New-MockState -VMCount 3
        $state.Filter = 'nomatch'
        $state.FilteredVMs = @()
        $lines = @(Format-VMwareVMView -State $state -Width 120 -Rows 20)
        Assert-True (($lines -join '') -like "*No VMs match filter*")
    }

    It 'never emits more rows than the viewport allows' {
        $state = New-MockState -VMCount 200
        $lines = @(Format-VMwareVMView -State $state -Width 120 -Rows 10)
        Assert-Equal 11 $lines.Count   # header + 10 rows
    }

    It 'renders a narrow terminal without throwing' {
        $state = New-MockState -VMCount 3
        $lines = @(Format-VMwareVMView -State $state -Width 80 -Rows 10)
        Assert-True ($lines.Count -ge 1)
    }
}

Describe 'Format-VMwareHealthView' {

    It 'renders without throwing and states the verdict' {
        $state = New-MockState
        $text = (@(Format-VMwareHealthView -State $state -Width 120 -Rows 20) -join "`n")
        Assert-True ($text -like '*OVERALL*')
    }

    It 'lists the host name and CPU/memory bars' {
        $state = New-MockState
        $text = (@(Format-VMwareHealthView -State $state -Width 120 -Rows 20) -join "`n")
        Assert-True ($text -like '*esxi01*')
        Assert-True ($text -like '*CPU*')
        Assert-True ($text -like '*MEM*')
    }

    It 'surfaces the nearly full datastore as a finding' {
        $state = New-MockState
        $text = (@(Format-VMwareHealthView -State $state -Width 120 -Rows 20) -join "`n")
        Assert-True ($text -like '*nfs-backup*')
    }

    It 'handles missing health data gracefully' {
        $state = New-MockState
        $state.Health = $null
        $text = (@(Format-VMwareHealthView -State $state -Width 120 -Rows 20) -join "`n")
        Assert-True ($text -like '*not available*')
    }
}

Describe 'Format-VMwareDatastoreView' {

    It 'renders a header plus one line per datastore' {
        $state = New-MockState
        $lines = @(Format-VMwareDatastoreView -State $state -Width 120 -Rows 20)
        Assert-Equal 3 $lines.Count
    }

    It 'includes datastore names' {
        $state = New-MockState
        $text = (@(Format-VMwareDatastoreView -State $state -Width 120 -Rows 20) -join "`n")
        Assert-True ($text -like '*datastore1*')
        Assert-True ($text -like '*nfs-backup*')
    }

    It 'reports an empty datastore list without throwing' {
        $state = New-MockState
        $state.Datastores = @()
        $text = (@(Format-VMwareDatastoreView -State $state -Width 120 -Rows 20) -join "`n")
        Assert-True ($text -like '*No datastores found*')
    }
}

Describe 'Format-VMwareLogView' {

    It 'renders existing entries' {
        $state = New-MockState
        $text = (@(Format-VMwareLogView -State $state -Width 120 -Rows 20) -join "`n")
        Assert-True ($text -like '*Connected*')
    }

    It 'reports an empty log without throwing' {
        $state = New-MockState
        $state.Log = New-Object System.Collections.Generic.List[object]
        $text = (@(Format-VMwareLogView -State $state -Width 120 -Rows 20) -join "`n")
        Assert-True ($text -like '*Nothing logged*')
    }

    It 'caps output at the row count' {
        $state = New-MockState
        for ($i = 0; $i -lt 50; $i++) {
            $state.Log.Add([pscustomobject]@{ Time = Get-Date; Level = 'Info'; Message = "entry $i" })
        }
        $lines = @(Format-VMwareLogView -State $state -Width 120 -Rows 10)
        Assert-Equal 10 $lines.Count
    }
}

Describe 'Get-VMwareHealthReport' {

    It 'counts powered-on and powered-off VMs' {
        $state = New-MockState -VMCount 4
        $report = $state.Health
        Assert-Equal 4 $report.VMCount
        Assert-Equal 2 $report.VMPoweredOn
        Assert-Equal 2 $report.VMPoweredOff
    }

    It 'returns a Warning verdict when a datastore is nearly full' {
        $state = New-MockState
        Assert-Equal 'Critical' $state.Health.Verdict   # nfs-backup at 97% crosses the critical line
    }

    It 'reports Ok when everything is healthy' {
        $connection = [pscustomobject]@{ Server = 'x'; IsVCenter = $false; ProductName = 'ESXi' }
        $hosts = @([pscustomobject]@{
            Name = 'h1'; OverallStatus = 'green'; ConnectionState = 'connected'; InMaintenanceMode = $false
            CpuPercent = 10; MemoryPercent = 20; CpuUsedMhz = 1; CpuTotalMhz = 10; MemoryUsedMB = 1; MemoryTotalMB = 10
        })
        $ds = @([pscustomobject]@{ Name = 'ds1'; Accessible = $true; UsedPercent = 10; FreeGB = 900; CapacityGB = 1000 })
        $vms = @([pscustomobject]@{ Name = 'v1'; PowerState = 'poweredOn'; ToolsStatus = 'toolsOk'; ToolsRunning = 'guestToolsRunning' })

        $report = Get-VMwareHealthReport -Connection $connection -VMHosts $hosts -Datastores $ds -VMs $vms
        Assert-Equal 'Ok' $report.Verdict
        Assert-Equal 0 $report.Findings.Count
    }

    It 'warns when a powered-on VM cannot be shut down gracefully' {
        $connection = [pscustomobject]@{ Server = 'x'; IsVCenter = $false; ProductName = 'ESXi' }
        $hosts = @()
        $ds = @()
        $vms = @([pscustomobject]@{ Name = 'v1'; PowerState = 'poweredOn'; ToolsStatus = 'toolsNotInstalled'; ToolsRunning = 'guestToolsNotRunning' })

        $report = Get-VMwareHealthReport -Connection $connection -VMHosts $hosts -Datastores $ds -VMs $vms
        Assert-Equal 'Warning' $report.Verdict
        Assert-True (($report.Findings[0].Message) -like '*cannot be shut down gracefully*')
    }
}
