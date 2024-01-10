<#
Davey Hobbs
2024/01/10

#>

#Test ITS Log location and create folder location if it doesnt exist.
function TestITSLog {
    param ()

    if (!(Test-Path "C:\itslog\Intune")) {
        New-Item -ItemType Directory -Path "C:\itslog\Intune" -Force -ErrorAction SilentlyContinue > $null
    }
    
}

#Set Registry Key and write log.
function Set-RegistryKeyValue {
    param(
        [string]$regPath,
        [string]$valueName,
        [string]$newValue,
        [string]$logFilePath
    )

    try {
        Set-ItemProperty -Path $regPath -Name $valueName -Value $newValue -ErrorAction Stop
        $logMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Registry key '$valueName' under '$regPath' changed to '$newValue' successfully."
        Add-content -Path $logFilePath -Value $logMessage
    } catch {
        $errorMessage = "Error: $($_.Exception.Message)"
        $logErrorMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Failed to change registry key '$valueName' under '$regPath'. $errorMessage"
        Add-content -Path $logFilePath -Value $logErrorMessage
    }
}

#Set Variable Values
$regPath = "HKCU:\Control Panel\Desktop"
$valueName = "ScreenSaveTimeOut"
$newValue = "600"
$logFilePath = "C:\itslog\Intune\ScreenSaverTimeOut.txt"

TestITSLog
Set-RegistryKeyValue -regPath $regPath -valueName $valueName -newValue $newValue -logFilePath $logFilePath