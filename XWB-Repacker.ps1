##########################
######## Functions #######
##########################

# get and store configuration in config file
function Set-Configuration {
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
    ######### andrebbe rimosso per pulizia
    $gameName               =       $gameFolder.Split("\")[-1] # use game path to store game name
    ######### andrebbe rimosso per pulizia
    $exeGame                =       "MISE.exe"
    
    # Store configuration to file
    Add-Content -Path $configFile -Value $runGame, $wavListFolder, $XWBToolFolder, $SpeechxwbOriginal, $gameFolder, $audioGameFolder, $gameName, $exeGame
}


# edit config file
function Edit-Configuration {
    param (
        $ConfigKey,
        $ConfigFile,
        [int16]$Index
    )

    if ($ConfigKey -eq "runGame") { # specific case to match true/false values
        do {
            $prompt = Read-Host "What is the new value? [True/False]" # prompt user to insert new value from keyboard 
        } until ($prompt -eq "True" -Or $prompt -eq "False")

        if ($prompt -eq "False") {
            $output = $false
        }
        else {
            $output = $true
        }
        
    }
    else {
        $output = Read-Host "Please, enter the new value" # prompt user to insert new value from keyboard
    }

    $content = Get-Content $ConfigFile # Get file content and store it into variable
    $content[$Index-1] = $output # Replace the line number 0 by a new text
    $content | Set-Content $ConfigFile # Set the new content

    return $output
}

function Build-ConfigTable {
    param (
        [int16[]]$TableId,
        [string[]]$TableKey,
        [string[]]$TableVal
    )

    $configTable = for ($i = 0; $i -lt $max; $i++) {
        [PSCustomObject]@{
            ID = $TableId[$i]
            Parameter = $TableKey[$i]
            Value = $TableVal[$i]
        }
    }

    return $configTable
}

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
        Write-Host "The config file $configFile does not exists. Creating..."
        $null = New-Item -ItemType File -Path $configFile -Force -ErrorAction Stop
        Write-Host "The config file $configFile has been created."
        $initWindowsPrompt = $true

        Set-Configuration -ConfigFile $configFile # get and store configuration in config file
    }
    catch {
        throw $_.Exception.Message
    }
}
else { # if the file already exists, show the message and do nothing
    Write-Host "The config file already exists."
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
$configTableId = 1..$max
$configTable = Build-ConfigTable -TableId $configTableId -TableKey $configTableKey -TableVal $configTableVal

# show config to user
Write-Host "This is your current configuration:"
$configTable | Format-Table

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
        $options = "&Cancel", "&1", "&2", "&3", "&4", "&5", "&6", "&7", "&8"
        $default = 0  # 0=Cancel

        do {
            $response = $Host.UI.PromptForChoice($title, $msg, $options, $default)
            switch ($response) {
                1 {$runGame = $configTableVal[0] = Edit-Configuration -ConfigKey "runGame" -ConfigFile $configFile -Index 1} # see custom function above
                2 {$wavListFolder = $configTableVal[1] = Edit-Configuration -ConfigKey "wavListFolder" -ConfigFile $configFile -Index 2}
                3 {$XWBToolFolder = $configTableVal[2] = Edit-Configuration -ConfigKey "XWBToolFolder" -ConfigFile $configFile -Index 3}
                4 {$SpeechxwbOriginal = $configTableVal[3] = Edit-Configuration -ConfigKey "SpeechxwbOriginal" -ConfigFile $configFile -Index 4}
                5 {$gameFolder = $configTableVal[4] = Edit-Configuration -ConfigKey "gameFolder" -ConfigFile $configFile -Index 5}
                6 {$audioGameFolder = $configTableVal[5] = Edit-Configuration -ConfigKey "audioGameFolder" -ConfigFile $configFile -Index 6}
                7 {$gameName = $configTableVal[6] = Edit-Configuration -ConfigKey "gameName" -ConfigFile $configFile -Index 7}
                8 {$exeGame = $configTableVal[7] = Edit-Configuration -ConfigKey "exeGame" -ConfigFile $configFile -Index 8}
            }
        } until ($response -eq $default)
    }
} until ($response -eq $default)

$configTable = Build-ConfigTable -TableId $configTableId -TableKey $configTableKey -TableVal $configTableVal
Write-Host "This is your new configuration:"
$configTable | Format-Table

# other variables initiation
$header = "header.bin"
$Speechxwb = $SpeechxwbOriginal.Split("\")[-1]

exit

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
