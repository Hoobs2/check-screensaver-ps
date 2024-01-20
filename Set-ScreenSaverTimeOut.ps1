<#
Davey Hobbs
2024/01/10
Create ITSLog location, Get User SIDs from local machine and add to Ordered hashtable, loop through hashtable and change registry value if it exists.
#>

#Test ITS Log location and create folder location if it doesnt exist.
function TestITSLog {
    param ()

    if (!(Test-Path "C:\itslog\Intune")) {
        New-Item -ItemType Directory -Path "C:\itslog\Intune" -Force -ErrorAction SilentlyContinue > $null
    }
    
}

#Get all User SIDs from Local Machine and add them to an ordered HashTable.
function Get-UserSIDs {
    $profileListPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"
    $userSIDs = Get-ChildItem -Path $profileListPath | ForEach-Object {
        $_.PSChildName
    }

    $userSIDsTable = [ordered]@{}
    foreach ($sid in $userSIDs) {
        $userSIDsTable[$sid] = $null
    }

    return $userSIDsTable
}

#Set Registry Key and write log.
function Set-RegistryKeyValue {
    param(
        [hashtable]$userSIDsTable,
        [string]$regPathHive,
        [string]$regPath,
        [string]$valueName,
        [string]$newValue,
        [string]$logFilePath 
    )
    #Try block and Catch error and write to log file. Could try moving to inside loop to catch errors and continue loop, possibly allowing the removal of the internal if statment.
    try {
        #Loop through entire userSID ordered hashtable, and evaluate ScreenSaveTimeOut value.
        foreach ($userSID in $userSIDsTable.Keys) {
            $currentRegPath = "$regPathHive$userSID$regPath"

            #If the path does not exist or the item ScreenSaveTimeOut under HKEY_USERS\{SID}\Control Panel\Desktop does not exist but the path does, continue to next loop iteration. Else move to further evaluation. (Could move into Switch at somepoint.)
            if ( (-not (Test-Path Registry::$currentRegPath)) -or (-not ((Get-Item Registry::$currentRegPath).Property -contains $valuename))) {
                continue
            }
            else {
                $registryValue = Get-ItemPropertyValue -Path Registry::$currentRegPath -Name $valueName -ErrorAction SilentlyContinue

                #Evaluate ScreenSaveTimeOut value.
                switch ($registryValue) {
                    #If ScreenSaveTimeOut is equal to 600, continue to next loop iteration.
                    {$_ -eq $newValue} {
                        $logMessage = "$(Get-Date -Format 'yyyy-MM-dd hh:mm:ss') - Registry key '$valueName' under '$currentRegPath' is equal to 600."
                        Add-content -Path $logFilePath -Value $logMessage
                        continue
                    }
                    #If ScreenSaveTimeOut is greater than 600, continue to next loop iteration.
                    {$_ -gt $newValue} {
                        $logMessage = "$(Get-Date -Format 'yyyy-MM-dd hh:mm:ss') - Registry key '$valueName' under '$currentRegPath' is greater than 600."
                        Add-content -Path $logFilePath -Value $logMessage
                        continue
                    }
                    #If ScreenSaveTimeOut is set to less then 600, set value to 600.
                    {$_ -lt $newValue} {
                        Set-ItemProperty -Path Registry::$currentRegPath -Name $valueName -Value $newValue -ErrorAction SilentlyContinue
                        $logMessage = "$(Get-Date -Format 'yyyy-MM-dd hh:mm:ss') - Registry key '$valueName' under '$currentRegPath' was less than 600. Changed to 600."
                        Add-content -Path $logFilePath -Value $logMessage
                        continue
                    }
                    #If ScreenSaveTimeOut exists but does not have a value, set value to 600
                    {$_ -eq $null} {
                        Set-ItemProperty -Path Registry::$currentRegPath -Name $valueName -Value $newValue -ErrorAction SilentlyContinue
                        $logMessage = "$(Get-Date -Format 'yyyy-MM-dd hh:mm:ss') - Registry value '$valueName' under '$currentRegPath' did not have a value set."
                        Add-content -Path $logFilePath -Value $logMessage
                        continue
                    }
                }
            }
        }
    } catch {
        $errorMessage = "Error: $($_.Exception.Message)"
        $logErrorMessage = "$(Get-Date -Format 'yyyy-MM-dd hh:mm:ss') - Failed due to error. '$valueName' under '$currentRegPath'.  $errorMessage"
        Add-content -Path $logFilePath -Value $logErrorMessage
    }
}

#Set Variable Values
$regPath = "\Control Panel\Desktop"
$regPathHive = "HKEY_USERS\"
$valueName = "ScreenSaveTimeOut"
$newValue = "600"
$logFilePath = "C:\itslog\Intune\ScreenSaverTimeOut.txt"

#Get User SIDs and create hashtable
$userSIDsTable = Get-UserSIDs

#Call functions.
TestITSLog
Set-RegistryKeyValue -userSIDsTable $userSIDsTable -regPathHive $regPathHive -regPath $regPath -valueName $valueName -newValue $newValue -logFilePath $logFilePath