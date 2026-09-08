# Power operations.
#
# vSphere splits these into two families and the difference matters
# operationally:
#
#   hard   - PowerOffVM_Task / ResetVM_Task act on virtual hardware. Always
#            available, equivalent to yanking the cord or hitting reset.
#   guest  - ShutdownGuest / RebootGuest ask VMware Tools inside the guest to
#            shut down cleanly. Requires Tools to be installed and running,
#            and returns immediately without a task to track.
#
# The TUI defaults to the guest variants and only offers the hard ones behind a
# confirmation, because a hard power-off on a domain controller or a database
# server risks corruption.

$script:VMwarePowerActions = @{
    'On'       = @{ Method = 'PowerOnVM_Task';  Kind = 'task';  NeedsTools = $false; Verb = 'Power on' }
    'Off'      = @{ Method = 'PowerOffVM_Task'; Kind = 'task';  NeedsTools = $false; Verb = 'Force power off' }
    'Reset'    = @{ Method = 'ResetVM_Task';    Kind = 'task';  NeedsTools = $false; Verb = 'Hard reset' }
    'Suspend'  = @{ Method = 'SuspendVM_Task';  Kind = 'task';  NeedsTools = $false; Verb = 'Suspend' }
    'Shutdown' = @{ Method = 'ShutdownGuest';   Kind = 'guest'; NeedsTools = $true;  Verb = 'Shut down guest' }
    'Restart'  = @{ Method = 'RebootGuest';     Kind = 'guest'; NeedsTools = $true;  Verb = 'Restart guest' }
}

function Test-VMwareToolsReady {
    <#
        .SYNOPSIS
            True when VMware Tools can service a guest shutdown/reboot request.
        .NOTES
            Pure function - covered by the unit tests.
    #>
    [CmdletBinding()]
    param(
        [AllowNull()][string]$ToolsStatus,
        [AllowNull()][string]$ToolsRunningStatus
    )

    if ($ToolsRunningStatus -and $ToolsRunningStatus -eq 'guestToolsNotRunning') { return $false }

    # toolsOld still answers shutdown requests; only missing or dead Tools cannot.
    return @('toolsOk', 'toolsOld') -contains $ToolsStatus
}

function Wait-VMwareTask {
    <#
        .SYNOPSIS
            Blocks until a vSphere task finishes.
        .PARAMETER OnProgress
            Optional scriptblock invoked with the percentage, so the TUI can
            animate without this function knowing anything about rendering.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Connection,
        [Parameter(Mandatory)][string]$TaskMoRef,
        [int]$TimeoutSec = 300,
        [int]$PollMs = 1000,
        [scriptblock]$OnProgress
    )

    $deadline = (Get-Date).AddSeconds($TimeoutSec)

    while ((Get-Date) -lt $deadline) {
        $state = Get-VMwareTaskState -Connection $Connection -TaskMoRef $TaskMoRef
        if (-not $state) { throw "Task $TaskMoRef disappeared before it completed." }

        if ($OnProgress) { & $OnProgress $state.Progress }

        switch ($state.State) {
            'success' { return [pscustomobject]@{ Success = $true;  State = 'success'; Error = $null } }
            'error'   {
                $message = $state.Error
                if ([string]::IsNullOrWhiteSpace($message)) { $message = 'The task failed without reporting a reason.' }
                return [pscustomobject]@{ Success = $false; State = 'error'; Error = $message }
            }
        }

        Start-Sleep -Milliseconds $PollMs
    }

    return [pscustomobject]@{
        Success = $false
        State   = 'timeout'
        Error   = "Task did not finish within ${TimeoutSec}s. It may still be running on the server."
    }
}

function Invoke-VMwareVMPower {
    <#
        .SYNOPSIS
            Performs a power operation on a virtual machine.

        .PARAMETER Action
            On, Off, Reset, Suspend, Shutdown or Restart.
            Shutdown and Restart are the graceful, Tools-driven variants;
            Off and Reset act on virtual hardware and can lose data.

        .PARAMETER VM
            A VM object from Get-VMwareVM, or a raw MoRef string.

        .PARAMETER Force
            Allow a guest action to fall back to the hard equivalent when
            VMware Tools is unavailable.

        .EXAMPLE
            Invoke-VMwareVMPower -Connection $c -VM $vm -Action Restart -Wait

        .EXAMPLE
            # Restart every powered-on VM whose name starts with TEST
            Get-VMwareVM -Connection $c -Name 'TEST*' |
                Where-Object PowerState -eq 'poweredOn' |
                ForEach-Object { Invoke-VMwareVMPower -Connection $c -VM $_ -Action Restart }
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory)]$Connection,
        [Parameter(Mandatory, ValueFromPipeline)]$VM,
        [Parameter(Mandatory)]
        [ValidateSet('On', 'Off', 'Reset', 'Suspend', 'Shutdown', 'Restart')]
        [string]$Action,
        [switch]$Wait,
        [switch]$Force,
        [int]$TimeoutSec = 300
    )

    process {
        $spec = $script:VMwarePowerActions[$Action]

        if ($VM -is [string]) {
            $moRef = $VM
            $name  = $VM
            $toolsStatus = $null
            $toolsRunning = $null
            $powerState = $null
        } else {
            $moRef = $VM.MoRef
            $name  = $VM.Name
            $toolsStatus  = $VM.ToolsStatus
            $toolsRunning = $VM.ToolsRunning
            $powerState   = $VM.PowerState
        }

        if (-not $moRef) { throw 'The VM object has no MoRef; pass an object from Get-VMwareVM.' }

        $method = $spec.Method

        # Guest operations need Tools. Rather than let vSphere return an opaque
        # fault, say so plainly - and offer the hard equivalent under -Force.
        if ($spec.NeedsTools -and $null -ne $toolsStatus) {
            if (-not (Test-VMwareToolsReady -ToolsStatus $toolsStatus -ToolsRunningStatus $toolsRunning)) {
                if (-not $Force) {
                    throw ("VMware Tools is not running on '{0}' (status: {1}), so a graceful {2} is not possible. " +
                           "Re-run with -Force to use the hard equivalent instead, or install VMware Tools." -f
                           $name, $toolsStatus, $Action.ToLower())
                }

                $method = if ($Action -eq 'Shutdown') { 'PowerOffVM_Task' } else { 'ResetVM_Task' }
                Write-Warning "VMware Tools unavailable on '$name'; falling back to $method."
                $spec = @{ Method = $method; Kind = 'task'; NeedsTools = $false; Verb = $spec.Verb }
            }
        }

        if ($powerState -and $Action -eq 'On' -and $powerState -eq 'poweredOn') {
            Write-Verbose "'$name' is already powered on."
            return [pscustomobject]@{ VM = $name; Action = $Action; Success = $true; State = 'noop'; Error = $null }
        }

        if (-not $PSCmdlet.ShouldProcess($name, $spec.Verb)) {
            return [pscustomobject]@{ VM = $name; Action = $Action; Success = $false; State = 'skipped'; Error = $null }
        }

        try {
            $taskRef = Invoke-VMwareMethod -Connection $Connection -Method $method -MoRef $moRef -MoType 'VirtualMachine'
        } catch {
            return [pscustomobject]@{ VM = $name; Action = $Action; Success = $false; State = 'error'; Error = $_.Exception.Message }
        }

        # Guest operations complete without a task to follow.
        if ($spec.Kind -eq 'guest' -or -not $taskRef) {
            return [pscustomobject]@{ VM = $name; Action = $Action; Success = $true; State = 'requested'; Error = $null; Task = $null }
        }

        if (-not $Wait) {
            return [pscustomobject]@{ VM = $name; Action = $Action; Success = $true; State = 'running'; Error = $null; Task = $taskRef }
        }

        $result = Wait-VMwareTask -Connection $Connection -TaskMoRef $taskRef -TimeoutSec $TimeoutSec
        return [pscustomobject]@{
            VM      = $name
            Action  = $Action
            Success = $result.Success
            State   = $result.State
            Error   = $result.Error
            Task    = $taskRef
        }
    }
}
