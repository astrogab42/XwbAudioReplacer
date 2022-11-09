##########################
######## Functions #######
##########################
function Set-Configuration { # get and store configuration in config file

    param (
        $ConfigFile
    )

    # Get configuration
    $runGame                =       $false; # do you want to run the game at the end of the script? $true/$false
    $wavListFolder          =       "C:\MISE-ITA\MISE-ITA-Master\Dialoghi\Tracce-WAV"
    $XWBToolFolder          =       ".\XWB-Extractor"
    $SpeechxwbOriginal      =       "C:\MISE-ITA\MISE-ITA-Master\originalSpeechFiles\Speech.xwb"
    $gameFolder             =       "C:\GOG Games\Monkey Island 1 SE"
    $audioGameFolder        =       "C:\GOG Games\Monkey Island 1 SE\audio"
    $gameName               =       $gameFolder.Split("\")[-1] # use game path to store game name
    $exeGame                =       "MISE.exe"
    
    # Store configuration to file
    Add-Content -Path $configFile -Value $runGame, $wavListFolder, $XWBToolFolder, $SpeechxwbOriginal, $gameFolder, $audioGameFolder, $gameName, $exeGame
}

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
        $null = New-Item -ItemType File -Path $configFile -Force -ErrorAction Stop
        Write-Debug "The config file $configFile has been created."
        $initWindowsPrompt = $true

        Set-Configuration -ConfigFile $configFile # get and store configuration in config file
    }
    catch {
        throw $_.Exception.Message
    }
}
else { # if the file already exists, show the message and do nothing
    Write-Debug "The config file already exists."
}

# Store current configuration in variables for this script
$i = 0
$configTableVal = [string[]]::new((Get-Content $configFile).Length) # initiate the array
foreach($line in Get-Content $configFile) { # get config from file
    $configTableVal[$i] = $line
    $i++
}

if ($configTableVal -eq "False") {
    $runGame = $false
}
else {
    $runGame = $true
}
$wavListFolder = $configTableVal[1]
$XWBToolFolder = $configTableVal[2]
$SpeechxwbOriginal = $configTableVal[3]
$gameFolder = $configTableVal[4]
$audioGameFolder = $configTableVal[5]
$gameName = $configTableVal[6]
$exeGame = $configTableVal[7]

$configTableKey = @("runGame","wavListFolder","XWBToolFolder","SpeechxwbOriginal","gameFolder","audioGameFolder","gameName","exeGame")
[int]$max = $configTableKey.Count
$configTableId = 0..($max-1)
$configTable = for ($i = 0; $i -lt $max; $i++) {
    [PSCustomObject]@{
        ID = $configTableId[$i]
        Parameter = $configTableKey[$i]
        Value = $configTableVal[$i]
    }
}

# show config to user
Write-Information "This is your current configuration:"
$configTable | Format-Table


$title   = "" #"$scriptName Configuration"
$msg     = "Do you want to change the configuration?"
$options = "&Yes", "&No"
$default = 1  # 0=Yes, 1=No

do {
    $response = $Host.UI.PromptForChoice($title, $msg, $options, $default)
    if ($response -eq 0) {
        Write-Host "You chose Y"
}
} until ($response -eq 1)





$header = "header.bin"
$Speechxwb = "Speech.xwb"

### read content of $configFile



exit

##### .NET code #####
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

##### Build xwb file from wav #####
Write-Host "Change directory to XWBTool"
Set-Location $XWBToolFolder
Write-Host "Build"$Speechxwb" with XWBTool version 43/45."
$buildXWB = .\XWBTool4543.exe -o $Speechxwb $wavListFolder"\*.wav" -s -f -y # see XWBTool4543 usage for details

##### Change header in hex #####
$numberOfBytes = 147
Write-Host "Get header from original $Speechxwb and write to temporary header file $header."
Get-Content $SpeechxwbOriginal -AsByteStream -TotalCount $numberOfBytes | Set-Content -Path $header -AsByteStream
Write-Host "Change header of $Speechxwb."
[GPSTools]::ReplaceBytes($XWBToolFolder+"\"+$Speechxwb, $XWBToolFolder+"\"+$header, $numberOfBytes)
Write-Host "Remove temporary header file."
Remove-Item $header # work clean


########################################################################## TO BE TESTED
##### Move Speech.xwb to MISE folder #####
if (-not(Test-Path -Path $audioGameFolder"\"$Speechxwb".original" -PathType Leaf)) { # if the file does not exist, create a copy to *.original
     try {
         Rename-Item -Path $audioGameFolder"\"$Speechxwb -NewName $Speechxwb".original"
         Write-Host "File $Speechxwb.original created as copy of the original $Speechxwb."
     }
     catch {
         throw $_.Exception.Message
     }
 }
 else { # If the file already exists, show the message and do nothing.
     Write-Host "File $Speechxwb.original NOT created because it already exists."
 }
Copy-Item -Path $Speechxwb -Destination $audioGameFolder # Copy new Speech.xwb to MISE folder
#######################################################################################

##### Start the game #####
if ($runGame) {
    Write-Host $gameName" is starting..."
    Start-Process -FilePath $exeGame -WorkingDirectory "C:\GOG Games\Monkey Island 1 SE" -Wait
}
else {
    Write-Host "You chose not to start $gameName."
}
