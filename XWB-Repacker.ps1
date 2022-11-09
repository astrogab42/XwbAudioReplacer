##### Initialization #####
$scriptName = "XWB-Repacker"
$configFile = ".\xwbrepacker.config" # config file
if (-not(Test-Path -Path $configFile -PathType Leaf)) { # if the file does not exist, create it.
    try {
        $null = New-Item -ItemType File -Path $configFile -Force -ErrorAction Stop
        Write-Host "The config file $configFile has been created."
        $initWindowsPrompt = $true

        # create configuration
        $runGame            =       $false; # do you want to run the game at the end of the script? $true/$false
        $runGame            >>      $configFile
        $wavListFolder      =       "C:\MISE-ITA\MISE-ITA-Master\Dialoghi\Tracce-WAV"
        $wavListFolder      >>      $configFile
        $XWBToolFolder      =       ".\XWB-Extractor"
        $XWBToolFolder      >>      $configFile
        $Speechxwb          =       "Speech.xwb"
        $Speechxwb          >>      $configFile
        $SpeechxwbOriginal  =       "C:\MISE-ITA\MISE-ITA-Master\originalSpeechFiles\Speech.xwb"
        $SpeechxwbOriginal  >>      $configFile
        $gameFolder         =       "C:\GOG Games\Monkey Island 1 SE"
        $gameFolder         >>      $configFile
        $audioGameFolder    =       "C:\GOG Games\Monkey Island 1 SE\audio"
        $audioGameFolder    >>      $configFile
        $gameName           =       $gameFolder.Split("\")[-1] # use game path to store game name
        $gameName           >>      $configFile
        $exeGame            =       "MISE.exe"
        $exeGame            >>      $configFile
    }
    catch {
        throw $_.Exception.Message
    }
}
else { # if the file already exists, show the message and do nothing.
    Write-Host "The config file already exists. This is the configuration:"
    Get-Content $configFile # show init file to the user

    $title   = "$scriptName Configuration"
    $msg     = "Do you want to change the configuration?"
    $options = "&Yes", "&No"
    $default = 1  # 0=Yes, 1=No

    do {
        $response = $Host.UI.PromptForChoice($title, $msg, $options, $default)
        if ($response -eq 0) {
            
    }
    } until ($response -eq 1)
}
$header = "header.bin"

### read content of $configFile


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
