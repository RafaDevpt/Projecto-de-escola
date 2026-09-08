Describe 'ConvertTo-VMwareXmlText' {

    It 'escapes ampersands, which otherwise corrupt a password in the envelope' {
        Assert-Equal 'a&amp;b' (ConvertTo-VMwareXmlText 'a&b')
    }

    It 'escapes angle brackets' {
        Assert-Equal '&lt;script&gt;' (ConvertTo-VMwareXmlText '<script>')
    }

    It 'escapes quotes and apostrophes' {
        Assert-Equal '&quot;x&apos;y&quot;' (ConvertTo-VMwareXmlText '"x''y"')
    }

    It 'escapes the ampersand first so entities are not double-encoded' {
        Assert-Equal '&amp;lt;' (ConvertTo-VMwareXmlText '&lt;')
    }

    It 'returns empty string for null' {
        Assert-Equal '' (ConvertTo-VMwareXmlText $null)
    }

    It 'produces a well-formed envelope for a password full of metacharacters' {
        $password = 'P@ss<w&o>rd"1'
        $body = "<Login><password>$(ConvertTo-VMwareXmlText $password)</password></Login>"
        $envelope = New-VMwareSoapEnvelope -Body $body

        $parsed = [xml]$envelope
        Assert-Equal $password $parsed.Envelope.Body.Login.password
    }
}

Describe 'New-VMwareSoapEnvelope' {

    It 'produces parseable XML' {
        $xml = [xml](New-VMwareSoapEnvelope -Body '<RetrieveServiceContent><_this type="ServiceInstance">ServiceInstance</_this></RetrieveServiceContent>')
        Assert-Equal 'ServiceInstance' $xml.Envelope.Body.RetrieveServiceContent._this.InnerText
    }

    It 'places request elements in the vim25 namespace' {
        # The default xmlns on <Body> applies to its children, which is what the
        # vSphere endpoint dispatches on - Body itself stays in the SOAP namespace.
        # Queried via XPath because PowerShell surfaces an empty element as a string.
        $xml = [xml](New-VMwareSoapEnvelope -Body '<Login/>')
        $ns = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
        $ns.AddNamespace('vim', 'urn:vim25')
        $node = $xml.SelectSingleNode('//vim:Login', $ns)
        Assert-True ($null -ne $node) 'Login element should resolve inside the vim25 namespace'
        Assert-Equal 'urn:vim25' $node.NamespaceURI
    }
}

Describe 'Get-VMwareSoapFault' {

    It 'extracts the message and type from an invalid-login fault' {
        $xml = [xml]@'
<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <soapenv:Body>
    <soapenv:Fault>
      <faultcode>ServerFaultCode</faultcode>
      <faultstring>Cannot complete login due to an incorrect user name or password.</faultstring>
      <detail><InvalidLoginFault xmlns="urn:vim25" xsi:type="InvalidLogin"/></detail>
    </soapenv:Fault>
  </soapenv:Body>
</soapenv:Envelope>
'@
        $fault = Get-VMwareSoapFault -Response $xml
        Assert-Equal 'Cannot complete login due to an incorrect user name or password.' $fault.Message
        Assert-Equal 'InvalidLoginFault' $fault.FaultType
    }

    It 'returns null when the response is not a fault' {
        $xml = [xml]'<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"><soapenv:Body><LoginResponse xmlns="urn:vim25"><returnval><key>abc</key></returnval></LoginResponse></soapenv:Body></soapenv:Envelope>'
        Assert-True ($null -eq (Get-VMwareSoapFault -Response $xml))
    }
}

Describe 'ConvertFrom-VMwarePropSet' {

    $sample = [xml]@'
<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <soapenv:Body>
    <RetrievePropertiesExResponse xmlns="urn:vim25">
      <returnval>
        <objects>
          <obj type="VirtualMachine">vm-101</obj>
          <propSet><name>name</name><val xsi:type="xsd:string">DC01</val></propSet>
          <propSet><name>runtime.powerState</name><val xsi:type="VirtualMachinePowerState">poweredOn</val></propSet>
          <propSet><name>config.hardware.memoryMB</name><val xsi:type="xsd:int">8192</val></propSet>
          <propSet><name>guest.ipAddress</name><val xsi:type="xsd:string">10.0.0.10</val></propSet>
        </objects>
      </returnval>
    </RetrievePropertiesExResponse>
  </soapenv:Body>
</soapenv:Envelope>
'@

    $objectNode = $sample.Envelope.Body.RetrievePropertiesExResponse.returnval.objects
    $props = ConvertFrom-VMwarePropSet -ObjectNode $objectNode

    It 'captures the managed object reference' {
        Assert-Equal 'vm-101' $props.MoRef
    }

    It 'captures the managed object type' {
        Assert-Equal 'VirtualMachine' $props.Type
    }

    It 'flattens a string property' {
        Assert-Equal 'DC01' $props['name']
    }

    It 'flattens a dotted property path' {
        Assert-Equal 'poweredOn' $props['runtime.powerState']
    }

    It 'flattens a numeric property as text' {
        Assert-Equal '8192' $props['config.hardware.memoryMB']
    }

    It 'flattens the guest IP address' {
        Assert-Equal '10.0.0.10' $props['guest.ipAddress']
    }

    It 'omits properties the server did not return' {
        Assert-False ($props.ContainsKey('guest.toolsStatus'))
    }
}

Describe 'ConvertTo-VMwareInt64' {

    It 'parses a numeric string' {
        Assert-Equal 8192 (ConvertTo-VMwareInt64 '8192')
    }

    It 'returns the default for null' {
        Assert-Equal 0 (ConvertTo-VMwareInt64 $null)
    }

    It 'returns the default for non-numeric text rather than throwing' {
        Assert-Equal 0 (ConvertTo-VMwareInt64 'not-a-number')
    }

    It 'honours a custom default' {
        Assert-Equal -1 (ConvertTo-VMwareInt64 $null -Default -1)
    }

    It 'handles values beyond Int32 range' {
        Assert-Equal 4294967296 (ConvertTo-VMwareInt64 '4294967296')
    }
}

Describe 'Format-VMwareUptime' {

    It 'renders days and hours' {
        Assert-Equal '12d 4h' (Format-VMwareUptime -Seconds 1051200)
    }

    It 'renders hours and minutes below a day' {
        Assert-Equal '3h 25m' (Format-VMwareUptime -Seconds 12300)
    }

    It 'renders minutes below an hour' {
        Assert-Equal '42m' (Format-VMwareUptime -Seconds 2520)
    }

    It 'renders a dash for zero' {
        Assert-Equal '-' (Format-VMwareUptime -Seconds 0)
    }
}
