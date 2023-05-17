##### DEBUG MODE #####
$DebugMode = $false

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
# Include external functions
. (PowerShell -Command "Get-ChildItem -Path '.\' -Filter 'XWB-Tools.ps1' -Recurse | Select-Object -ExpandProperty FullName | Resolve-Path -Relative")
. (PowerShell -Command "Get-ChildItem -Path '.\' -Filter 'XWB-Configuration.ps1' -Recurse | Select-Object -ExpandProperty FullName | Resolve-Path -Relative")
. (PowerShell -Command "Get-ChildItem -Path '.\' -Filter 'XWB-Main.ps1' -Recurse | Select-Object -ExpandProperty FullName | Resolve-Path -Relative")
# Welcome Message
Set-WelcomeMessage -ScriptName "XWB-Repacker"
# Header
$Header = "header.bin"
# Cache
$CacheFolderPath = ".\Cache"

##########################
##### Configuration ######
##########################
# Get and store configuration in config file
$ConfigFile = ".\XwbAudioReplacer.config" # config file
# Check config file existance
if (-not(Test-Path -Path $ConfigFile -PathType Leaf)) {
    # If the file does not exist, create it.
    if ($DebugMode) { Write-HostInfo -Text "The config file $ConfigFile does not exists. Creating..." }
    New-Item -ItemType File -Path $ConfigFile -Force -ErrorAction Stop | Out-Null # Create new item
    Set-Configuration -ConfigFile $ConfigFile # Get and store configuration in config file
}
else {
    # If the file already exists, show the message and do nothing
    if ($DebugMode) { Write-HostInfo -Text "The config file already exists." }
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

############################
##### Game is running ######
############################
# Check if the game is running
if ($GameName -match '\.exe$') {
    # Path to the game exe is really an "*.exe"
    $GameProcess = Get-Process -Name ($GameName.Split('.exe')[-2]) -ErrorAction SilentlyContinue
    if ($GameProcess) {
        # If the game is running, close it
        if ($DebugMode) { Write-HostWarn -Text "There is a process $GameName in background. Killing process..." }
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
    Show-Config -ConfigTable $ConfigTable

    $TitleMainMenu = ""
    $MessageMainMenu = "Make your choice:"
    $OptionsMainMenu = @(
        [System.Management.Automation.Host.ChoiceDescription]::new("&1 - Add all custom sound files", "Upload all WAV files in the custom files folder to the game. Use whenever you add or edit a WAV file to the custom files folder.")
        [System.Management.Automation.Host.ChoiceDescription]::new("&2 - Synchronise custom audio files", "Loads all custom audio files currently in the custom files folder into the game and restores the original version for all other WAV files. Use this function if you wish to remove previously loaded custom sound files from the game that are no longer present in the custom sound files folder.")
        [System.Management.Automation.Host.ChoiceDescription]::new("&3 - Edit configuration", "Use this function if you want to change the script's working folders and decide whether or not to start the game after execution.")
        [System.Management.Automation.Host.ChoiceDescription]::new("&4 - Restore the original XWB file", "Restores the original XWB file created by the game developers. To be used in case something goes wrong and the game no longer starts.")
        [System.Management.Automation.Host.ChoiceDescription]::new("&5 - Delete Cache", "Delete the temporary files of this script. No user file will be deleted. Use this function at the end of use or when you want to archive this script on disk while occupying as few space as possible.")
        [System.Management.Automation.Host.ChoiceDescription]::new("&Quit", "Exit the script.")
        )
    $DefaultMainMenu = 0
    $ResponseMainMenu = $Host.UI.PromptForChoice($TitleMainMenu, $MessageMainMenu, $OptionsMainMenu, $DefaultMainMenu)
    switch ($ResponseMainMenu) {
        ##################################################
        ########### Add all custom sound files ###########
        ##################################################
        0 { Add-AllCustomSoundFiles -XwbPath $XwbPath -CacheFolderPath $CacheFolderPath -OriginalWavPath $OriginalWavPath -CustomWavPath $CustomWavPath -XwbName $XwbName -Header $Header -GameAudioPath $GameAudioPath -GameName $GameName -GameExePath $GameExePath -RunGame $RunGame}

        ######################################################
        ########### Synchronise custom audio files ###########
        ######################################################
        1 { 
            if (Test-Path -Path $CacheFolderPath) {
                if ($DebugMode) { Write-HostInfo -Text "Deleting Cache folder: $CacheFolderPath..." }
                Remove-Item $CacheFolderPath -Recurse -Force
            }
            
            # Run MAIN
            Add-AllCustomSoundFiles -XwbPath $XwbPath -CacheFolderPath $CacheFolderPath -OriginalWavPath $OriginalWavPath -CustomWavPath $CustomWavPath -XwbName $XwbName -Header $Header -GameAudioPath $GameAudioPath -GameName $GameName -GameExePath $GameExePath -RunGame $RunGame
        }

        ##########################################
        ########### Edit configuration ###########
        ##########################################
        2 {
            # The answer is Yes (say, user wants to change configuration)
            
            Show-Config -ConfigTable $ConfigTable
            
            # Menu
            $TitleConfMenu = ""
            $MessageConfMenu = "Choose the ID you want to change"
            $OptionsConfMenu = @(
                [System.Management.Automation.Host.ChoiceDescription]::new("&Back to main menu", "Exit from change configuration mode.")
                [System.Management.Automation.Host.ChoiceDescription]::new("&1 - OriginalWavPath", "The path containing the WAV files extracted from the XWB file with XWBExtractor.ps1")
                [System.Management.Automation.Host.ChoiceDescription]::new("&2 - CustomWavPath", "The path that will contain the user's audio files")
                [System.Management.Automation.Host.ChoiceDescription]::new("&3 - XwbPath", "The path to the XWB file inside the game folder")
                [System.Management.Automation.Host.ChoiceDescription]::new("&4 - GameExePath", "The path to the exe file of the game launcher")
                [System.Management.Automation.Host.ChoiceDescription]::new("&5 - RunGame", "Whether or not to run the game")
            )        
            $DefaultConfMenu = 0  # 0=Cancel
    
            do {

                Show-Config -ConfigTable $ConfigTable

                # Do until the answer is Cancel (default)
                $ResponseConfMenu = $Host.UI.PromptForChoice($TitleConfMenu, $MessageConfMenu, $OptionsConfMenu, $DefaultConfMenu)
                switch ($ResponseConfMenu) {
                    # For any cases (say, IDs) the user wants to edit, call custom function Edit-Configuration
                    1 { $OriginalWavPath = $ConfigTableVal[0] = (Edit-Configuration -ConfigKey "OriginalWavPath" -ConfigFile $ConfigFile -Index 1).Replace("`"", "") } # see custom function
                    2 { $CustomWavPath = $ConfigTableVal[1] = (Edit-Configuration -ConfigKey "CustomWavPath" -ConfigFile $ConfigFile -Index 2).Replace("`"", "") }
                    3 { $XwbPath = $ConfigTableVal[2] = (Edit-Configuration -ConfigKey "XwbPath" -ConfigFile $ConfigFile -Index 3).Replace("`"", "") }
                    4 { $GameExePath = $ConfigTableVal[3] = (Edit-Configuration -ConfigKey "GameExePath" -ConfigFile $ConfigFile -Index 4).Replace("`"", "") }
                    5 { $RunGame = $ConfigTableVal[4] = Edit-Configuration -ConfigKey "RunGame" -ConfigFile $ConfigFile -Index 5 }
                }
                $CounterConfMenu++ # Used to understand if any change has been made or requested

                if ($ResponseConfMenu -eq $DefaultConfMenu) {
                    Clear-Host
                }
            } until ($ResponseConfMenu -eq $DefaultConfMenu)
    
            # Edit table with the new configuration
            $ConfigTable = Build-ConfigTable -TableId $ConfigTableId -TableKey $ConfigTableKey -TableVal $ConfigTableVal
            if ($CounterConfMenu -gt 1) {
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
            Write-HostInfo -Text "Original XWB file restored."
            
            if ($RunGame) {
                # Run the game only if it is set so in the configuration
                if ($DebugMode) { Write-HostInfo -Text $GameName" is starting..." }
                Start-Process -FilePath $GameExePath -WorkingDirectory "C:\GOG Games\Monkey Island 1 SE" -Wait
            }
            else {
                if ($DebugMode) { Write-HostInfo -Text "You chose not to start $GameName. Exiting..." }
                exit
            }
        }

        ##########################
        ###### Delete Cache ######
        ##########################
        4 {
            if (Test-Path -Path $CacheFolderPath) {
                if ($DebugMode) { Write-HostInfo -Text "Deleting Cache folder: $CacheFolderPath..." }
                Remove-Item $CacheFolderPath -Recurse -Force
                Write-HostInfo -Text "Cache folder deleted."
            }

            exit
        }

        ##################
        ###### Exit ######
        ##################
        5 { exit }
    }

} until ($ResponseMainMenu -eq $DefaultMainMenu)
