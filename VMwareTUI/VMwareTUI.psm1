# VMwareTUI - terminal management console for vCenter and ESXi.
#
# Private files hold the transport and rendering primitives; Public files hold
# the cmdlets exposed to the user. Loading order matters: Public code calls
# into Private, so Private is dot-sourced first.

$ErrorActionPreference = 'Stop'

foreach ($folder in @('Private', 'Public')) {
    $path = Join-Path -Path $PSScriptRoot -ChildPath $folder
    if (-not (Test-Path -LiteralPath $path)) { continue }

    foreach ($file in (Get-ChildItem -Path $path -Filter '*.ps1' -File | Sort-Object Name)) {
        try {
            . $file.FullName
        } catch {
            throw "Failed to load $($file.Name): $($_.Exception.Message)"
        }
    }
}

Export-ModuleMember -Function @(
    'Connect-VMwareServer'
    'Disconnect-VMwareServer'
    'Test-VMwareConnection'
    'Get-VMwareVM'
    'Get-VMwareHost'
    'Get-VMwareDatastore'
    'Get-VMwareHealthReport'
    'Invoke-VMwareVMPower'
    'Wait-VMwareTask'
    'Show-VMwareConsole'
    'Get-VMwareServerCertificate'
)
