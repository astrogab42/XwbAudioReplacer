##### Initialization #####
$runMISE = $false; #Do you want to run the game at the end of the script? $true/$false
$wavListFolder = "C:\MISE-ITA\MISE-ITA-Master\Dialoghi\Tracce-WAV"
$XWBToolFolder = ".\XWB-Extractor"
$Speechxwb = "Speech.xwb"
$header = "header.bin"
$SpeechxwbOriginal = "C:\MISE-ITA\MISE-ITA-Master\originalSpeechFiles\Speech.xwb"
$gameFolder = "C:\GOG Games\Monkey Island 1 SE"
$audioGameFolder = "C:\GOG Games\Monkey Island 1 SE\audio"
$MISE = "Monkey Island 1 - Special Edition"

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
if ($runMISE) {
    Write-Host $MISE" is starting..."
    Start-Process -FilePath "MISE.exe" -WorkingDirectory "C:\GOG Games\Monkey Island 1 SE" -Wait
}
else {
    Write-Host "You chose not to start $MISE."
}
