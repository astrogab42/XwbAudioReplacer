Write-Host "XWB-Repacker STARTED" -ForegroundColor blue

# Include external functions
. ".\XWB-Tools.ps1"
. ".\XWB-Configuration.ps1"

##### .NET code #####
# replace data in file as byte stream
Add-Type -TypeDefinition @"
using System;
using System.IO;
using System.Text;
using System.Linq;

public class GPSTools
{
    public static void ReplaceBytes(string fileName, string replaceFileName, int length, int offset = 0)
    {
        byte[] newData = File.ReadAllBytes(replaceFileName);
        if(length != 0)
        {
            newData = newData.Take(length).ToArray();
        }
        Stream stream = File.Open(fileName, FileMode.Open);
        stream.Position = offset;
        stream.Write(newData, 0, newData.Length);
        stream.Close();
    }
}
"@

##########################
##### Initialization #####
##########################
$CurrentTimestamp = Get-Date -Format "yyyyMMddHHmmss"
$Header = "header.bin"
$AddCustomSoundMode = $false
$RebuildCustomXwbMode = $false
$EditConfigurationMode = $false
$RestoreOriginalXwbMode = $false

##########################
##### Configuration ######
##########################
# Get and store configuration in config file
$ConfigFile = ".\xwbrepacker.config" # config file
# Check config file existance
if (-not(Test-Path -Path $ConfigFile -PathType Leaf)) {
    # If the file does not exist, create it.
    Write-HostInfo -Text "The config file $ConfigFile does not exists. Creating..."
    New-Item -ItemType File -Path $ConfigFile -Force -ErrorAction Stop | Out-Null # Create new item
    Set-Configuration -ConfigFile $ConfigFile # Get and store configuration in config file
}
else {
    # If the file already exists, show the message and do nothing
    Write-HostInfo -Text "The config file already exists."
}

##### Store current configuration in variables for this script #####
$ConfigTableVal = [string[]]::new((Get-Content $ConfigFile).Length) # Initiate the array

$i = 0
foreach ($line in Get-Content $ConfigFile) {
    # Get config from file
    $ConfigTableVal[$i] = $line.Replace("`"", "")
    $i++
}

$OriginalWavPath = $ConfigTableVal[0]
$CustomWavPath = $ConfigTableVal[1]
$XwbPath = $ConfigTableVal[2]
$GameExePath = $ConfigTableVal[3]
if ($ConfigTableVal[4] -eq "False") { $RunGame = $false } else { $RunGame = $true }

# Manage and remove quotes in paths
$OriginalWavPath = $OriginalWavPath.Replace("`"", "")
$CustomWavPath = $CustomWavPath.Replace("`"", "")
$XwbPath = $XwbPath.Replace("`"", "")
$GameExePath = $GameExePath.Replace("`"", "")

# Other variables initiation
$XwbName = Split-Path $XwbPath -Leaf
$GameName = Split-Path $GameExePath -Leaf
$GameAudioPath = Split-Path $XwbPath -Parent

# Create keys for table
$ConfigTableKey = @("OriginalWavPath", "CustomWavPath", "XwbPath", "GameExePath", "RunGame")
[int]$max = $ConfigTableKey.Count
$ConfigTableId = 1..$max

# Check existance of files and folders
if (-not(Assert-FolderExists -Folder $OriginalWavPath)) {
    $OriginalWavPath = $ConfigTableVal[0] = (Edit-Configuration -ConfigKey "OriginalWavPath" -ConfigFile $ConfigFile -Index 1).Replace("`"", "")
}
if (-not(Assert-FolderExists -Folder $CustomWavPath)) {
    $CustomWavPath = $ConfigTableVal[1] = (Edit-Configuration -ConfigKey "CustomWavPath" -ConfigFile $ConfigFile -Index 2).Replace("`"", "")
}
if (-not(Assert-FileExists -File $XwbPath)) {
    $XwbPath = $ConfigTableVal[2] = (Edit-Configuration -ConfigKey "XwbPath" -ConfigFile $ConfigFile -Index 3).Replace("`"", "")
}
if (-not(Assert-FileExists -File $GameExePath)) {
    $GameExePath = $ConfigTableVal[3] = (Edit-Configuration -ConfigKey "GameExePath" -ConfigFile $ConfigFile -Index 4).Replace("`"", "")
}

# Build table
$ConfigTable = Build-ConfigTable -TableId $ConfigTableId -TableKey $ConfigTableKey -TableVal $ConfigTableVal

# Show config to user
Write-HostInfo -Text "This is your current configuration:"
$ConfigTable | Format-Table

############################
##### Game is running ######
############################
# Check if the game is running
if ($GameName -match '\.exe$') {
    # Path to the game exe is really an "*.exe"
    $GameProcess = Get-Process -Name ($GameName.Split('.exe')[-2]) -ErrorAction SilentlyContinue
    if ($GameProcess) {
        # If the game is running, close it
        Write-HostWarn -Text "There is a process $GameName in background. Killing process..."
        $GameProcess | Stop-Process -Force # No mercy if you mess with game files.
    }
}
else {
    Write-HostError -Text "The file you selected as game exe exists, but it is not an exe file! Please verify."
    Write-HostError "Fatal Error! Exiting..."
    exit
}

######################
##### User Menu ######
######################
do {
    $TitleMainMenu = ""
    $MessageMainMenu = "Make your choice:"
    $OptionsMainMenu = @(
        [System.Management.Automation.Host.ChoiceDescription]::new("&Add all custom sound files", "Upload all WAV files in the custom files folder to the game. Use whenever you add or edit a WAV file to the custom files folder.")
        [System.Management.Automation.Host.ChoiceDescription]::new("&Synchronise custom audio files", "Loads all custom audio files currently in the custom files folder into the game and restores the original version for all other WAV files. Use this function if you wish to remove previously loaded custom sound files from the game that are no longer present in the custom sound files folder.")
        [System.Management.Automation.Host.ChoiceDescription]::new("&Edit configuration", "Use this function if you want to change the script's working folders and decide whether or not to start the game after execution.")
        [System.Management.Automation.Host.ChoiceDescription]::new("&Restore the original XWB file", "Restores the original XWB file created by the game developers. To be used in case something goes wrong and the game no longer starts.")
    )
    $DefaultMainMenu = 0
    $ResponseMainMenu = $Host.UI.PromptForChoice($TitleMainMenu, $MessageMainMenu, $OptionsMainMenu, $DefaultMainMenu)
    switch ($ResponseMainMenu) {
        ##################################################
        ########### Add all custom sound files ###########
        ##################################################
        0 { continue }

        ######################################################
        ########### Synchronise custom audio files ###########
        ######################################################
        1 { 
            Write-HostInfo -Text "Deleting Repacker folder: $RepackerWavesPath..."
            Remove-Item $RepackerWavesPath -Recurse -Force
        }

        ##########################################
        ########### Edit configuration ###########
        ##########################################
        2 {
            $Title = "" #"$scriptName Configuration"
            $Message = "Do you want to change the configuration?"
            $Options = @(
                [System.Management.Automation.Host.ChoiceDescription]::new("&Yes", "Change the script's working folders and decide whether or not to start the game after execution.")
                [System.Management.Automation.Host.ChoiceDescription]::new("&No", "Keep your current configuration.")
            )
            $Default = 1  # 0=Yes, 1=No
    
            ###do {
                # Do until the answer is No (default)
                ###$Response = $Host.UI.PromptForChoice($Title, $Message, $Options, $Default)
                ###if ($Response -eq 0) {
                    # The answer is Yes (say, user wants to change configuration)
                    $Title = ""
                    $Message = "Choose the ID you want to change"
                    $Options = @(
                        [System.Management.Automation.Host.ChoiceDescription]::new("&Back to main menu", "Exit from change configuration mode.")
                        [System.Management.Automation.Host.ChoiceDescription]::new("&1 - OriginalWavPath", "The path containing the WAV files extracted from the XWB file with XWBExtractor.ps1")
                        [System.Management.Automation.Host.ChoiceDescription]::new("&2 - CustomWavPath", "The path that will contain the user's audio files")
                        [System.Management.Automation.Host.ChoiceDescription]::new("&3 - XwbPath", "The path to the XWB file inside the game folder")
                        [System.Management.Automation.Host.ChoiceDescription]::new("&4 - GameExePath", "The path to the exe file of the game launcher")
                        [System.Management.Automation.Host.ChoiceDescription]::new("&5 - RunGame", "Whether or not to run the game")
                    )        
                    $Default = 0  # 0=Cancel
    
                    do {
                        # Do until the answer is Cancel (default)
                        $Response = $Host.UI.PromptForChoice($Title, $Message, $Options, $Default)
                        switch ($Response) {
                            # For any cases (say, IDs) the user wants to edit, call custom function Edit-Configuration
                            1 { $OriginalWavPath = $ConfigTableVal[0] = (Edit-Configuration -ConfigKey "OriginalWavPath" -ConfigFile $ConfigFile -Index 1).Replace("`"", "") } # see custom function
                            2 { $CustomWavPath = $ConfigTableVal[1] = (Edit-Configuration -ConfigKey "CustomWavPath" -ConfigFile $ConfigFile -Index 2).Replace("`"", "") }
                            3 { $XwbPath = $ConfigTableVal[2] = (Edit-Configuration -ConfigKey "XwbPath" -ConfigFile $ConfigFile -Index 3).Replace("`"", "") }
                            4 { $GameExePath = $ConfigTableVal[3] = (Edit-Configuration -ConfigKey "GameExePath" -ConfigFile $ConfigFile -Index 4).Replace("`"", "") }
                            5 { $RunGame = $ConfigTableVal[4] = Edit-Configuration -ConfigKey "RunGame" -ConfigFile $ConfigFile -Index 5 }
                        }
                        $Counter++ # Used to understand if any change has been made or requested
                    } until ($Response -eq $Default)
                ###}
    
            ###} until ($Response -eq $Default)
    
            # Edit table with the new configuration
            $ConfigTable = Build-ConfigTable -TableId $ConfigTableId -TableKey $ConfigTableKey -TableVal $ConfigTableVal
            if ($Counter -gt 1) {
                # Any changes has been made to the configuration
                Write-HostInfo -Text "This is your new configuration:"
                $ConfigTable | Format-Table
            }
            else {
                Write-HostInfo -Text "Nothing to change in the configuration"
            }
        }

        ##########################################
        ##### Restore the original XWB file ######
        ##########################################
        3 {
            if (Test-Path -Path $GameAudioPath"\"$XwbName".original" -PathType Leaf) {
                Remove-Item $XwbPath
                Rename-Item -Path $GameAudioPath"\"$XwbName".original" -NewName $XwbName
            }
            Write-HostInfo -Text "Original XWB file restored. Exiting..."
            exit
        }
    }

} until ($Response -eq $Default)

Write-Host "Debug mode on"
exit

##########################
######## XWB info ########
##########################
##### Get info from XWB file #####
$ByteStreamLimit = 150 # Limit the number of bytes to speed up the process
$XwbHeader = Get-Content $XwbPath -AsByteStream -TotalCount $ByteStreamLimit # Get content of XWB file as stream of bytes (limit to $ByteStreamLimit)

# Tool version, aka dwVersion / XACT_CONTENT_VERSION
$DwVersionBytePosition = [uint32]"0x08" # Byte at position 0x08 (see Documentation)
$DwVersion = $XwbHeader[$DwVersionBytePosition] # Get byte in position $DwVersionBytePosition
Write-HostInfo -Text "dwVersion of original XWB file: $DwVersion"

# File format, aka dwHeaderVersion
$DwHeaderVersionBytePosition = [uint32]"0x04" # Byte at position 0x04 (see Documentation)
$DwHeaderVersion = $XwbHeader[$DwHeaderVersionBytePosition] # Get byte in position $DwHeaderVersionBytePosition
Write-HostInfo -Text "dwHeaderVersion of original XWB file: $DwHeaderVersion"

<# DEPRECATED
# Timestamp
$XwbTimestampBytePosition = [uint32]"0x8c" # byte at position 0x8c (see Documentation)
$XwbTimestampByteLength = 8 # 8 byte (see Documentation)
$XwbTimestamp = $XwbHeader[$XwbTimestampBytePosition..($XwbTimestampBytePosition + $XwbTimestampByteLength - 1)]
Write-HostInfo -Text "Timestamp in original XWB header: $XwbTimestamp"
#>

##### Preparation for xwb file built #####
# Repacker Folder (see Documentation)
$RepackerWavesPath = ".\RepackerFolder"
if (-not(Test-Path -Path $RepackerWavesPath)) {
    # Create Repacker folder if it does not exist
    Write-HostInfo -Text "Creating Repacker folder: $RepackerWavesPath..."
    New-Item $RepackerWavesPath -ItemType Directory | Out-Null
}
else {
    Write-HostInfo -Text "Repacker Folder exists."
}


# Print info about folders
Write-HostInfo -Text "Original Folder: $OriginalWavPath. This folder contains the original WAV files extracted from original XWB file."
Write-HostInfo -Text "Dubbed Folder: $CustomWavPath. This folder contains the WAV files that has been dubbed."
Write-HostInfo -Text "Repacker Folder: $RepackerWavesPath. This folder contains the WAV files (original and/or dubbed) that will be packed into the new XWB file."

# Copy of original WAV files in Repacker folder
Write-HostInfo -Text "Construction of Repacker folder: $RepackerWavesPath with Robocopy..."
robocopy /xc /xn /xo $OriginalWavPath $RepackerWavesPath /if *.wav | Out-Null # Flags: /xc (eXclude Changed files) /xn (eXclude Newer files) /xo (eXclude Older files) /if (Include the following Files)

##########################
######## Dubbing #########
##########################
# Copy dubbed audio files from Dubbed folder to Repacker folder
$DubbedFileList = Get-ChildItem $CustomWavPath -Filter "*.wav" # Retrieve list of dubbed WAV files in Dubbed folder
$OriginalWavesList = Get-ChildItem $OriginalWavPath -Filter "*.wav" # Retrieve list of WAV files in Original folder
$RepackerWavesList = Get-ChildItem $RepackerWavesPath -Filter "*.wav" # Retrieve list of WAV files in Repacker folder
$DubbedFilesSizeError = "DubbedFilesError-Size-tmp.txt" # Temporary files to store errors
$DubbedFilesNameError = "DubbedFilesError-Name-tmp.txt"
$DubbedFilesDateError = "DubbedFilesError-Date-tmp.txt"
ForEach ($DubbedFile in $DubbedFileList) {
    if ($OriginalWavesList.Name.Contains($DubbedFile.Name)) {
        # The dubbed file exists among the original ones
        $ID = [uint32]($DubbedFile.Name.Split("_")[0]) # Take the ID (aka number of the file) as number (int32)
        if ($DubbedFile.Length -le $OriginalWavesList[$ID - 1].Length) {
            # Use the ID to get the corresponding file in Repacker folder and compare file size
            if (-not($DubbedFile.LastWriteTime -eq $OriginalWavesList[$ID - 1].LastWriteTime)) {
                # Files do not have the same LastWriteDate, i.e. they are not the same file (optimization check)
                <# FOR OPTIMIZATION
                Write-HostInfo "Copying dubbed file $DubbedFile to Repacker folder $RepackerWavesPath..."
                #>
                robocopy $CustomWavPath $RepackerWavesPath $DubbedFile.Name # Perform the copy and display a summary to the user
            }
            <# FOR OPTIMIZATION
            else {
                Write-HostWarn -Text "File dubbed file $DubbedFile already copied."
                Write-HostInfo "Storing log to file $DubbedFilesDateError..."
                $DubbedFile.Name >> $DubbedFilesDateError
                Write-HostInfo "The script will continue"
                continue
            }
            #>
        }
        else {
            $LengthDelta = $DubbedFile.Length - $OriginalWavesList[$ID - 1].Length # Size difference in byte
            Write-HostWarn "The size of file $($DubbedFile.Name) is greater than the original one's by $LengthDelta byte."
            Write-HostInfo "Storing log to file $DubbedFilesSizeError..."
            $DubbedFile.Name >> $DubbedFilesSizeError
            Write-HostInfo "The script will continue"
            continue
        }
    }
    else {
        Write-HostWarn "The dubbed file $($DubbedFile.Name) has a wrong name."
        Write-HostInfo "Storing log to file $DubbedFilesNameError..."
        $DubbedFile.Name >> $DubbedFilesNameError
        Write-HostInfo "The script will continue"
        continue
    }
}

##### Clean and reorder files in error #####
$DubbedFilesSizeErrorFinal = "DubbedFilesError-Size.txt"
$DubbedFilesNameErrorFinal = "DubbedFilesError-Name.txt"
$DubbedFilesDateErrorFinal = "DubbedFilesError-Date.txt"

if (Test-Path -Path $DubbedFilesSizeError) {
    # If tmp file exists, sort by name and make the list disting (unique)
    Get-Content $DubbedFilesSizeError | Sort-Object | Get-Unique > $DubbedFilesSizeErrorFinal
}
if (Test-Path -Path $DubbedFilesNameError) {
    Get-Content $DubbedFilesNameError | Sort-Object | Get-Unique > $DubbedFilesNameErrorFinal
}
if (Test-Path -Path $DubbedFilesDateError) {
    Get-Content $DubbedFilesDateError | Sort-Object | Get-Unique > $DubbedFilesDateErrorFinal
}

# Display to the user how to use error log files
Write-HostInfo -Text "Check $DubbedFilesSizeErrorFinal for files with wrong size.
`tCheck $DubbedFilesNameErrorFinal for files with wrong name.
`tCheck $DubbedFilesDateErrorFinal for files already copied, with the same last-write date."

##########################
###### Build new XWB #####
##########################
##### Build xwb file from WAV #####
Write-HostInfo -Text "Building $XwbName with XWBTool version $DwVersion/$DwHeaderVersion..."
$buildXWB = .\XWBTool_GPS.exe -o $XwbName -tv $DwVersion -fv $DwHeaderVersion -s -f -y "$RepackerWavesPath\*.wav" # see XWBTool usage on Documentation for details
$XwbToolOutputLogTailLinesNumber = 1 # How many lines at the end of the output in XwbTool log
$NumberOfFileElaboratedByXwbTool = $buildXWB.Length - $XwbToolOutputLogHeadLinesNumber - $XwbToolOutputLogTailLinesNumber
$NumberOfFilesInRepackerFolder = $RepackerWavesList.Length
if ($NumberOfFileElaboratedByXwbTool -lt $NumberOfFilesInRepackerFolder) {
    # In case we have less files elaborated by XwbTool w.r.t. the number of WAV files in Repacker Folder
    Write-HostError "XwbTool elaborated $NumberOfFileElaboratedByXwbTool files, whilst the Repacker Folder contains $NumberOfFilesInRepackerFolder files!"
    Write-HostError "Fatal Error! Exiting..."
    exit
}

##### Update XWB Header #####
$XwbHeader | Set-Content -Path $Header -AsByteStream # Save header to temporary binary file
[GPSTools]::ReplaceBytes($XwbName, $Header, $ByteStreamLimit) # Substitute the first $ByteStreamLimit bytes in the brand-new $XwbName file in current folder
<# DEPRECATED
# Specific change of "timestamp" in header
$XwbTimestamp | Set-Content -Path $Header -AsByteStream # Save header to temporary binary file
[GPSTools]::ReplaceBytes($XwbName, $XwbTimestamp, $XwbTimestampByteLength, $XwbTimestampBytePosition)
#>
Remove-Item $Header # Delete temporary binary file

##########################
######### Outtro #########
##########################
##### Move XWB file to game folder #####
if (-not(Test-Path -Path $GameAudioPath"\"$XwbName".original" -PathType Leaf)) {
    # Create a backup of the original XWB file (adding ".original" at the end of the filename) if not already done
    Rename-Item -Path $GameAudioPath"\"$XwbName -NewName $XwbName".original"
    Write-HostInfo -Text "File $XwbName (assumed to be The Original) renamed in $XwbName.original."
}
else {
        # If the backup of the original XWB file already exists, show the message and do nothing
        Write-HostInfo -Text "File $XwbName.original NOT created because it already exists."
}
Move-Item -Path $XwbName -Destination $GameAudioPath -Force # Copy rebuilt XWB file to game folder


##### Run the game #####
if ($RunGame) {
    # Run the game only if it is set so in the configuration
    Write-HostInfo -Text $GameName" is starting..."
    Start-Process -FilePath $GameExePath -WorkingDirectory "C:\GOG Games\Monkey Island 1 SE" -Wait
}
else {
    Write-HostInfo -Text "You chose not to start $GameName."
}
