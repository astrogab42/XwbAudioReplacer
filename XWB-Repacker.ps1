# Include external functions
. ".\XWB-Functions.ps1"

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
$scriptName = "XWB-Repacker" # name of this script

##########################
##### Configuration ######
##########################
$configFile = ".\xwbrepacker.config" # config file

# Check on config file existance
if (-not(Test-Path -Path $configFile -PathType Leaf)) { # if the file does not exist, create it.
    try {
        Write-HostInfo -Text "The config file $configFile does not exists. Creating..."
        $null = New-Item -ItemType File -Path $configFile -Force -ErrorAction Stop
        Write-HostInfo -Text "The config file $configFile has been created."
        $initWindowsPrompt = $true

        Set-Configuration -ConfigFile $configFile # get and store configuration in config file
    }
    catch {
        throw $_.Exception.Message
    }
}
else { # if the file already exists, show the message and do nothing
    Write-HostInfo -Text "The config file already exists."
}

# Store current configuration in variables for this script
$i = 0
$ConfigTableVal = [string[]]::new((Get-Content $configFile).Length) # initiate the array
foreach($line in Get-Content $configFile) { # get config from file
    $ConfigTableVal[$i] = $line
    $i++
}

if ($ConfigTableVal -eq "False") {
    $RunGame = $false
}
else {
    $RunGame = $true
}
$NewWavesPath   =    $ConfigTableVal[1]
$XwbFilePath    =    $ConfigTableVal[2]
$GameExePath    =    $ConfigTableVal[3]
$GameAudioPath  =    $ConfigTableVal[4]
#$XwbToolVersion =    $ConfigTableVal

$configTableKey = @("RunGame","NewWavesPath","XwbFilePath","GameExePath","GameAudioPath")
[int]$max = $configTableKey.Count
$configTableId = 1..$max
$ConfigTable = Build-ConfigTable -TableId $configTableId -TableKey $configTableKey -TableVal $ConfigTableVal

# show config to user
Write-HostInfo -Text "This is your current configuration:"
$ConfigTable | Format-Table

# edit configuration
$title   = "" #"$scriptName Configuration"
$msg     = "Do you want to change the configuration?"
$options = "&Yes", "&No"
$default = 1  # 0=Yes, 1=No

do {
    $response = $Host.UI.PromptForChoice($title, $msg, $options, $default)
    if ($response -eq 0) {

        $title   = "" #"$scriptName Configuration"
        $msg     = "Choose the ID you want to change"
        $options = "&Cancel", "&1", "&2", "&3", "&4", "&5"
        $default = 0  # 0=Cancel

        do {
            $response = $Host.UI.PromptForChoice($title, $msg, $options, $default)
            switch ($response) {
                1 {$RunGame = $ConfigTableVal[0] = Edit-Configuration -ConfigKey "runGame" -ConfigFile $configFile -Index 1} # see custom function
                2 {$NewWavesPath = $ConfigTableVal[1] = Edit-Configuration -ConfigKey "NewWavesPath" -ConfigFile $configFile -Index 2}
                3 {$XwbFilePath = $ConfigTableVal[2] = Edit-Configuration -ConfigKey "XwbFilePath" -ConfigFile $configFile -Index 3}
                4 {$GameExePath = $ConfigTableVal[3] = Edit-Configuration -ConfigKey "GameMasterPath" -ConfigFile $configFile -Index 4}
                5 {$GameAudioPath = $ConfigTableVal[4] = Edit-Configuration -ConfigKey "GameAudioPath" -ConfigFile $configFile -Index 5}
            }
            $Counter++
        } until ($response -eq $default)
    }

} until ($response -eq $default)

$ConfigTable = Build-ConfigTable -TableId $configTableId -TableKey $configTableKey -TableVal $ConfigTableVal
if ($Counter -gt 1) {
    Write-HostInfo -Text "This is your new configuration:"
    $ConfigTable | Format-Table
}
else {
    Write-HostInfo -Text "Nothing to change in the configuration"
}

# Check existance of files and folders
Assert-FolderExists -Folder $NewWavesPath
Assert-FileExists -File $XwbFilePath
#Assert-FileExists -File $GameExePath # commented for developing and testing purposed. MUST BE ACTIVATED IN PRD
Assert-FolderExists -Folder $GameAudioPath

# Other variables initiation
$XwbName = $XwbFilePath.Split("\")[-1]

exit

##### Get info from XWB file #####
# Tool version, aka dwVersion / XACT_CONTENT_VERSION
$DwVersionBytePosition = 8 # 8th byte, i.e. 8th pair of values (see Bible)
$DwVersion = (Get-Content $XwbFilePath -AsByteStream)[$DwVersionBytePosition-1]
Write-HostInfo -Text "dwVersion of original XWB file: $DwVersion" # 45 ####################### TO BE CHECKED

# File format, aka dwHeaderVersion
$DwHeaderVersionBytePosition = 12 # 12th byte, i.e. 12th pair of values (see Bible)
$DwHeaderVersion = (Get-Content $XwbFilePath -AsByteStream)[$DwVersionBytePosition-1] # 43 ####################### TO BE CHECKED
Write-HostInfo -Text "dwHeaderVersion of original XWB file: $DwHeaderVersion"

# Timestamp
$XwbTimestampBytePosition = [uint32]"0x8c" # byte at position 0x8c (see Bible)
$XwbTimestampByteLength = 8 # 8 byte (see Bible)
$XwbTimestamp = (Get-Content $XwbFilePath -AsByteStream)[$XwbTimestampBytePosition..($XwbTimestampBytePosition+$XwbTimestampByteLength-1)]
Write-HostInfo -Text "Timestamp in original XWB header: $XwbTimestamp"

##### Build xwb file from wav #####
Write-HostInfo -Text "Build $XwbName with XWBTool version $DwVersion/$DwHeaderVersion."
if ($DwVersion -eq 45 -And $DwHeaderVersion -eq 43) {
    $buildXWB = .\XWBTool4543.exe -o $XwbName $NewWavesPath"\*.wav" -s -f -y # see XWBTool usage on Bible for details
}
elseif ($DwVersion -eq 46 -And $DwHeaderVersion -eq 44) {
    $buildXWB = .\XWBTool4644.exe -o $XwbName $NewWavesPath"\*.wav" -s -f -y
}
else {
    Write-HostError "There is something wrong with your XWBTool"
}

##### Change XWB timestamp in XWB header #####
[GPSTools]::ReplaceBytes($XwbName, $XwbTimestamp, $XwbTimestampByteLength, $XwbTimestampBytePosition)

########################################################################## TO BE TESTED
##### Move Speech.xwb to MISE folder #####
if (-not(Test-Path -Path $GameAudioPath"\"$XwbName".original" -PathType Leaf)) { # if the file does not exist, create a copy to *.original
     try {
         Rename-Item -Path $GameAudioPath"\"$XwbName -NewName $XwbName".original"
         Write-HostInfo -Text "File $XwbName.original created as copy of the original $XwbName."
     }
     catch {
         throw $_.Exception.Message
     }
 }
 else { # If the file already exists, show the message and do nothing.
     Write-HostInfo -Text "File $XwbName.original NOT created because it already exists."
 }
Copy-Item -Path $XwbName -Destination $GameAudioPath # Copy new Speech.xwb to MISE folder
#######################################################################################

##### Start the game #####
if ($RunGame) {
    Write-HostInfo -Text $GameName" is starting..."
    Start-Process -FilePath $GameExePath -WorkingDirectory $GameMasterPath -Wait
}
else {
    Write-HostInfo -Text "You chose not to start $GameName."
}
