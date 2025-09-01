Function Start-EvccMinchargeWeatherControle
{
<#
	.SYNOPSIS
		This will start the module interactive
	
	.DESCRIPTION
		This will start the module interactive
	

    .EXAMPLE
        Starts the module interactive

        Start-EvccMinchargeWeatherControle
#>

    [CmdletBinding()]
    Param ()


    #On first start check if config was saved
    If (!(Test-Path -Path "$((Get-Location).path)\evccminchargeweeathercontroleconfig.xml")){
        Export-Clixml -InputObject $Global:Config -Path "$((Get-Location).path)\evccminchargeweeathercontroleconfig.xml"
    }else{
        $Global:Config = Import-Clixml -Path "$((Get-Location).path)\evccminchargeweeathercontroleconfig.xml"
    }

    if (!$Global:Config.'Weather.Enabled')
    {
        Write-LogEntry -Severity 1 -Message 'Weather module is not enabled please run Set-EvccMinchargeWeatherControleConfig first'
        Throw 'Weather module is not enabled please run Set-EvccMinchargeWeatherControleConfig first'
    }


    #Wrap in loop based on evcc data
    $Seconds = 60
    [Int64]$RunCount = 0
    do 
    {
        #Clean itterative variables

        #Increase run count
        $RunCount++


        #Get EvccData
        #If multiple loadpoints Array returns all loadpoints. Testing for true means if any is true it will run.
    
        Update-SunHours

        #sleep
        Start-Sleep -Seconds $Seconds
        
    }while ($True) 

} 

Function Set-EvccMinchargeWeatherControleConfig
{
<#
	.SYNOPSIS
		Configure the Evcc Mincharge Weather Controle Module
	
	.DESCRIPTION
		Configure the Evcc Mincharge Weather Controle Module.
	
	.EXAMPLE
        Configure the Evcc Mincharge Weather Controle Module

		Set-EvccMinchargeWeatherControleConfig

#>

    [CmdletBinding(DefaultParameterSetName = 'Default')]
    [Alias('Set-EvccConfig')]
    Param ()
    
  
    
    #First reload current config before exporting again could be other default session that was started
    $Global:Config = Import-ConfigVariable -Reload

    $Global:Config.'Weather.Enabled' = $true 
    $Global:Config.'Weather.Longitude' = Read-Host -AsSecureString -Prompt 'https://www.latlong.net Location Longitude: '
    $Global:Config.'Weather.Latitude' = Read-Host -AsSecureString -Prompt 'https://www.latlong.net Location Latitude: '
    $Global:Config.'Weather.SunHoursHigh' = 7
    $Global:Config.'Weather.SunHoursMedium' = 4
    
    $Global:Config.'Url.Evcc' = Read-Host -Prompt 'EVCC URL eg: http://192.168.178.201:7070'
    
    Export-Clixml -InputObject $Global:Config -Path "$((Get-Location).path)\evccminchargeweeathercontroleconfig.xml"
    Write-LogEntry -Severity 0 -Message "Exporting config to $((Get-Location).path)\evccminchargeweeathercontroleconfig.xml"

    return $Global:Config

}
