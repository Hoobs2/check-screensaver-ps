<#
Davey Hobbs
2024/01/10
Remediation Detection Script
#>

#Test ITS Log location and create folder location if it doesnt exist.
function TestITSLog {
    param ()

    if (!(Test-Path "C:\itslog\Intune")) {
        New-Item -ItemType Directory -Path "C:\itslog\Intune" -Force -ErrorAction SilentlyContinue > $null
    }
    
}

function Test-RegistryValue {
    param(
        [string]$regPath,
        [string]$valueName
    )

    try {
        $registryValue = Get-ItemPropertyValue -Path $regPath -Name $valueName -ErrorAction Stop

        if ($null -eq $registryValue) {
            $logMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Registry value '$valueName' not found in path '$regPath'."
            Add-content -Path $logFilePath -Value $logMessage
            EXIT 0
        }

        if ($registryValue -eq 600) {
            $logMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Registry key '$valueName' under '$regPath' was equle to 600."
            Add-content -Path $logFilePath -Value $logMessage
            EXIT 0
        } elseif ($registryValue -lt 600) {
            $logMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Registry key '$valueName' under '$regPath' was less than to 600."
            Add-content -Path $logFilePath -Value $logMessage
            EXIT 1
        } else {
            $logMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Registry key '$valueName' under '$regPath' was greater then 600."
            Add-content -Path $logFilePath -Value $logMessage
            EXIT 0
        }
    } catch {
        $errorMessage = "Error: $($_.Exception.Message)"
        $logErrorMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Failed to change registry key '$valueName' under '$regPath'. $errorMessage"
        Add-content -Path $logFilePath -Value $logErrorMessage

    }
}

# Example usage of the function
$regPath = "HKCU:\Control Panel\Desktop"
$valueName = "ScreenSaveTimeOut"
$logFilePath = "C:\itslog\Intune\DETECTIONScreenSaverTimeOut.txt"

TestITSLog
Test-RegistryValue -regPath $regPath -valueName $valueName

