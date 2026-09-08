# vSphere Web Services (SOAP) client - the /sdk endpoint.
#
# This is the transport that matters most for this module. The modern vSphere
# Automation REST API (/api/vcenter/...) only exists on vCenter; a standalone
# ESXi host does not serve it. The SOAP API, by contrast, is present on both
# vCenter and every ESXi host, so it is the common denominator and the default
# path here. REST is used opportunistically on vCenter where it is cheaper.

function ConvertTo-VMwareXmlText {
    <#
        .SYNOPSIS
            Escapes text for inclusion in an XML element.
        .NOTES
            Matters for passwords: an unescaped '&' in a password produces a
            malformed envelope and a confusing login failure.
    #>
    [CmdletBinding()]
    param([AllowNull()][AllowEmptyString()][string]$Text)

    if ([string]::IsNullOrEmpty($Text)) { return '' }

    return $Text.
        Replace('&', '&amp;').
        Replace('<', '&lt;').
        Replace('>', '&gt;').
        Replace('"', '&quot;').
        Replace("'", '&apos;')
}

function New-VMwareSoapEnvelope {
    <#
        .SYNOPSIS
            Wraps a vim25 request body in a SOAP envelope.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Body)

    return @"
<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <soapenv:Body xmlns="urn:vim25">
$Body
  </soapenv:Body>
</soapenv:Envelope>
"@
}

function Get-VMwareSoapFault {
    <#
        .SYNOPSIS
            Extracts a human-readable message from a SOAP fault, if present.
        .OUTPUTS
            $null when the response is not a fault.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][xml]$Response)

    $fault = $Response.Envelope.Body.Fault
    if (-not $fault) { return $null }

    $message = $fault.faultstring
    if ([string]::IsNullOrWhiteSpace($message)) { $message = 'Unknown SOAP fault.' }

    # detail holds the typed vim25 fault (InvalidLogin, NotAuthenticated, ...)
    $type = $null
    if ($fault.detail -and $fault.detail.ChildNodes.Count -gt 0) {
        $type = $fault.detail.ChildNodes[0].LocalName
    }

    return [pscustomobject]@{
        Message   = $message.Trim()
        FaultType = $type
    }
}

function Invoke-VMwareSoap {
    <#
        .SYNOPSIS
            Posts a vim25 request and returns the parsed XML response.
        .PARAMETER Connection
            Connection object from Connect-VMwareServer. During login the
            connection is still half-built, so only SdkUri, WebSession and
            SkipCertificateCheck are required.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Connection,
        [Parameter(Mandatory)][string]$Body,
        [int]$TimeoutSec = 60
    )

    $envelope = New-VMwareSoapEnvelope -Body $Body

    $headers = @{
        'SOAPAction' = 'urn:vim25/6.0'
        'Accept'     = 'text/xml'
    }

    try {
        $response = Invoke-VMwareHttp -Uri $Connection.SdkUri -Method 'POST' -Headers $headers `
            -Body $envelope -ContentType 'text/xml; charset=utf-8' `
            -WebSession $Connection.WebSession -TimeoutSec $TimeoutSec `
            -SkipCertificateCheck:$Connection.SkipCertificateCheck -Raw
        $text = $response.Content
    } catch {
        # A vim25 fault comes back as HTTP 500 with a SOAP body, which
        # Invoke-WebRequest raises as a terminating error. Recover the body so we
        # can report "Cannot complete login due to an incorrect user name or
        # password" instead of a bare "500 Internal Server Error".
        $text = $null
        $webResponse = $null
        if ($_.Exception.PSObject.Properties.Name -contains 'Response') { $webResponse = $_.Exception.Response }

        if ($webResponse) {
            try {
                if (Test-VMwareCoreEdition) {
                    $text = $_.ErrorDetails.Message
                } else {
                    $stream = $webResponse.GetResponseStream()
                    $reader = New-Object System.IO.StreamReader($stream)
                    try { $text = $reader.ReadToEnd() } finally { $reader.Dispose() }
                }
            } catch { $text = $null }
        }

        if ([string]::IsNullOrWhiteSpace($text)) { throw }
    }

    $xml = $null
    try {
        $xml = [xml]$text
    } catch {
        throw "The server at $($Connection.SdkUri) returned a response that is not valid XML. Is this really a vCenter or ESXi host?"
    }

    $fault = Get-VMwareSoapFault -Response $xml
    if ($fault) {
        $suffix = ''
        if ($fault.FaultType) { $suffix = " [$($fault.FaultType)]" }
        throw "vSphere API error$suffix`: $($fault.Message)"
    }

    return $xml
}

function Get-VMwareServiceContent {
    <#
        .SYNOPSIS
            Retrieves ServiceContent - the entry point of the vim25 API.
        .DESCRIPTION
            Also tells us what we are talking to: about.apiType is
            'VirtualCenter' for vCenter and 'HostAgent' for a standalone ESXi host.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Connection)

    $body = @'
    <RetrieveServiceContent>
      <_this type="ServiceInstance">ServiceInstance</_this>
    </RetrieveServiceContent>
'@

    $xml = Invoke-VMwareSoap -Connection $Connection -Body $body
    $content = $xml.Envelope.Body.RetrieveServiceContentResponse.returnval

    return [pscustomobject]@{
        RootFolder        = $content.rootFolder.InnerText
        PropertyCollector = $content.propertyCollector.InnerText
        ViewManager       = $content.viewManager.InnerText
        SessionManager    = $content.sessionManager.InnerText
        PerfManager       = $(if ($content.perfManager) { $content.perfManager.InnerText } else { $null })
        ApiType           = $content.about.apiType
        ProductName       = $content.about.fullName
        Version           = $content.about.version
        Build             = $content.about.build
        InstanceUuid      = $(if ($content.about.instanceUuid) { $content.about.instanceUuid } else { $null })
    }
}

function Invoke-VMwareSoapLogin {
    <#
        .SYNOPSIS
            Authenticates against SessionManager and leaves the session cookie
            in the connection's WebSession.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Connection,
        [Parameter(Mandatory)][string]$SessionManager,
        [Parameter(Mandatory)][string]$Username,
        [Parameter(Mandatory)][System.Security.SecureString]$Password
    )

    # The plaintext password exists only for the moment it takes to build the
    # envelope, and both copies are cleared in the finally block below.
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
    $plain = $null
    $body = $null
    try {
        $plain = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)

        $body = @"
    <Login>
      <_this type="SessionManager">$(ConvertTo-VMwareXmlText $SessionManager)</_this>
      <userName>$(ConvertTo-VMwareXmlText $Username)</userName>
      <password>$(ConvertTo-VMwareXmlText $plain)</password>
    </Login>
"@

        $xml = Invoke-VMwareSoap -Connection $Connection -Body $body
        $session = $xml.Envelope.Body.LoginResponse.returnval

        return [pscustomobject]@{
            Key           = $session.key
            UserName      = $session.userName
            FullName      = $session.fullName
            LoginTime     = $session.loginTime
        }
    } finally {
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
        # Overwrite the local copies so the password does not linger in memory
        # any longer than necessary.
        $plain = $null
        $body  = $null
        [System.GC]::Collect()
    }
}

function Invoke-VMwareSoapLogout {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Connection,
        [Parameter(Mandatory)][string]$SessionManager
    )

    $body = @"
    <Logout>
      <_this type="SessionManager">$(ConvertTo-VMwareXmlText $SessionManager)</_this>
    </Logout>
"@
    $null = Invoke-VMwareSoap -Connection $Connection -Body $body
}

function New-VMwareContainerView {
    <#
        .SYNOPSIS
            Creates a ContainerView over the inventory, the standard way to
            enumerate every object of one type.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Connection,
        [Parameter(Mandatory)][string]$Type,
        [string]$Container
    )

    if (-not $Container) { $Container = $Connection.ServiceContent.RootFolder }

    $body = @"
    <CreateContainerView>
      <_this type="ViewManager">$(ConvertTo-VMwareXmlText $Connection.ServiceContent.ViewManager)</_this>
      <container type="Folder">$(ConvertTo-VMwareXmlText $Container)</container>
      <type>$(ConvertTo-VMwareXmlText $Type)</type>
      <recursive>true</recursive>
    </CreateContainerView>
"@

    $xml = Invoke-VMwareSoap -Connection $Connection -Body $body
    return $xml.Envelope.Body.CreateContainerViewResponse.returnval.InnerText
}

function Remove-VMwareView {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Connection,
        [Parameter(Mandatory)][string]$ViewId
    )

    $body = @"
    <DestroyView>
      <_this type="ContainerView">$(ConvertTo-VMwareXmlText $ViewId)</_this>
    </DestroyView>
"@
    try { $null = Invoke-VMwareSoap -Connection $Connection -Body $body } catch {
        Write-Verbose "DestroyView failed (harmless, views expire): $($_.Exception.Message)"
    }
}

function ConvertFrom-VMwarePropSet {
    <#
        .SYNOPSIS
            Flattens one <objects> element from a RetrievePropertiesEx response
            into a hashtable of property path -> value.
        .DESCRIPTION
            Kept free of any network dependency so it can be unit tested against
            captured payloads.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)]$ObjectNode)

    $result = @{
        MoRef = $ObjectNode.obj.InnerText
        Type  = $ObjectNode.obj.type
    }

    if (-not $ObjectNode.propSet) { return $result }

    foreach ($prop in @($ObjectNode.propSet)) {
        if (-not $prop) { continue }
        $name = $prop.name

        # Scalars carry their text directly; complex/array values keep the node
        # so a caller can dig further if it needs to.
        $val = $prop.val
        if ($null -eq $val) {
            $result[$name] = $null
        } elseif ($val -is [string]) {
            $result[$name] = $val
        } elseif ($val.ChildNodes.Count -eq 1 -and $val.ChildNodes[0].NodeType -eq 'Text') {
            $result[$name] = $val.InnerText
        } elseif ($val.ChildNodes.Count -eq 0) {
            $result[$name] = $val.InnerText
        } else {
            $result[$name] = $val
        }
    }

    return $result
}

function Get-VMwarePropertySet {
    <#
        .SYNOPSIS
            Retrieves a set of properties for every object of one type.
        .DESCRIPTION
            Builds a PropertyFilterSpec over a ContainerView and follows the
            continuation token, so inventories larger than one page are handled.
        .OUTPUTS
            One hashtable per object (see ConvertFrom-VMwarePropSet).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Connection,
        [Parameter(Mandatory)][string]$Type,
        [Parameter(Mandatory)][string[]]$Properties,
        [string]$Container
    )

    $viewId = New-VMwareContainerView -Connection $Connection -Type $Type -Container $Container
    try {
        $pathSet = ($Properties | ForEach-Object { "        <pathSet>$(ConvertTo-VMwareXmlText $_)</pathSet>" }) -join "`n"

        $body = @"
    <RetrievePropertiesEx>
      <_this type="PropertyCollector">$(ConvertTo-VMwareXmlText $Connection.ServiceContent.PropertyCollector)</_this>
      <specSet>
        <propSet>
          <type>$(ConvertTo-VMwareXmlText $Type)</type>
          <all>false</all>
$pathSet
        </propSet>
        <objectSet>
          <obj type="ContainerView">$(ConvertTo-VMwareXmlText $viewId)</obj>
          <skip>true</skip>
          <selectSet xsi:type="TraversalSpec">
            <name>traverseEntities</name>
            <type>ContainerView</type>
            <path>view</path>
            <skip>false</skip>
          </selectSet>
        </objectSet>
      </specSet>
      <options/>
    </RetrievePropertiesEx>
"@

        $xml = Invoke-VMwareSoap -Connection $Connection -Body $body
        $returnval = $xml.Envelope.Body.RetrievePropertiesExResponse.returnval

        $results = New-Object System.Collections.Generic.List[object]

        while ($returnval) {
            foreach ($obj in @($returnval.objects)) {
                if ($obj) { $results.Add((ConvertFrom-VMwarePropSet -ObjectNode $obj)) }
            }

            $token = $returnval.token
            if ([string]::IsNullOrEmpty($token)) { break }

            $contBody = @"
    <ContinueRetrievePropertiesEx>
      <_this type="PropertyCollector">$(ConvertTo-VMwareXmlText $Connection.ServiceContent.PropertyCollector)</_this>
      <token>$(ConvertTo-VMwareXmlText $token)</token>
    </ContinueRetrievePropertiesEx>
"@
            $xml = Invoke-VMwareSoap -Connection $Connection -Body $contBody
            $returnval = $xml.Envelope.Body.ContinueRetrievePropertiesExResponse.returnval
        }

        return $results.ToArray()
    } finally {
        Remove-VMwareView -Connection $Connection -ViewId $viewId
    }
}

function Invoke-VMwareMethod {
    <#
        .SYNOPSIS
            Calls a no-argument vim25 method on a managed object.
        .DESCRIPTION
            Covers the power operations, which all take only _this.
        .OUTPUTS
            The task MoRef for *_Task methods, otherwise $null.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Connection,
        [Parameter(Mandatory)][string]$Method,
        [Parameter(Mandatory)][string]$MoRef,
        [Parameter(Mandatory)][string]$MoType
    )

    $body = @"
    <$Method>
      <_this type="$(ConvertTo-VMwareXmlText $MoType)">$(ConvertTo-VMwareXmlText $MoRef)</_this>
    </$Method>
"@

    $xml = Invoke-VMwareSoap -Connection $Connection -Body $body
    $responseNode = $xml.Envelope.Body.ChildNodes[0]
    if ($responseNode -and $responseNode.returnval) {
        return $responseNode.returnval.InnerText
    }
    return $null
}

function Get-VMwareTaskState {
    <#
        .SYNOPSIS
            Reads info.state / info.progress / info.error for a running task.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Connection,
        [Parameter(Mandatory)][string]$TaskMoRef
    )

    $body = @"
    <RetrievePropertiesEx>
      <_this type="PropertyCollector">$(ConvertTo-VMwareXmlText $Connection.ServiceContent.PropertyCollector)</_this>
      <specSet>
        <propSet>
          <type>Task</type>
          <all>false</all>
          <pathSet>info.state</pathSet>
          <pathSet>info.progress</pathSet>
          <pathSet>info.error</pathSet>
        </propSet>
        <objectSet>
          <obj type="Task">$(ConvertTo-VMwareXmlText $TaskMoRef)</obj>
          <skip>false</skip>
        </objectSet>
      </specSet>
      <options/>
    </RetrievePropertiesEx>
"@

    $xml = Invoke-VMwareSoap -Connection $Connection -Body $body
    $obj = $xml.Envelope.Body.RetrievePropertiesExResponse.returnval.objects
    if (-not $obj) { return $null }

    $props = ConvertFrom-VMwarePropSet -ObjectNode $obj

    $errorMessage = $null
    if ($props.ContainsKey('info.error') -and $props['info.error']) {
        $errNode = $props['info.error']
        if ($errNode -is [string]) { $errorMessage = $errNode }
        elseif ($errNode.localizedMessage) { $errorMessage = $errNode.localizedMessage }
        else { $errorMessage = $errNode.InnerText }
    }

    $progress = 0
    if ($props.ContainsKey('info.progress') -and $props['info.progress']) {
        [int]::TryParse([string]$props['info.progress'], [ref]$progress) | Out-Null
    }

    return [pscustomobject]@{
        State    = [string]$props['info.state']
        Progress = $progress
        Error    = $errorMessage
    }
}
