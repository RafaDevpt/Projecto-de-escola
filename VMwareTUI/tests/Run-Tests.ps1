<#
    .SYNOPSIS
        Runs the VMwareTUI unit tests.
    .DESCRIPTION
        Dot-sources the module's source files directly so that internal
        (non-exported) functions can be tested, then executes every *.Tests.ps1
        in this folder. Exits non-zero if anything fails, so it can gate CI.
    .EXAMPLE
        pwsh -File .\tests\Run-Tests.ps1
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$testRoot   = $PSScriptRoot
$moduleRoot = Split-Path -Path $testRoot -Parent

. (Join-Path $testRoot 'TestHarness.ps1')

# Load the implementation. Private first - Public depends on it.
foreach ($folder in @('Private', 'Public')) {
    $path = Join-Path $moduleRoot $folder
    foreach ($file in (Get-ChildItem -Path $path -Filter '*.ps1' -File | Sort-Object Name)) {
        . $file.FullName
    }
}

Write-Host ''
Write-Host 'VMwareTUI test suite' -ForegroundColor White
Write-Host ('=' * 60) -ForegroundColor DarkGray

foreach ($testFile in (Get-ChildItem -Path $testRoot -Filter '*.Tests.ps1' -File | Sort-Object Name)) {
    . $testFile.FullName
}

$summary = Get-TestSummary

Write-Host ''
Write-Host ('=' * 60) -ForegroundColor DarkGray
Write-Host ("Passed: {0}   Failed: {1}" -f $summary.Passed, $summary.Failed) -ForegroundColor $(if ($summary.Failed -gt 0) { 'Red' } else { 'Green' })

if ($summary.Failed -gt 0) {
    Write-Host ''
    Write-Host 'Failures:' -ForegroundColor Red
    foreach ($f in $summary.Failures) { Write-Host "  - $f" -ForegroundColor Red }
    exit 1
}

exit 0
