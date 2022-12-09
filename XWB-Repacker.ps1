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

# other variables initiation
$header = "header.bin"
$CurrentXwb = $XwbFilePath.Split("\")[-1]

# Check existance of files and folders
Assert-FolderExists -Folder $NewWavesPath
Assert-FileExists -File $XwbFilePath
#Assert-FileExists -File $GameExePath # commented for developing and testing purposed. MUST BE ACTIVATED IN PRD
Assert-FolderExists -Folder $GameAudioPath

exit

##### Build xwb file from wav #####
Write-HostInfo -Text "Build"$CurrentXwb" with XWBTool version 43/45."
$buildXWB = .\XWBTool4543.exe -o $CurrentXwb $NewWavesPath"\*.wav" -s -f -y # see XWBTool4543 usage for details

##### Change header in hex #####
$numberOfBytes = 147
Write-HostInfo -Text "Get header from original $CurrentXwb and write to temporary header file $header."
Get-Content $XwbFilePath -AsByteStream -TotalCount $numberOfBytes | Set-Content -Path $header -AsByteStream
Write-HostInfo -Text "Change header of $CurrentXwb."
[GPSTools]::ReplaceBytes($XwbToolPath+"\"+$CurrentXwb, $XwbToolPath+"\"+$header, $numberOfBytes)
Write-HostInfo -Text "Remove temporary header file."
Remove-Item $header # work clean


########################################################################## TO BE TESTED
##### Move Speech.xwb to MISE folder #####
if (-not(Test-Path -Path $GameAudioPath"\"$CurrentXwb".original" -PathType Leaf)) { # if the file does not exist, create a copy to *.original
     try {
         Rename-Item -Path $GameAudioPath"\"$CurrentXwb -NewName $CurrentXwb".original"
         Write-HostInfo -Text "File $CurrentXwb.original created as copy of the original $CurrentXwb."
     }
     catch {
         throw $_.Exception.Message
     }
 }
 else { # If the file already exists, show the message and do nothing.
     Write-HostInfo -Text "File $CurrentXwb.original NOT created because it already exists."
 }
Copy-Item -Path $CurrentXwb -Destination $GameAudioPath # Copy new Speech.xwb to MISE folder
#######################################################################################

##### Start the game #####
if ($RunGame) {
    Write-HostInfo -Text $GameName" is starting..."
    Start-Process -FilePath $GameExePath -WorkingDirectory $GameMasterPath -Wait
}
else {
    Write-HostInfo -Text "You chose not to start $GameName."
}
