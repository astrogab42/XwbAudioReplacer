##### INITIALIZATION #####
# Include external functions
. (PowerShell -Command "Get-ChildItem -Path '.\' -Filter 'XWB-Tools.ps1' -Recurse | Select-Object -ExpandProperty FullName | Resolve-Path -Relative")
# Welcome Message
Set-WelcomeMessage -ScriptName "XWB-Extractor"

##### CONFIGURATION #####
# XWB File
Write-HostInfo -Text "Provide the XWB file you want to extract."
$xwbInputFile = (Read-Host "Please, enter the path to the XWB file").Replace("`"", "") # Prompt user to insert new value from keyboard
$Output = Assert-FileExists -File $xwbInputFile
if (-not($Output)) {
    exit
}

# Destination folder for extraction
Write-HostInfo -Text "Now, provide the folder where you want to save the extracted WAV files. The folder MUST be empty."
$wavOutputFolder = (Read-Host "Please, enter the path to the folder where to extract the wav files").Replace("`"", "") # Prompt user to insert new value from keyboard
$Output = Assert-FolderExists -Folder $wavOutputFolder
if (-not($Output)) {
    Write-HostInfo -Text "The folder does not exist."
    $Title = ""
    $Message = "Do you want to create it?"
    $Options = "&Yes", "&No"
    $Default = 1  # 0=Yes, 1=No
    do {
        $Response = $Host.UI.PromptForChoice($Title, $Message, $Options, $Default)
        if ($Response -eq 0) {
            Write-HostInfo -Text "Creating new folder..."
            New-Item -Path $wavOutputFolder -ItemType Directory
        }
        else {
            Write-HostError -Text "It is impossibile to continue. The script will be stopped."
            exit
        }
    } until ($Response -eq $Default -Or (Test-Path $wavOutputFolder))
}
if (-not((Get-ChildItem $wavOutputFolder | Measure-Object).Count -eq 0)) {
    # if the folder is not empty
    Write-HostError -Text "The destination folder is not empty. The extractor could have been already executed or the specified output folder is use for other purposes."
    Write-HostInfo -Text "Hint! Remember that you can use option R in XWB-Repacker to restore the original XWB file"
    exit
}
##### MAIN #####
# extract wav from xwb
Write-HostInfo "Extracting WAV files from XWB file"
& (PowerShell -Command "Get-ChildItem -Path '.\' -Filter 'towav.exe' -Recurse | Select-Object -ExpandProperty FullName | Resolve-Path -Relative") $xwbInputFile | Out-Null
# Check if any file with the pattern exists in the current directory
if (Test-Path -Path "*.wav") {
    # Get all .wav files in the current directory
    $files = Get-ChildItem -Path . -Filter *.wav
    # Count the number of .wav files
    $fileCount = $files.Count
    # Output the count
    Write-HostInfo -Text "Number of extracted files is $fileCount"

} else {
    Write-HostError -Text "It seems like that the XWB file $xwbInputFile does not contain any WAV files."
    Write-HostInfo -Text "Please, check its content with an external tool [suggestion will be provided in future releases]"
    exit
}
Write-HostInfo "Moving WAV files to destination folder $wavOutputFolder"
Move-Item *.wav $wavOutputFolder

# Rename files
Write-HostInfo "Renaming WAV files"
$fileList = Get-ChildItem $wavOutputFolder -Filter *.wav
ForEach ($thisFile in $fileList.Name) {
    $number = $thisFile.Split(" ")[0]
    $wavName = $thisFile.Split(" ")[-1] # Assumption: towav.exe output file name is as "<number> filename.wav"
    
    if ($thisFile.Split(" ").Length -gt 1) {
        #If there are no spaces in file name (file name already renamed)
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
Write-HostInfo -Text "Extraction completed!"
