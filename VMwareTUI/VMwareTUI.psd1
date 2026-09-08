@{
    RootModule        = 'VMwareTUI.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = 'b7c4e1d2-9a3f-4e58-8c16-2f7d5a9e4b31'
    Author            = 'RafaDevpt'
    Description       = 'Terminal management console for VMware vCenter and standalone ESXi hosts. Connects over the vSphere Web Services API - no PowerCLI required.'
    PowerShellVersion = '5.1'

    FunctionsToExport = @(
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
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()

    PrivateData = @{
        PSData = @{
            Tags       = @('VMware', 'vSphere', 'vCenter', 'ESXi', 'TUI', 'SysAdmin')
            ProjectUri = 'https://github.com/RafaDevpt/Projecto-de-escola'
        }
    }
}
