function Connect-VMwareServer {
    <#
        .SYNOPSIS
            Connects to a vCenter Server or a standalone ESXi host by name or IP.

        .DESCRIPTION
            Authenticates against the vSphere Web Services (SOAP) endpoint, which
            both vCenter and ESXi expose, and reports which of the two answered.
            No PowerCLI installation is required.

        .PARAMETER Server
            Hostname or IP address, e.g. 192.168.1.50 or vcenter.lab.local.

        .PARAMETER Credential
            Credentials to log in with. Prompted for if omitted.
            ESXi usually wants 'root'; vCenter wants something like
            'administrator@vsphere.local'.

        .PARAMETER SkipCertificateCheck
            Accept the certificate without validating it. Convenient on a lab
            host, but prefer -CertificateThumbprint once you know the value:
            the warning this prints tells you the thumbprint to pin.

        .PARAMETER CertificateThumbprint
            Only connect if the host presents this exact certificate. Safe way
            to work with the self-signed certificates vSphere ships by default.

        .EXAMPLE
            $c = Connect-VMwareServer -Server 192.168.1.50 -SkipCertificateCheck

        .EXAMPLE
            $c = Connect-VMwareServer -Server esxi01.lab -CertificateThumbprint A1B2C3...
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Server,

        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        [ValidateRange(1, 65535)]
        [int]$Port = 443,

        [switch]$SkipCertificateCheck,

        [string]$CertificateThumbprint,

        [int]$TimeoutSec = 60
    )

    # Accept a pasted URL as well as a bare host/IP.
    $Server = $Server.Trim() -replace '^https?://', '' -replace '/.*$', ''
    if ($Server -match '^(.*):(\d+)$') {
        $Server = $Matches[1]
        $Port   = [int]$Matches[2]
    }

    if (-not $Credential) {
        $Credential = Get-Credential -Message "Sign in to $Server (ESXi: root - vCenter: administrator@vsphere.local)"
    }
    if (-not $Credential) { throw 'A credential is required to connect.' }

    Enable-VMwareTls

    $certInfo = Assert-VMwareCertificateTrust -Server $Server -Port $Port `
        -CertificateThumbprint $CertificateThumbprint -SkipCertificateCheck:$SkipCertificateCheck

    $connection = [pscustomobject]@{
        Server               = $Server
        Port                 = $Port
        SdkUri               = "https://${Server}:${Port}/sdk"
        BaseUri              = "https://${Server}:${Port}"
        WebSession           = New-VMwareWebSession
        SkipCertificateCheck = [bool]$SkipCertificateCheck
        Certificate          = $certInfo
        ServiceContent       = $null
        Session              = $null
        User                 = $Credential.UserName
        IsVCenter            = $false
        ProductName          = $null
        Version              = $null
        Build                = $null
        ApiType              = $null
        ConnectedAt          = $null
        TimeoutSec           = $TimeoutSec
    }

    try {
        $connection.ServiceContent = Get-VMwareServiceContent -Connection $connection
    } catch {
        throw "Could not reach the vSphere API at $($connection.SdkUri). $($_.Exception.Message)"
    }

    $connection.ApiType     = $connection.ServiceContent.ApiType
    $connection.ProductName = $connection.ServiceContent.ProductName
    $connection.Version     = $connection.ServiceContent.Version
    $connection.Build       = $connection.ServiceContent.Build
    $connection.IsVCenter   = ($connection.ServiceContent.ApiType -eq 'VirtualCenter')

    $session = Invoke-VMwareSoapLogin -Connection $connection `
        -SessionManager $connection.ServiceContent.SessionManager `
        -Username $Credential.UserName -Password $Credential.Password

    $connection.Session     = $session
    $connection.ConnectedAt = Get-Date

    Write-Verbose ("Connected to {0} ({1}) as {2}" -f $connection.Server, $connection.ProductName, $session.UserName)
    return $connection
}

function Disconnect-VMwareServer {
    <#
        .SYNOPSIS
            Logs the session out and undoes any global certificate bypass.
        .DESCRIPTION
            Worth calling: vCenter caps concurrent sessions per user, and
            abandoned sessions linger until they idle out.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]$Connection
    )

    process {
        if (-not $Connection) { return }

        if ($Connection.ServiceContent -and $Connection.Session) {
            try {
                Invoke-VMwareSoapLogout -Connection $Connection -SessionManager $Connection.ServiceContent.SessionManager
            } catch {
                Write-Verbose "Logout failed (session may already be gone): $($_.Exception.Message)"
            }
        }

        $Connection.Session = $null
        Disable-VMwareCertificateBypass
    }
}

function Test-VMwareConnection {
    <#
        .SYNOPSIS
            Returns $true when the connection still has a usable session.
        .DESCRIPTION
            The TUI uses this to tell "the host is busy" apart from
            "our session expired", which need different responses.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Connection)

    if (-not $Connection -or -not $Connection.Session) { return $false }

    try {
        $body = @"
    <RetrievePropertiesEx>
      <_this type="PropertyCollector">$(ConvertTo-VMwareXmlText $Connection.ServiceContent.PropertyCollector)</_this>
      <specSet>
        <propSet><type>SessionManager</type><all>false</all><pathSet>currentSession</pathSet></propSet>
        <objectSet><obj type="SessionManager">$(ConvertTo-VMwareXmlText $Connection.ServiceContent.SessionManager)</obj><skip>false</skip></objectSet>
      </specSet>
      <options/>
    </RetrievePropertiesEx>
"@
        $null = Invoke-VMwareSoap -Connection $Connection -Body $body -TimeoutSec 15
        return $true
    } catch {
        return $false
    }
}
