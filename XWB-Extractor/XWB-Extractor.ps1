
# Change directory: place you "towav"-wav folder as next variable
### GAB ###
$inputFolder = "C:\MISE-ITA\DoppiaggioITA\traccewav" #input
### STEVE ###
# $toWavExtactionPath = "D:\Progetti Personali\Monkey Island - Doppiaggio in italiano\audio estratto\MISE-ITA\DoppiaggioITA\audio estratto\con numero davanti (towav)"

$renamedFolder = "C:\MISE-ITA\MISE-ITA-Master\Dialoghi\Tracce-WAV" #output
# Set-Location $toWavExtactionPath # cd path

$fileList = Get-ChildItem $inputFolder -Filter *.wav
$fileName = [string[]]::new($fileList.Length) # initiate the array
ForEach ($thisFile in $fileList.Name) {
    $number = $thisFile.Split(" ")[0]
    #$newFileName = $number
    exit
}

<#
foreach file presente nella cartella {
    if nome del file soddisfa "(\d+)+\s(.*.wav)"{ //subpattern 1 = numero iniziale, subpattern 2 = nome file senza numero iniziale
       if subpattern1 ha una cifra
          rinomina in ("0000" + subpattern1 + "_" + subpattern2)
       if subpattern1 ha 2 cifre...
       if subpattern1 ha 3 cifre...
       if subpattern1 ha 4 cifre...
 }
#>

<#
Get-ChildItem . -Filter *.wav | ForEach-Object {
    $CurrentFile = $_
    ForEach ($wavNewName in $wavNewNameList) {
        if ($CurrentFile.Name -ilike $wavNewName.originalName) {
            Rename-Item $CurrentFile.Name $wavNewName.finalName
            Write-Host "Renaming " $CurrentFile " with " $wavNewName "..."
            Write-Host "File renamed!"
            Write-Host "##########"
        }
    }
}
#>