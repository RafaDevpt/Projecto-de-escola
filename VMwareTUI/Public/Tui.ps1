# The interactive console.
#
# Four views (VMs, Health, Datastores, Activity log) share one render/input
# loop. Data is refreshed on a timer and on demand; the loop stays responsive
# by polling for keys rather than blocking on ReadKey.

function Read-VMwareKeyWithTimeout {
    <#
        .SYNOPSIS
            Waits up to $TimeoutMs for a keypress. Returns $null on timeout,
            which is what drives the periodic refresh.
    #>
    [CmdletBinding()]
    param([int]$TimeoutMs = 1000)

    $deadline = (Get-Date).AddMilliseconds($TimeoutMs)
    while ((Get-Date) -lt $deadline) {
        if ([Console]::KeyAvailable) { return [Console]::ReadKey($true) }
        Start-Sleep -Milliseconds 40
    }
    return $null
}

function Write-VMwareScreen {
    <#
        .SYNOPSIS
            Paints the frame. Redraws in place and clears to end of line rather
            than calling Clear-Host, which would flicker on every refresh.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][string[]]$Lines, [int]$Height)

    $esc = [char]27
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.Append("$esc[H")   # home

    for ($i = 0; $i -lt $Height; $i++) {
        $line = if ($i -lt $Lines.Count) { $Lines[$i] } else { '' }
        [void]$sb.Append($line)
        [void]$sb.Append("$esc[K")   # clear rest of line
        if ($i -lt $Height - 1) { [void]$sb.Append("`n") }
    }

    [Console]::Write($sb.ToString())
}

function Add-VMwareLogEntry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$State,
        [Parameter(Mandatory)][string]$Message,
        [ValidateSet('Info', 'Ok', 'Warning', 'Error')][string]$Level = 'Info'
    )

    $State.Log.Insert(0, [pscustomobject]@{
        Time    = Get-Date
        Level   = $Level
        Message = $Message
    })

    while ($State.Log.Count -gt 200) { $State.Log.RemoveAt($State.Log.Count - 1) }
}

function Update-VMwareConsoleData {
    <#
        .SYNOPSIS
            Refreshes inventory and health into the UI state object.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)]$State)

    try {
        $State.VMs        = @(Get-VMwareVM -Connection $State.Connection)
        $State.Hosts      = @(Get-VMwareHost -Connection $State.Connection)
        $State.Datastores = @(Get-VMwareDatastore -Connection $State.Connection)
        $State.Health     = Get-VMwareHealthReport -Connection $State.Connection `
                                -VMHosts $State.Hosts -Datastores $State.Datastores -VMs $State.VMs
        $State.LastRefresh = Get-Date
        $State.RefreshError = $null
    } catch {
        $State.RefreshError = $_.Exception.Message
        Add-VMwareLogEntry -State $State -Level 'Error' -Message "Refresh failed: $($_.Exception.Message)"
    }
}

function Get-VMwareFilteredVM {
    <#
        .SYNOPSIS
            Applies the active filter to the VM list.
        .NOTES
            Matches name, guest OS and IP so '/win' or '/10.0.0' both work.
    #>
    [CmdletBinding()]
    param($VMs, [string]$Filter)

    if ([string]::IsNullOrWhiteSpace($Filter)) { return @($VMs) }

    $needle = $Filter.Trim()
    return @(@($VMs) | Where-Object {
        $_.Name -like "*$needle*" -or
        $_.GuestOS -like "*$needle*" -or
        $_.IPAddress -like "*$needle*"
    })
}

function Format-VMwareVMView {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$State, [Parameter(Mandatory)][int]$Width, [Parameter(Mandatory)][int]$Rows)

    $c = $script:VMwareColor
    $lines = New-Object System.Collections.Generic.List[string]

    $showHost = [bool]$State.Connection.IsVCenter

    # Fixed columns, with the name column absorbing what is left over. The index
    # column is marker(3) + number(3) + a separating space, so a three-digit row
    # number still cannot run into the name.
    $wMarker = 3; $wNum = 3; $wIdx = $wMarker + $wNum + 1
    $wPower = 7; $wCpu = 6; $wMem = 8; $wIp = 16; $wTools = 7
    $wHost = if ($showHost) { 14 } else { 0 }
    $fixed = $wIdx + $wPower + $wCpu + $wMem + $wIp + $wTools + $wHost
    $wName = $Width - $fixed - 2
    if ($wName -lt 12) { $wName = 12 }
    if ($wName -gt 44) { $wName = 44 }   # keep names from sprawling on a wide terminal

    $header = (Format-VMwareCell '' $wMarker) + (Format-VMwareCell '#' $wNum -Align Right) + ' ' +
              (Format-VMwareCell 'NAME' $wName) +
              (Format-VMwareCell 'POWER' $wPower) +
              (Format-VMwareCell 'vCPU' $wCpu -Align Right) +
              (Format-VMwareCell 'MEM GB' $wMem -Align Right) +
              (Format-VMwareCell '  IP ADDRESS' $wIp) +
              (Format-VMwareCell ' TOOLS' $wTools)
    if ($showHost) { $header += (Format-VMwareCell ' HOST' $wHost) }
    $lines.Add($c.Bold + $c.Cyan + (Format-VMwareCell $header $Width) + $c.Reset)

    $vms = $State.FilteredVMs
    if ($vms.Count -eq 0) {
        $empty = if ($State.Filter) { "  No VMs match filter '$($State.Filter)'." } else { '  No virtual machines found.' }
        $lines.Add($c.Grey + $empty + $c.Reset)
        return $lines
    }

    $window = Get-VMwareViewportWindow -ItemCount $vms.Count -SelectedIndex $State.SelectedIndex -Height $Rows

    for ($i = $window.StartIndex; $i -lt ($window.StartIndex + $window.Count) -and $i -lt $vms.Count; $i++) {
        $vm = $vms[$i]
        $selected = ($i -eq $State.SelectedIndex)
        $power = Get-VMwarePowerGlyph -PowerState $vm.PowerState -Ascii:$State.Ascii

        $marker = if ($selected) { ' > ' } else { '   ' }
        $toolsText = if (Test-VMwareToolsReady -ToolsStatus $vm.ToolsStatus -ToolsRunningStatus $vm.ToolsRunning) { 'ok' } else { '-' }

        $row = (Format-VMwareCell $marker $wMarker) + (Format-VMwareCell ([string]($i + 1)) $wNum -Align Right) + ' ' +
               (Format-VMwareCell $vm.Name $wName) +
               (Format-VMwareCell ("{0} {1}" -f $power.Glyph, $power.Text) $wPower) +
               (Format-VMwareCell $vm.NumCpu $wCpu -Align Right) +
               (Format-VMwareCell $vm.MemoryGB $wMem -Align Right) +
               (Format-VMwareCell ("  " + $vm.IPAddress) $wIp) +
               (Format-VMwareCell ("  " + $toolsText) $wTools)
        if ($showHost) { $row += (Format-VMwareCell (" " + $vm.HostName) $wHost) }

        $row = Format-VMwareCell $row $Width

        if ($selected) {
            $lines.Add($c.Reverse + $row + $c.Reset)
        } else {
            $lines.Add($power.Color + $row + $c.Reset)
        }
    }

    return $lines
}

function Format-VMwareHealthView {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$State, [Parameter(Mandatory)][int]$Width, [Parameter(Mandatory)][int]$Rows)

    $c = $script:VMwareColor
    $lines = New-Object System.Collections.Generic.List[string]
    $report = $State.Health

    if (-not $report) {
        $lines.Add($c.Grey + '  Health data not available yet.' + $c.Reset)
        return $lines
    }

    $verdictColor = Get-VMwareSeverityColor -Severity $report.Verdict
    $lines.Add($c.Bold + '  OVERALL: ' + $verdictColor + $report.Verdict.ToUpper() + $c.Reset +
               $c.Grey + ("   {0} host(s), {1} VM(s) - {2} on / {3} off, {4} datastore(s)" -f
                          $report.HostCount, $report.VMCount, $report.VMPoweredOn, $report.VMPoweredOff, $report.DatastoreCount) + $c.Reset)
    $lines.Add('')

    foreach ($h in $report.Hosts) {
        $statusColor = switch ($h.OverallStatus) {
            'green'  { $c.Green }
            'yellow' { $c.Yellow }
            'red'    { $c.Red }
            default  { $c.Grey }
        }
        $lines.Add($c.Bold + '  ' + (Format-VMwareCell $h.Name 28) + $c.Reset +
                   $statusColor + (Format-VMwareCell $h.OverallStatus 8) + $c.Reset +
                   $c.Grey + (Format-VMwareCell ("up {0}" -f $h.UptimeText) 12) + $c.Reset +
                   (Format-VMwareCell $h.Product 34))

        $cpuBar = New-VMwareBar -Percent $h.CpuPercent -Width 20
        $memBar = New-VMwareBar -Percent $h.MemoryPercent -Width 20
        $cpuColor = Get-VMwareSeverityColor -Severity (Get-VMwareUsageSeverity -Percent $h.CpuPercent -WarningAt 75 -CriticalAt 90)
        $memColor = Get-VMwareSeverityColor -Severity (Get-VMwareUsageSeverity -Percent $h.MemoryPercent -WarningAt 85 -CriticalAt 95)

        $lines.Add('      CPU ' + $cpuColor + "[$cpuBar] " + (Format-VMwareCell ("{0}%" -f $h.CpuPercent) 5 -Align Right) + $c.Reset +
                   $c.Grey + ("  {0} / {1} MHz  ({2} cores)" -f $h.CpuUsedMhz, $h.CpuTotalMhz, $h.CpuCores) + $c.Reset)
        $lines.Add('      MEM ' + $memColor + "[$memBar] " + (Format-VMwareCell ("{0}%" -f $h.MemoryPercent) 5 -Align Right) + $c.Reset +
                   $c.Grey + ("  {0} / {1} MB" -f $h.MemoryUsedMB, $h.MemoryTotalMB) + $c.Reset)
        $lines.Add('')
    }

    if ($report.Findings.Count -eq 0) {
        $lines.Add($c.Green + '  No issues detected.' + $c.Reset)
    } else {
        $lines.Add($c.Bold + '  FINDINGS' + $c.Reset)
        foreach ($f in ($report.Findings | Sort-Object { switch ($_.Severity) { 'Critical' { 0 } 'Warning' { 1 } default { 2 } } })) {
            $col = Get-VMwareSeverityColor -Severity $f.Severity
            $lines.Add('  ' + $col + (Format-VMwareCell $f.Severity 10) + $c.Reset +
                       (Format-VMwareCell $f.Subject 24) + $f.Message)
        }
    }

    return $lines
}

function Format-VMwareDatastoreView {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$State, [Parameter(Mandatory)][int]$Width, [Parameter(Mandatory)][int]$Rows)

    $c = $script:VMwareColor
    $lines = New-Object System.Collections.Generic.List[string]

    $lines.Add($c.Bold + $c.Cyan + (Format-VMwareCell ('  ' + (Format-VMwareCell 'NAME' 30) + (Format-VMwareCell 'TYPE' 10) +
               (Format-VMwareCell 'USED' 26) + (Format-VMwareCell 'FREE GB' 12 -Align Right) +
               (Format-VMwareCell 'CAPACITY GB' 14 -Align Right)) $Width) + $c.Reset)

    foreach ($ds in @($State.Datastores)) {
        $sev = Get-VMwareUsageSeverity -Percent $ds.UsedPercent -WarningAt 85 -CriticalAt 95
        $col = Get-VMwareSeverityColor -Severity $sev
        $bar = New-VMwareBar -Percent $ds.UsedPercent -Width 16

        $lines.Add('  ' + (Format-VMwareCell $ds.Name 30) +
                   (Format-VMwareCell $ds.Type 10) +
                   $col + (Format-VMwareCell ("[$bar] {0}%" -f $ds.UsedPercent) 26) + $c.Reset +
                   (Format-VMwareCell $ds.FreeGB 12 -Align Right) +
                   (Format-VMwareCell $ds.CapacityGB 14 -Align Right))
    }

    if (@($State.Datastores).Count -eq 0) { $lines.Add($c.Grey + '  No datastores found.' + $c.Reset) }
    return $lines
}

function Format-VMwareLogView {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$State, [Parameter(Mandatory)][int]$Width, [Parameter(Mandatory)][int]$Rows)

    $c = $script:VMwareColor
    $lines = New-Object System.Collections.Generic.List[string]

    if ($State.Log.Count -eq 0) {
        $lines.Add($c.Grey + '  Nothing logged yet this session.' + $c.Reset)
        return $lines
    }

    foreach ($entry in ($State.Log | Select-Object -First $Rows)) {
        $col = switch ($entry.Level) {
            'Ok'      { $c.Green }
            'Warning' { $c.Yellow }
            'Error'   { $c.Red }
            default   { $c.White }
        }
        $lines.Add('  ' + $c.Grey + $entry.Time.ToString('HH:mm:ss') + $c.Reset + '  ' +
                   $col + (Format-VMwareCell $entry.Level 9) + $c.Reset + $entry.Message)
    }

    return $lines
}

function Confirm-VMwareAction {
    <#
        .SYNOPSIS
            Draws a one-line confirmation prompt and waits for y/n.
        .DESCRIPTION
            Used for the operations that can lose data. Requires an explicit
            'y'; any other key cancels.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Message, [Parameter(Mandatory)][int]$Row, [Parameter(Mandatory)][int]$Width)

    $c = $script:VMwareColor
    $esc = [char]27

    [Console]::Write("$esc[$($Row);1H")
    [Console]::Write($c.BgRed + $c.White + (Format-VMwareCell ("  $Message  [y/N] ") $Width) + $c.Reset)

    $key = [Console]::ReadKey($true)
    return ($key.KeyChar -eq 'y' -or $key.KeyChar -eq 'Y')
}

function Read-VMwareLine {
    <#
        .SYNOPSIS
            Reads a line of text on the prompt row (used by the filter).
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Prompt, [Parameter(Mandatory)][int]$Row, [Parameter(Mandatory)][int]$Width)

    $c = $script:VMwareColor
    $esc = [char]27

    [Console]::Write("$esc[$($Row);1H")
    [Console]::Write($c.BgBlue + $c.White + (Format-VMwareCell ("  $Prompt") $Width) + $c.Reset)
    [Console]::Write("$esc[$($Row);$($Prompt.Length + 4)H")
    [Console]::Write("$esc[?25h")   # show cursor while typing

    $text = [Console]::ReadLine()

    [Console]::Write("$esc[?25l")
    return $text
}

function Invoke-VMwareConsoleAction {
    <#
        .SYNOPSIS
            Runs one power action from the TUI and records the outcome.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$State,
        [Parameter(Mandatory)]$VM,
        [Parameter(Mandatory)][string]$Action
    )

    try {
        # -Confirm:$false because the TUI has already asked where it matters.
        $result = Invoke-VMwareVMPower -Connection $State.Connection -VM $VM -Action $Action -Confirm:$false -ErrorAction Stop

        if ($result.Success) {
            Add-VMwareLogEntry -State $State -Level 'Ok' -Message "$Action requested on '$($VM.Name)' ($($result.State))."
            $State.Status = "$Action sent to $($VM.Name)."
            $State.StatusLevel = 'Ok'
        } else {
            $message = if ($result.Error) { $result.Error } else { 'refused' }
            Add-VMwareLogEntry -State $State -Level 'Error' -Message "$Action on '$($VM.Name)' failed: $message"
            $State.Status = "$Action failed: $message"
            $State.StatusLevel = 'Error'
        }
    } catch {
        Add-VMwareLogEntry -State $State -Level 'Error' -Message "$Action on '$($VM.Name)' failed: $($_.Exception.Message)"
        $State.Status = $_.Exception.Message
        $State.StatusLevel = 'Error'
    }

    # Power state lags the request slightly; a short pause makes the refresh useful.
    Start-Sleep -Milliseconds 700
    Update-VMwareConsoleData -State $State
}

function Show-VMwareConsole {
    <#
        .SYNOPSIS
            Launches the full-screen management console.

        .DESCRIPTION
            Keys:
              Up/Down/PgUp/PgDn/Home/End  move            1  VMs
              O  power on                                 2  health
              S  shut down guest (graceful)               3  datastores
              R  restart guest (graceful)                 4  activity log
              P  force power off (confirm)                /  filter
              E  hard reset (confirm)                     F5 refresh
              U  suspend                                  Q  quit

        .PARAMETER RefreshSeconds
            How often to poll the server. 0 disables automatic refresh.

        .PARAMETER Ascii
            Use ASCII instead of Unicode box drawing, for legacy consoles.

        .EXAMPLE
            Show-VMwareConsole -Connection $c
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Connection,
        [int]$RefreshSeconds = 20,
        [switch]$Ascii
    )

    if ([Console]::IsInputRedirected) {
        throw 'Show-VMwareConsole needs an interactive console; input is currently redirected.'
    }

    $null = Enable-VMwareVirtualTerminal
    $esc = [char]27
    $c = $script:VMwareColor

    $previousEncoding = [Console]::OutputEncoding
    if (-not $Ascii) {
        try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }
    }

    $state = @{
        Connection   = $Connection
        View         = 'VMs'
        SelectedIndex = 0
        Filter       = ''
        VMs          = @()
        FilteredVMs  = @()
        Hosts        = @()
        Datastores   = @()
        Health       = $null
        Log          = New-Object System.Collections.Generic.List[object]
        LastRefresh  = $null
        RefreshError = $null
        Status       = 'Connected.'
        StatusLevel  = 'Info'
        Ascii        = [bool]$Ascii
    }

    Add-VMwareLogEntry -State $state -Level 'Ok' `
        -Message "Connected to $($Connection.Server) as $($Connection.User) ($($Connection.ProductName))."

    [Console]::Write("$esc[?1049h")   # alternate screen buffer
    [Console]::Write("$esc[?25l")     # hide cursor

    try {
        Update-VMwareConsoleData -State $state
        $running = $true

        while ($running) {
            $width  = [Math]::Max([Console]::WindowWidth, 80)
            $height = [Math]::Max([Console]::WindowHeight, 20)
            $box = Get-VMwareBoxChars -Ascii:$Ascii

            $state.FilteredVMs = Get-VMwareFilteredVM -VMs $state.VMs -Filter $state.Filter
            if ($state.SelectedIndex -ge $state.FilteredVMs.Count) { $state.SelectedIndex = [Math]::Max(0, $state.FilteredVMs.Count - 1) }

            $lines = New-Object System.Collections.Generic.List[string]

            # --- header ---------------------------------------------------
            $kind = if ($Connection.IsVCenter) { 'vCenter' } else { 'ESXi host' }
            $title = " VMware Console  $($box.Vertical)  $($Connection.Server)  $($box.Vertical)  $kind $($Connection.Version) "
            $lines.Add($c.Bold + $c.Cyan + (Format-VMwareCell $title $width) + $c.Reset)

            $refreshText = if ($state.LastRefresh) { $state.LastRefresh.ToString('HH:mm:ss') } else { 'never' }
            $verdict = if ($state.Health) { $state.Health.Verdict } else { 'unknown' }
            $verdictColor = Get-VMwareSeverityColor -Severity $verdict
            $sub = " user $($Connection.User)   $($box.Vertical)  health " 
            $lines.Add($c.Grey + $sub + $c.Reset + $verdictColor + $verdict.ToUpper() + $c.Reset +
                       $c.Grey + "   $($box.Vertical)  refreshed $refreshText   $($box.Vertical)  $($state.VMs.Count) VMs" + $c.Reset)

            $lines.Add($c.Grey + ([string]$box.Horizontal * $width) + $c.Reset)

            # --- tabs -----------------------------------------------------
            $tabs = @('1 VMs', '2 Health', '3 Datastores', '4 Log')
            $tabNames = @('VMs', 'Health', 'Datastores', 'Log')
            $tabLine = ' '
            for ($t = 0; $t -lt $tabs.Count; $t++) {
                if ($state.View -eq $tabNames[$t]) { $tabLine += $c.Reverse + " $($tabs[$t]) " + $c.Reset + ' ' }
                else { $tabLine += $c.Grey + " $($tabs[$t]) " + $c.Reset + ' ' }
            }
            if ($state.Filter) { $tabLine += $c.Yellow + "  filter: '$($state.Filter)'" + $c.Reset }
            $lines.Add($tabLine)
            $lines.Add($c.Grey + ([string]$box.Horizontal * $width) + $c.Reset)

            # Body height = total - header(4) - separator - detail(2) - status(1) - footer(2)
            $chromeRows = 11
            $bodyRows = $height - $chromeRows
            if ($bodyRows -lt 3) { $bodyRows = 3 }

            switch ($state.View) {
                'VMs'        { foreach ($l in (Format-VMwareVMView       -State $state -Width $width -Rows $bodyRows)) { $lines.Add($l) } }
                'Health'     { foreach ($l in (Format-VMwareHealthView    -State $state -Width $width -Rows $bodyRows)) { $lines.Add($l) } }
                'Datastores' { foreach ($l in (Format-VMwareDatastoreView -State $state -Width $width -Rows $bodyRows)) { $lines.Add($l) } }
                'Log'        { foreach ($l in (Format-VMwareLogView       -State $state -Width $width -Rows $bodyRows)) { $lines.Add($l) } }
            }

            while ($lines.Count -lt ($height - 5)) { $lines.Add('') }

            # --- detail panel --------------------------------------------
            $lines.Add($c.Grey + ([string]$box.Horizontal * $width) + $c.Reset)
            if ($state.View -eq 'VMs' -and $state.FilteredVMs.Count -gt 0) {
                $sel = $state.FilteredVMs[$state.SelectedIndex]
                $detail = " $($sel.Name)  $($box.Vertical)  $($sel.GuestOS)  $($box.Vertical)  $($sel.NumCpu) vCPU / $($sel.MemoryGB) GB"
                if ($sel.GuestHostName) { $detail += "  $($box.Vertical)  $($sel.GuestHostName)" }
                if ($sel.HostName)      { $detail += "  $($box.Vertical)  on $($sel.HostName)" }
                $detail += "  $($box.Vertical)  tools: $($sel.ToolsStatus)"
                $lines.Add($c.White + (Format-VMwareCell $detail $width) + $c.Reset)
            } else {
                $lines.Add('')
            }

            # --- status ---------------------------------------------------
            $statusColor = switch ($state.StatusLevel) {
                'Ok'      { $c.Green }
                'Warning' { $c.Yellow }
                'Error'   { $c.Red }
                default   { $c.Grey }
            }
            $statusText = if ($state.RefreshError) { "REFRESH ERROR: $($state.RefreshError)" } else { $state.Status }
            $statusColor = if ($state.RefreshError) { $c.Red } else { $statusColor }
            $lines.Add($statusColor + (Format-VMwareCell (" $statusText") $width) + $c.Reset)

            # --- footer ---------------------------------------------------
            $lines.Add($c.Grey + ([string]$box.Horizontal * $width) + $c.Reset)
            $keys = if ($state.View -eq 'VMs') {
                ' O on  S shutdown  R restart  P power-off  E reset  U suspend  / filter  F5 refresh  Q quit'
            } else {
                ' 1 VMs  2 Health  3 Datastores  4 Log  F5 refresh  Q quit'
            }
            $lines.Add($c.Cyan + (Format-VMwareCell $keys $width) + $c.Reset)

            Write-VMwareScreen -Lines $lines.ToArray() -Height $height

            # --- input ----------------------------------------------------
            $timeout = if ($RefreshSeconds -gt 0) { 1000 } else { 3000 }
            $key = Read-VMwareKeyWithTimeout -TimeoutMs $timeout

            if ($null -eq $key) {
                if ($RefreshSeconds -gt 0 -and $state.LastRefresh -and
                    ((Get-Date) - $state.LastRefresh).TotalSeconds -ge $RefreshSeconds) {
                    Update-VMwareConsoleData -State $state
                }
                continue
            }

            $selectedVM = if ($state.View -eq 'VMs' -and $state.FilteredVMs.Count -gt 0) { $state.FilteredVMs[$state.SelectedIndex] } else { $null }
            $promptRow = $height - 1

            switch ($key.Key) {
                'UpArrow'    { if ($state.SelectedIndex -gt 0) { $state.SelectedIndex-- }; continue }
                'DownArrow'  { if ($state.SelectedIndex -lt ($state.FilteredVMs.Count - 1)) { $state.SelectedIndex++ }; continue }
                'Home'       { $state.SelectedIndex = 0; continue }
                'End'        { $state.SelectedIndex = [Math]::Max(0, $state.FilteredVMs.Count - 1); continue }
                'PageUp'     { $state.SelectedIndex = [Math]::Max(0, $state.SelectedIndex - $bodyRows); continue }
                'PageDown'   { $state.SelectedIndex = [Math]::Min([Math]::Max(0, $state.FilteredVMs.Count - 1), $state.SelectedIndex + $bodyRows); continue }
                'F5'         { $state.Status = 'Refreshing...'; Update-VMwareConsoleData -State $state; continue }
                'Escape'     { if ($state.Filter) { $state.Filter = ''; $state.SelectedIndex = 0 }; continue }
            }

            switch -CaseSensitive ($key.KeyChar) {
                '1' { $state.View = 'VMs';        continue }
                '2' { $state.View = 'Health';     continue }
                '3' { $state.View = 'Datastores'; continue }
                '4' { $state.View = 'Log';        continue }
                '/' {
                    $entered = Read-VMwareLine -Prompt 'Filter (name / OS / IP), blank to clear:' -Row $promptRow -Width $width
                    $state.Filter = if ($null -eq $entered) { '' } else { $entered.Trim() }
                    $state.SelectedIndex = 0
                    continue
                }
            }

            $char = [char]::ToLowerInvariant($key.KeyChar)

            if ($char -eq 'q') { $running = $false; continue }

            if ($state.View -ne 'VMs' -or -not $selectedVM) { continue }

            switch ($char) {
                'o' { Invoke-VMwareConsoleAction -State $state -VM $selectedVM -Action 'On' }
                's' { Invoke-VMwareConsoleAction -State $state -VM $selectedVM -Action 'Shutdown' }
                'r' { Invoke-VMwareConsoleAction -State $state -VM $selectedVM -Action 'Restart' }
                'u' { Invoke-VMwareConsoleAction -State $state -VM $selectedVM -Action 'Suspend' }
                'p' {
                    if (Confirm-VMwareAction -Message "FORCE POWER OFF '$($selectedVM.Name)'? Unsaved data in the guest will be lost." -Row $promptRow -Width $width) {
                        Invoke-VMwareConsoleAction -State $state -VM $selectedVM -Action 'Off'
                    } else { $state.Status = 'Cancelled.'; $state.StatusLevel = 'Info' }
                }
                'e' {
                    if (Confirm-VMwareAction -Message "HARD RESET '$($selectedVM.Name)'? This is equivalent to the reset button." -Row $promptRow -Width $width) {
                        Invoke-VMwareConsoleAction -State $state -VM $selectedVM -Action 'Reset'
                    } else { $state.Status = 'Cancelled.'; $state.StatusLevel = 'Info' }
                }
            }
        }
    } finally {
        [Console]::Write("$esc[?25h")     # show cursor
        [Console]::Write("$esc[?1049l")   # restore the original screen
        try { [Console]::OutputEncoding = $previousEncoding } catch { }
    }
}
