@{
    # Module manifest for LoftLights module
    RootModule = 'LoftLights.psm1'
    ModuleVersion = '1.0.0'
    GUID = '12345678-1234-1234-1234-123456789012'
    Author = 'User'
    Description = 'Controls Hive loft lights via Home Assistant REST API'
    
    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'
    
    # Functions to export from this module
    FunctionsToExport = @('Set-LoftLights')
    
    # Cmdlets to export from this module
    CmdletsToExport = @()
    
    # Variables to export from this module
    VariablesToExport = @()
    
    # Aliases to export from this module
    AliasesToExport = @()
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            Tags = @('HomeAssistant', 'SmartLights', 'IoT', 'Hive')
            ProjectUri = ''
            LicenseUri = ''
            ReleaseNotes = 'Initial release of LoftLights module'
        }
    }
}