# Minimal test harness.
#
# Deliberately dependency-free: this module is meant to run on locked-down
# Windows servers where installing Pester from the gallery is often blocked,
# so the tests must run with nothing but stock PowerShell.

$script:TestState = [pscustomobject]@{
    Passed   = 0
    Failed   = 0
    Failures = (New-Object System.Collections.Generic.List[string])
    Context  = ''
}

function Describe {
    param([Parameter(Mandatory)][string]$Name, [Parameter(Mandatory)][scriptblock]$Body)

    $script:TestState.Context = $Name
    Write-Host ''
    Write-Host "  $Name" -ForegroundColor Cyan
    & $Body
}

function It {
    param([Parameter(Mandatory)][string]$Name, [Parameter(Mandatory)][scriptblock]$Body)

    try {
        & $Body
        $script:TestState.Passed++
        Write-Host "    [pass] $Name" -ForegroundColor Green
    } catch {
        $script:TestState.Failed++
        $message = "$($script:TestState.Context) -> $Name : $($_.Exception.Message)"
        $script:TestState.Failures.Add($message)
        Write-Host "    [FAIL] $Name" -ForegroundColor Red
        Write-Host "           $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Assert-Equal {
    param($Expected, $Actual, [string]$Because = '')

    $e = if ($null -eq $Expected) { '<null>' } else { [string]$Expected }
    $a = if ($null -eq $Actual)   { '<null>' } else { [string]$Actual }

    if ($e -ne $a) {
        throw "Expected '$e' but got '$a'. $Because"
    }
}

function Assert-True {
    param($Condition, [string]$Because = '')
    if (-not $Condition) { throw "Expected true but got false. $Because" }
}

function Assert-False {
    param($Condition, [string]$Because = '')
    if ($Condition) { throw "Expected false but got true. $Because" }
}

function Assert-Throws {
    param([Parameter(Mandatory)][scriptblock]$Body, [string]$MatchText, [string]$Because = '')

    $threw = $false
    $message = ''
    try { & $Body } catch { $threw = $true; $message = $_.Exception.Message }

    if (-not $threw) { throw "Expected an exception but none was thrown. $Because" }
    if ($MatchText -and $message -notlike "*$MatchText*") {
        throw "Expected exception matching '$MatchText' but got '$message'. $Because"
    }
}

function Get-TestSummary { return $script:TestState }
