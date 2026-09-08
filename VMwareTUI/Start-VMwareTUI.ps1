<#
    .SYNOPSIS
        Connects to a vCenter or ESXi host and opens the management console.

    .DESCRIPTION
        Entry point for everyday use. Prompts for the address and credentials
        when they are not supplied.

    .PARAMETER Server
        Hostname or IP of the vCenter Server or ESXi host.

    .PARAMETER SkipCertificateCheck
        Accept a self-signed certificate. The connection warning prints the
        thumbprint so you can switch to -CertificateThumbprint afterwards.

    .EXAMPLE
        .\Start-VMwareTUI.ps1
        Prompts for everything.

    .EXAMPLE
        .\Start-VMwareTUI.ps1 -Server 192.168.1.50 -SkipCertificateCheck

    .EXAMPLE
        .\Start-VMwareTUI.ps1 -Server esxi01.lab -CertificateThumbprint AABBCC...
#>
[CmdletBinding()]
param(
    [string]$Server,

    [System.Management.Automation.PSCredential]
    [System.Management.Automation.Credential()]
    $Credential,

    [int]$Port = 443,
    [switch]$SkipCertificateCheck,
    [string]$CertificateThumbprint,
    [int]$RefreshSeconds = 20,
    [switch]$Ascii
)

$ErrorActionPreference = 'Stop'

$modulePath = Join-Path -Path $PSScriptRoot -ChildPath 'VMwareTUI.psd1'
if (-not (Test-Path -LiteralPath $modulePath)) {
    throw "Cannot find VMwareTUI.psd1 next to this script (looked in $PSScriptRoot)."
}

Import-Module $modulePath -Force

if (-not $Server) {
    $Server = Read-Host 'vCenter or ESXi address (hostname or IP)'
}
if ([string]::IsNullOrWhiteSpace($Server)) { throw 'No server address supplied.' }

Write-Host "Connecting to $Server ..." -ForegroundColor Cyan

$connectParams = @{
    Server = $Server
    Port   = $Port
}
if ($Credential)            { $connectParams['Credential'] = $Credential }
if ($SkipCertificateCheck)  { $connectParams['SkipCertificateCheck'] = $true }
if ($CertificateThumbprint) { $connectParams['CertificateThumbprint'] = $CertificateThumbprint }

$connection = $null
try {
    $connection = Connect-VMwareServer @connectParams

    $kind = if ($connection.IsVCenter) { 'vCenter Server' } else { 'ESXi host' }
    Write-Host "Connected to $kind $($connection.ProductName)" -ForegroundColor Green

    Show-VMwareConsole -Connection $connection -RefreshSeconds $RefreshSeconds -Ascii:$Ascii
} finally {
    if ($connection) {
        Disconnect-VMwareServer -Connection $connection
        Write-Host 'Disconnected.' -ForegroundColor Cyan
    }
}
