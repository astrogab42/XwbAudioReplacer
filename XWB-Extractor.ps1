Write-Host "Welcome to XWB-Extractor!" -ForegroundColor blue

##### INITIALIZATION #####
# Include external functions
. ".\XWB-Tools.ps1"

# Configuration
$wavOutputFolder = "C:\MISE-ITA\MISE-ITA-Master\Dialoghi\Tracce-WAV" # Folder that will be filled with extraction of wav files
$Output = Assert-FolderExists -Folder $wavOutputFolder
if (-not($Output)) {
    exit
}

$xwbInputFile = "C:\GOG Games\Monkey Island 1 SE\audio\Speech.xwb" # Path to XWB file
Assert-FileExists -File $xwbInputFile
if (-not($Output)) {
    exit
}

# extract wav from xwb
Write-HostInfo "Extracting WAV files from XWB file"
.\towav.exe $xwbInputFile | Out-Null
Write-HostInfo "Moving WAV files to destination folder $wavOutputFolder"
Move-Item *.wav $wavOutputFolder

# Rename files
Write-HostInfo "Renaming WAV files"
$fileList = Get-ChildItem $wavOutputFolder -Filter *.wav
ForEach ($thisFile in $fileList.Name) {
    $number = $thisFile.Split(" ")[0]
    $wavName = $thisFile.Split(" ")[-1] # Assumption: towav.exe output file name is as "<number> filename.wav"
    
    if ($thisFile.Split(" ").Length -gt 1) { #If there are no spaces in file name (file name already renamed)
        if ($number.ToString().Length -eq 1) {
            Rename-Item -Path $wavOutputFolder"\"$thisFile -NewName ("0000" + $number + "_" + $wavName)
        }
        elseif ($number.ToString().Length -eq 2) {
            Rename-Item -Path $wavOutputFolder"\"$thisFile -NewName ("000" + $number + "_" + $wavName)
        }
        elseif ($number.ToString().Length -eq 3) {
            Rename-Item -Path $wavOutputFolder"\"$thisFile -NewName ("00" + $number + "_" + $wavName)
        }
        elseif ($number.ToString().Length -eq 4) {
            Rename-Item -Path $wavOutputFolder"\"$thisFile -NewName ("0" + $number + "_" + $wavName)
        }
        else {
            Rename-Item -Path $wavOutputFolder"\"$thisFile -NewName ($number + "_" + $wavName)
        }
    }
}
