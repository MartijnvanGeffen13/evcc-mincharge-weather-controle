@{

    # Script module or binary module file associated with this manifest.
    RootModule = 'evcc-mincharge-weather-controle.psm1'
    
    # Version number of this module.
    ModuleVersion = '0.0.1'
    
    # ID used to uniquely identify this module
    GUID = '374b75b3-73b7-45b0-913a-76880eb71fc0'
    
    # Author of this module
    Author = 'Martijn van Geffen'
    
    # Company or vendor of this module
    CompanyName = '13TH Division'
    
    # Copyright statement for this module
    Copyright = '(c) 2024 13TH Division. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description = 'evcc-mincharge-weather-controle for EVCC integration'
    
    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '7.4'
    
    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = @(
        'Set-EvccMinchargeWeatherControleConfig',
        'Start-EvccMinchargeWeatherControle'
    )
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData = @{
    
        PSData = @{
    
            # Tags applied to this module. These help with module discovery in online galleries.
            # Tags = @()
    
            # A URL to the license for this module.
            # LicenseUri = ''
    
            # A URL to the main website for this project.
            # ProjectUri = ''
    
            # A URL to an icon representing this module.
            # IconUri = ''
    
            # ReleaseNotes of this module
            # ReleaseNotes = ''
    
        } # End of PSData hashtable
    
    } # End of PrivateData hashtable
    }
    
    