# Transport primitives shared by the SOAP and REST clients.
#
# vCenter and ESXi almost always present a self-signed certificate, so the
# module has to give the operator a way through that without silently turning
# off validation everywhere. Three modes are supported:
#
#   default                  - normal chain validation
#   -CertificateThumbprint   - pin one certificate (trust on first use)
#   -SkipCertificateCheck    - accept anything, with a visible warning
#
# Windows PowerShell 5.1 and PowerShell 7 disagree about how to bypass
# validation (5.1 uses the global ServicePointManager callback, 7 uses the
# per-call -SkipCertificateCheck switch), so that difference is contained here.

$script:VMwareCertCallbackInstalled = $false
$script:VMwareOriginalCertCallback  = $null

function Test-VMwareCoreEdition {
    # $PSEdition is 'Core' on PowerShell 6+, 'Desktop' on Windows PowerShell 5.1.
    return ($PSVersionTable.PSEdition -eq 'Core')
}

function Enable-VMwareTls {
    <#
        .SYNOPSIS
            Makes sure TLS 1.2/1.3 are enabled. Windows PowerShell 5.1 still
            defaults to SSL3/TLS1.0 on older hosts, which vCenter refuses.
    #>
    [CmdletBinding()]
    param()

    if (Test-VMwareCoreEdition) { return }  # .NET Core negotiates modern TLS itself.

    $desired = 0
    foreach ($name in @('Tls12', 'Tls13')) {
        try { $desired = $desired -bor [System.Net.SecurityProtocolType]::$name } catch { }
    }
    if ($desired -ne 0) {
        try {
            [System.Net.ServicePointManager]::SecurityProtocol =
                [System.Net.ServicePointManager]::SecurityProtocol -bor $desired
        } catch {
            Write-Verbose "Could not raise SecurityProtocol: $($_.Exception.Message)"
        }
    }
}

function Enable-VMwareCertificateBypass {
    <#
        .SYNOPSIS
            Installs a permissive certificate callback on Windows PowerShell 5.1.
        .NOTES
            This is process-global, which is exactly why Disable-VMwareCertificateBypass
            exists and why Disconnect-VMwareServer calls it.
    #>
    [CmdletBinding()]
    param()

    if (Test-VMwareCoreEdition) { return }
    if ($script:VMwareCertCallbackInstalled) { return }

    $script:VMwareOriginalCertCallback = [System.Net.ServicePointManager]::ServerCertificateValidationCallback
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { param($s, $c, $ch, $e) return $true }
    $script:VMwareCertCallbackInstalled = $true
}

function Disable-VMwareCertificateBypass {
    <#
        .SYNOPSIS
            Restores whatever certificate callback was in place before we meddled.
    #>
    [CmdletBinding()]
    param()

    if (-not $script:VMwareCertCallbackInstalled) { return }

    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = $script:VMwareOriginalCertCallback
    $script:VMwareOriginalCertCallback  = $null
    $script:VMwareCertCallbackInstalled = $false
}

function Get-VMwareServerCertificate {
    <#
        .SYNOPSIS
            Retrieves the TLS certificate a host presents, without validating it.
        .DESCRIPTION
            Used for thumbprint pinning and so the TUI can show the operator what
            they are about to trust. Deliberately independent of the HTTP stack so
            it behaves identically on 5.1 and 7.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ComputerName,
        [int]$Port = 443,
        [int]$TimeoutMs = 10000
    )

    $client = New-Object System.Net.Sockets.TcpClient
    try {
        $async = $client.BeginConnect($ComputerName, $Port, $null, $null)
        if (-not $async.AsyncWaitHandle.WaitOne($TimeoutMs)) {
            throw "Timed out after $([int]($TimeoutMs / 1000))s connecting to ${ComputerName}:${Port}."
        }
        $client.EndConnect($async)

        $acceptAll = { param($sender, $certificate, $chain, $errors) return $true }
        $ssl = New-Object System.Net.Security.SslStream($client.GetStream(), $false, $acceptAll)
        try {
            $ssl.AuthenticateAsClient($ComputerName)
            if (-not $ssl.RemoteCertificate) { throw "$ComputerName presented no TLS certificate." }

            $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($ssl.RemoteCertificate)
            return [pscustomobject]@{
                Subject    = $cert.Subject
                Issuer     = $cert.Issuer
                Thumbprint = $cert.Thumbprint
                NotBefore  = $cert.NotBefore
                NotAfter   = $cert.NotAfter
                IsExpired  = ($cert.NotAfter -lt (Get-Date)) -or ($cert.NotBefore -gt (Get-Date))
                SelfSigned = ($cert.Subject -eq $cert.Issuer)
            }
        } finally {
            $ssl.Dispose()
        }
    } finally {
        $client.Dispose()
    }
}

function Assert-VMwareCertificateTrust {
    <#
        .SYNOPSIS
            Decides whether the certificate on $Server may be used.
        .OUTPUTS
            The certificate info object, so callers can display it.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Server,
        [int]$Port = 443,
        [string]$CertificateThumbprint,
        [switch]$SkipCertificateCheck
    )

    # Only inspect the certificate when we actually need to reason about it.
    if (-not $CertificateThumbprint -and -not $SkipCertificateCheck) { return $null }

    $info = Get-VMwareServerCertificate -ComputerName $Server -Port $Port

    if ($CertificateThumbprint) {
        $expected = ($CertificateThumbprint -replace '[^0-9A-Fa-f]', '')
        if ($info.Thumbprint -ne $expected) {
            throw ("Certificate thumbprint mismatch for {0}. Expected {1} but the host presented {2}. " +
                   "Refusing to connect - this could be a man-in-the-middle, or the host certificate was replaced." -f
                   $Server, $expected, $info.Thumbprint)
        }
    } elseif ($SkipCertificateCheck) {
        Write-Warning ("TLS validation disabled for {0} (thumbprint {1}). " +
                       "Pass -CertificateThumbprint {1} instead to pin this certificate." -f $Server, $info.Thumbprint)
    }

    return $info
}

function New-VMwareWebSession {
    <#
        .SYNOPSIS
            Creates a cookie container. The SOAP API authenticates once and then
            carries a vmware_soap_session cookie, so every later call must reuse it.
    #>
    [CmdletBinding()]
    param()
    return (New-Object Microsoft.PowerShell.Commands.WebRequestSession)
}

function Invoke-VMwareHttp {
    <#
        .SYNOPSIS
            Single choke point for outbound HTTP, so certificate handling and
            timeouts behave the same for SOAP and REST on both PowerShell editions.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Uri,
        [string]$Method = 'GET',
        [hashtable]$Headers,
        $Body,
        [string]$ContentType = 'application/json',
        $WebSession,
        [int]$TimeoutSec = 60,
        [switch]$SkipCertificateCheck,
        [switch]$Raw
    )

    Enable-VMwareTls

    $params = @{
        Uri         = $Uri
        Method      = $Method
        TimeoutSec  = $TimeoutSec
        ErrorAction = 'Stop'
    }
    if ($Headers)     { $params['Headers']     = $Headers }
    if ($ContentType) { $params['ContentType'] = $ContentType }
    if ($WebSession)  { $params['WebSession']  = $WebSession }
    if ($null -ne $Body) { $params['Body'] = $Body }

    # Suppress the IE-engine dependency and progress bar; both bite on Server Core.
    if (-not (Test-VMwareCoreEdition)) {
        $params['UseBasicParsing'] = $true
    }

    if ($SkipCertificateCheck) {
        if (Test-VMwareCoreEdition) {
            $params['SkipCertificateCheck'] = $true
        } else {
            Enable-VMwareCertificateBypass
        }
    }

    $previousProgress = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'
    try {
        if ($Raw) {
            return Invoke-WebRequest @params
        }
        return Invoke-RestMethod @params
    } finally {
        $ProgressPreference = $previousProgress
    }
}
