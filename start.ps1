#Load the module
Import-Module "$($pwd.path)/evcc-mincharge-weather-controle/evcc-mincharge-weather-controle.psd1" 
#Import-Module "DnsClient-PS"

#Kill any running process that is the same
If ($PSVersionTable.Platform -like "Unix*"){
    Get-Process 'pwsh' | Where-Object -FilterScript {$_.Commandline -like "*evcc-mincharge-weather-controle/start.ps1" -and $_.id -ne $pid } | Stop-Process -Force
}

If ($PSVersionTable.Platform -like "Win*"){
    Get-Process 'pwsh' | Where-Object -FilterScript {$_.Commandline -like "*evcc-mincharge-weather-controle/start.ps1" -and $_.id -ne $pid } | Stop-Process -Force
}

Start-EvccMinchargeWeatherControle
