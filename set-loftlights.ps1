#Requires -Version 5.1
<#
.SYNOPSIS
    Controls Hive loft lights via Home Assistant REST API
.DESCRIPTION
    Manages three Hive TWGU10Bulb03UK lights through Home Assistant's REST API.
    Supports turning lights on/off and adjusting brightness levels.
.PARAMETER On
    Turn on all loft lights with default settings
.PARAMETER Off
    Turn off all loft lights
.PARAMETER Dim
    Set brightness level (1-100). Can be used alone or with -On.
.PARAMETER WhatIf
    Show what would happen without executing
.EXAMPLE
    Set-LoftLights -On
    Turns on all loft lights with default brightness and colour
.EXAMPLE
    Set-LoftLights -On -Dim 50
    Turns on all loft lights at 50% brightness with default colour
.EXAMPLE
    Set-LoftLights -Dim 50
    Sets brightness to 50% (lights must be on)
.EXAMPLE
    Set-LoftLights -Off
    Turns off all loft lights
.NOTES
    Requires HA_TOKEN environment variable to be set with Home Assistant long-lived access token
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(ParameterSetName = "TurnOn", Mandatory)]
    [Parameter(ParameterSetName = "TurnOnWithDim", Mandatory)]
    [switch]$On,
    
    [Parameter(ParameterSetName = "TurnOff", Mandatory)]
    [switch]$Off,
    
    [Parameter(ParameterSetName = "SetDim", Mandatory)]
    [Parameter(ParameterSetName = "TurnOnWithDim", Mandatory)]
    [ValidateRange(1, 100)]
    [int]$Dim,
    
    [Parameter()]
    [string]$HomeAssistantUrl = "https://ha.err.services",
    
    [Parameter()]
    [int]$TimeoutSeconds = 10
)

# Constants for default operation
$Script:DefaultBrightness = 80        # Range: 1-100 (percentage)
$Script:DefaultHue = 25              # Range: 0-360 (degrees on colour wheel)
$Script:DefaultSaturation = 15       # Range: 0-100 (percentage - lower = more white)

# Configuration
$Script:LightEntities = @(
    "light.loft_front",
    "light.loft_middle", 
    "light.loft_rear"
)

$Script:RestApiTimeout = New-TimeSpan -Seconds $TimeoutSeconds

#region Private Functions

function Get-HomeAssistantHeaders {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()
    
    $ApiToken = $env:HA_TOKEN
    if ([string]::IsNullOrWhiteSpace($ApiToken)) {
        $Exception = [System.InvalidOperationException]::new(
            "Home Assistant API token not found. Set environment variable: `$env:HA_TOKEN = 'your_token'"
        )
        $ErrorRecord = [System.Management.Automation.ErrorRecord]::new(
            $Exception,
            'MissingApiToken',
            [System.Management.Automation.ErrorCategory]::AuthenticationError,
            $null
        )
        $PSCmdlet.ThrowTerminatingError($ErrorRecord)
    }
    
    return @{
        "Authorization" = "Bearer $ApiToken"
        "Content-Type" = "application/json"
        "User-Agent" = "PowerShell-LoftLights/1.0"
    }
}

function Invoke-HomeAssistantService {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet("turn_on", "turn_off")]
        [string]$Service,
        
        [Parameter()]
        [hashtable]$ServiceData = @{},
        
        [Parameter()]
        [string]$Domain = "light"
    )
    
    $Headers = Get-HomeAssistantHeaders
    
    $RequestBody = @{
        entity_id = $Script:LightEntities
    }
    
    if ($ServiceData.Count -gt 0) {
        $RequestBody += $ServiceData
    }
    
    $Uri = "$HomeAssistantUrl/api/services/$Domain/$Service"
    $JsonBody = $RequestBody | ConvertTo-Json -Depth 3
    
    Write-Verbose "Calling: $Uri"
    Write-Verbose "Request body: $JsonBody"
    
    if ($PSCmdlet.ShouldProcess("Loft lights ($($Script:LightEntities -join ', '))", $Service)) {
        try {
            $SplatParams = @{
                Uri         = $Uri
                Method      = 'Post'
                Headers     = $Headers
                Body        = $JsonBody
                TimeoutSec  = $TimeoutSeconds
                ErrorAction = 'Stop'
            }
            
            $Response = Invoke-RestMethod @SplatParams
            
            Write-Information "Successfully executed '$Service' on loft lights" -InformationAction Continue
            
            return [PSCustomObject]@{
                Success   = $true
                Service   = $Service
                Entities  = $Script:LightEntities
                Response  = $Response
                Timestamp = Get-Date
            }
        }
        catch [System.Net.WebException] {
            $ErrorMsg = "Network error connecting to Home Assistant: $($_.Exception.Message)"
            Write-Error $ErrorMsg
            throw [System.Net.NetworkInformation.NetworkInformationException]::new($ErrorMsg)
        }
        catch {
            $ErrorMsg = "Failed to execute '$Service': $($_.Exception.Message)"
            Write-Error $ErrorMsg
            throw
        }
    }
}

#endregion

#region Main Logic

try {
    switch ($PSCmdlet.ParameterSetName) {
        { $_ -ne "TurnOff" } {
            # All non-off operations use turn_on service with brightness
            $BrightnessLevel = if ($PSBoundParameters.ContainsKey('Dim')) { $Dim } else { $Script:DefaultBrightness }
            
            # Build service data
            $ServiceData = @{
                brightness_pct = $BrightnessLevel
            }
            
            # Add colour only when explicitly turning on (not just dimming)
            if ($On) {
                $ServiceData['hs_color'] = @($Script:DefaultHue, $Script:DefaultSaturation)
                Write-Verbose "Turning on loft lights at ${BrightnessLevel}% brightness with default colour (hue: ${Script:DefaultHue}°)"
            } else {
                Write-Verbose "Setting loft lights brightness to ${BrightnessLevel}% (lights must be on)"
            }
            
            $Result = Invoke-HomeAssistantService -Service "turn_on" -ServiceData $ServiceData
        }
        
        "TurnOff" {
            Write-Verbose "Turning off loft lights"
            $Result = Invoke-HomeAssistantService -Service "turn_off"
        }
    }
    
    if ($Result.Success) {
        Write-Output $Result
    }
}
catch {
    Write-Error "Operation failed: $($_.Exception.Message)"
    exit 1
}

#endregion