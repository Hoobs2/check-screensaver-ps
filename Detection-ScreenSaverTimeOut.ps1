# Test ITS Log location and create folder location if it doesn't exist.
function TestITSLog {
    param()

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

#Loop through User SIDs ordered hashtable, detect if $valueName is less than 
function Test-RegistryValue {
    param (
        [hashtable]$userSIDsTable,
        [string]$valueName,
        [string]$newValue,
        [string]$logFilePath,
        [string]$regPathHive,
        [string]$regPath
    )

    $counter = 0

    try {
        foreach ($userSID in $userSIDsTable.Keys) {
            $currentRegPath = "$regPathHive$userSID$regPath"
                        

            if ( (-not (Test-Path Registry::$currentRegPath)) -or (-not ((Get-Item Registry::$currentRegPath).Property -contains $valuename))) {
                $counter++
                if ($counter -eq $userSIDsTable.Count) {
                    $logMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - No Issue!"
                    Add-content -Path $logFilePath -Value $logMessage
                    return 0
                }
                else {
                    continue
                }
            }
            else {
                $registryValue = Get-ItemPropertyValue -Path Registry::$currentRegPath -Name $valueName -ErrorAction SilentlyContinue

                switch ($registryValue) {
                    {$_ -eq $newValue} {
                        $logMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Registry key '$valueName' under '$currentRegPath' was equal to 600."
                        Add-content -Path $logFilePath -Value $logMessage
                        return 0
                    }
                    {$_ -gt $newValue} {
                        $logMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Registry key '$valueName' under '$currentRegPath' was greater than 600."
                        Add-content -Path $logFilePath -Value $logMessage
                        return 0
                    }
                    {$_ -lt $newValue} {
                        $logMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Registry key '$valueName' under '$currentRegPath' was less than 600."
                        Add-content -Path $logFilePath -Value $logMessage
                        EXIT 1
                    }
                    {$_ -eq $null} {
                        $logMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Registry value '$valueName' not found in path '$currentRegPath'."
                        Add-content -Path $logFilePath -Value $logMessage
                    }
                }
            }
        }
    #Could move the catch up so that it does not include the foreach, allowing to continue the loop if an error occures. Would get rid of if statment?
    } catch {
        $errorMessage = "Error: $($_.Exception.Message)"
        $logErrorMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Failed due to error. '$valueName' under '$currentRegPath'.  $errorMessage"
        Add-content -Path $logFilePath -Value $logErrorMessage
    }
}

#Define variables
$logFilePath = "C:\itslog\Intune\DETECTIONScreenSaverTimeOut.txt"
$regPathHive = "HKEY_USERS\"
$regPath = "\Control Panel\Desktop"
$valueName = "ScreenSaveTimeOut"
$newValue = "600"



#Launch Functions
TestITSLog

# Get User SIDs and create hashtable
$userSIDsTable = Get-UserSIDs

# Check ScreenSaverTimeout for each user in the hashtable
if ((Test-RegistryValue -userSIDsTable $userSIDsTable -valueName $valueName -newValue $newValue -logFilePath $logFilePath -regPathHive $regPathHive -regPath $regPath) -eq 0) {
    Exit 0
}
else {
    Exit 1
}
