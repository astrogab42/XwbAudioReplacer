
# Change directory: place you "towav"-wav folder as next variable
$ToWavOutputFolder = "C:\MISE-ITA\MISE-ITA-Master\Dialoghi\Tracce-WAV"


<#
Sezione dedicata a towav.exe per estrazione wav da XWB file originale
#>


$fileList = Get-ChildItem $ToWavOutputFolder -Filter *.wav
ForEach ($thisFile in $fileList.Name) {
    $number = $thisFile.Split(" ")[0]
    $wavName = $thisFile.Split(" ")[1] # Assumption: towav.exe output file name is as "<number> filename.wav"
    
    if ($thisFile.Split(" ").Length -gt 1) { #If there are no spaces in file name (file name already renamed)
        if ($number.ToString().Length -eq 1) {
            Rename-Item -Path $ToWavOutputFolder"\"$thisFile -NewName ("0000" + $number + "_" + $wavName)
        }
        elseif ($number.ToString().Length -eq 2) {
            Rename-Item -Path $ToWavOutputFolder"\"$thisFile -NewName ("000" + $number + "_" + $wavName)
        }
        elseif ($number.ToString().Length -eq 3) {
            Rename-Item -Path $ToWavOutputFolder"\"$thisFile -NewName ("00" + $number + "_" + $wavName)
        }
        elseif ($number.ToString().Length -eq 4) {
            Rename-Item -Path $ToWavOutputFolder"\"$thisFile -NewName ("0" + $number + "_" + $wavName)
        }
        else {
            Rename-Item -Path $ToWavOutputFolder"\"$thisFile -NewName ($number + "_" + $wavName)
        }
    }
}
