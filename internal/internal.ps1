Function Import-ConfigVariable
{
<#
	.SYNOPSIS
		Import configuration form disk
	
	.DESCRIPTION
		Import configuration form disk

	.EXAMPLE
		Import-ConfigVariable
#>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$False)]
        [Switch]$Reload
    )

    If ($Reload){
        If (Test-Path -Path "$((Get-Location).path)\evccminchargeweeathercontroleconfig.xml" ) {
            $Global:Config = Import-Clixml -Path "$((Get-Location).path)\evccminchargeweeathercontroleconfig.xml" -ErrorAction SilentlyContinue
            return $Global:Config
        }else{
            Throw 'Please run Set-EvccMinchargeWeatherControleConfig first to configure this module'
        }
    }

    If ($Global:Config){
        Write-LogEntry
    }else{
        If (Test-Path -Path "$((Get-Location).path)\evccminchargeweeathercontroleconfig.xml"){
            $Global:Config = Import-Clixml -Path "$((Get-Location).path)\evccminchargeweeathercontroleconfig.xml"
        }else{
            Write-LogEntry -Severity 1 -Message 'evccminchargeweeathercontroleconfig.xml Does not exist'
            Throw 'Please run Set-EvccMinchargeWeatherControleConfig first to configure this module'
        }        
    }

    return $Global:Config
}

Function Get-EvccData
{
<#
	.SYNOPSIS
		This will get the EVCC data 
	
	.DESCRIPTION
		This will get the EVCC data from your host to determine the intervalls 

	.EXAMPLE
		Get-EvccData
#>
    [CmdletBinding()]
    Param (
    )

    $EvccData = @{}

    Try {
        $EvccDataRaw = Invoke-RestMethod -Uri "$($Global:Config.'Url.evcc')/api/state"
        $EvccData.SourceOk = $True
    }catch{
        $EvccData.charging
        $EvccData.SourceOk = $False
    }

    if($EvccDataRaw.result){
        $EvccData.Connected = $EvccDataRaw.result.loadpoints.connected
        $EvccData.Charging = $EvccDataRaw.result.loadpoints.charging
        $EvccData.vehicles = $EvccDataRaw.result.vehicles
    }else{
        $EvccData.Connected = $EvccDataRaw.loadpoints.connected
        $EvccData.Charging = $EvccDataRaw.loadpoints.charging
        $EvccData.vehicles = $EvccDataRaw.vehicles
    }
    return $EvccData
}

Function Write-LogEntry
{
<#
	.SYNOPSIS
		Write a entry in the log
	
	.DESCRIPTION
		Write a entry in the log based on the severity level of the message
	
	.EXAMPLE
		Write-LogEntry
#>

    [CmdletBinding()]
    Param (  
    
    [Parameter(Mandatory=$True)]
    [String]$Message,

    [Parameter(Mandatory=$False)]
    [Int32]$Severity=0
    )
    

    if ([string]::Empty -eq $Message ){
        $Message = 'No message provided'
    }

    #Information
    If ($Severity -eq 0){
        If ($Global:Config.'Log.Level' -ge 0){
            "$(Get-Date -Format "yyyyMMdd-HHmm ")Info: $Message" | Out-File -Append -FilePath ./volvo4evcc.log
            
        }
        Write-Host -Message $Message
    }

    #Warning
    If ($Severity -eq 1){
        If ($Global:Config.'Log.Level' -ge 1){
            "$(Get-Date -Format "yyyyMMdd-HHmm ")Warning: $Message" | Out-File -Append -FilePath ./volvo4evcc.log
            
        }
        Write-Warning -Message $Message
    }

    #Debug
    If ($Severity -eq 2){
        If ($Global:Config.'Log.Level' -ge 2){
            "$(Get-Date -Format "yyyyMMdd-HHmm ")Debug: $Message" | Out-File -Append -FilePath ./volvo4evcc.log
            
        }
        Write-Debug -Message $Message   
    }
}

Function Get-SunHours
{
<#
	.SYNOPSIS
		Get the sun hours for the comming days
	
	.DESCRIPTION
		Get the sun hours for the comming days where the sun is delivering PV 
	
	.EXAMPLE
		Get-SunHours
#>

    [CmdletBinding()]
    Param ()
    $Api = "https://api.open-meteo.com/v1/forecast?latitude=$($Global:Config.'Weather.latitude'| ConvertFrom-SecureString -AsPlainText)&longitude=$($Global:Config.'Weather.longitude'| ConvertFrom-SecureString -AsPlainText)&daily=sunshine_duration&forecast_days=16"
    $Daily = Invoke-RestMethod -Uri $Api -Method 'get'

    $ForecastDaily = @()
    $Counter = 0
    foreach ($Time in $Daily.daily.time)
    {
        $TempObject = New-Object -TypeName "PSCustomObject"
        $TempObject | Add-Member -memberType 'noteproperty' -name 'Time' -Value $Daily.daily.time[$counter]
        $TempObject | Add-Member -memberType 'noteproperty' -name 'SunHours' -Value ([math]::Round($Daily.daily.sunshine_duration[$counter]/3600, 1))
        $Counter++
        $ForecastDaily += $TempObject
    }

    Return $ForecastDaily
}

Function Update-SunHours
{
    <#
	.SYNOPSIS
		Update the sun hours for the comming days
	
	.DESCRIPTION
		Update the sun hours for the comming days where the sun is delivering PV 
	
	.EXAMPLE
		Update-SunHours
#>

    [CmdletBinding()]
    Param ()

    Write-LogEntry -Severity 0 -Message 'Weather - Testing weather settings'

    $Sunhours = Get-Sunhours

    $Evcc = Invoke-RestMethod -Uri "$($Global:Config.'Url.Evcc')/api/state" -Method get
    if ($Evcc.result){
        $TargetVehicle = $Evcc.result.vehicles | Get-Member |  Where-Object -FilterScript {$_.Membertype -eq "NoteProperty" }
    }else{
        $TargetVehicle = $Evcc.vehicles | Get-Member |  Where-Object -FilterScript {$_.Membertype -eq "NoteProperty" }
    }

    if (!($Evcc.vehicles.($TargetVehicle.name).minSoc -eq 0 ))
    {

        if($SunHours){
            $SunHours.SunHours[0..($Global:Config.'Weather.SunHoursDaysDevider'-1)] | ForEach-Object -Begin {$TotalSunHours = 0} -Process {$TotalSunHours += $_}
            If (($TotalSunHours / $Global:Config.'Weather.SunHoursDaysDevider') -ge $Global:Config.'Weather.SunHoursHigh'){
                Write-LogEntry -Severity 0 -Message "Weather - More than enough sun"
                $MinSocValue = $Global:Config.'Weather.SunHoursMinsocLow'
 
            }elseIf (($TotalSunHours / $Global:Config.'Weather.SunHoursDaysDevider') -ge $Global:Config.'Weather.SunHoursMedium'){
                Write-LogEntry -Severity 0 -Message "Weather - Medium sun"
                
                #Overwrite the 3 day forecast if today is verry sunny
                If ($SunHours.SunHours[0] -gt $Global:Config.'Weather.SunHoursMedium')
                {
                    $MinSocValue = $Global:Config.'Weather.SunHoursMinsocLow'
                    Write-LogEntry -Severity 0 -Message "Weather - Daily overwrite As today has more sun"
                }else {
                    $MinSocValue = $Global:Config.'Weather.SunHoursMinsocMedium'
                }

                
            }elseif(($TotalSunHours / $Global:Config.'Weather.SunHoursDaysDevider') -lt $Global:Config.'Weather.SunHoursMedium'){
                Write-LogEntry -Severity 0 -Message "Weather - Not enough sun"
                
                #Overwrite the 3 day forecast if today is verry sunny
                If ($SunHours.SunHours[0] -gt $Global:Config.'Weather.SunHoursMedium')
                {
                    $MinSocValue = $Global:Config.'Weather.SunHoursMinsocLow'
                    Write-LogEntry -Severity 0 -Message "Weather - Daily overwrite As today has more sun"
                }else {
                    $MinSocValue = $Global:Config.'Weather.SunHoursMinsocHigh'
                }
            }
        }

        Write-LogEntry -Severity 0 -Message "Weather - minsoc: $MinSocValue"
        $ResultSetNewMinSoc = Invoke-RestMethod -Uri "$($Global:Config.'Url.Evcc')/api/vehicles/$($TargetVehicle.Name)/minsoc/$MinSocValue" -Method Post


        $Global:Config.'Weather.SunHoursTotalAverage' = $TotalSunHours / 3
        $Global:Config.'Weather.SunHoursToday' = $SunHours.SunHours[0]
    }else{
        Write-LogEntry -Severity 1 -Message "Overwrite of 0 place so skipping weather control"
    }    
}
