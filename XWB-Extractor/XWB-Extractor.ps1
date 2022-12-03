
# Change directory: place you "towav"-wav folder as next variable
# $toWavExtactionPath = "C:\MISE-ITA\DoppiaggioITA\audio estratto\con numero davanti (towav)"
$toWavExtactionPath = "D:\Progetti Personali\Monkey Island - Doppiaggio in italiano\audio estratto\MISE-ITA\DoppiaggioITA\audio estratto\con numero davanti (towav)"
Set-Location $toWavExtactionPath # cd path

Get-ChildItem . -Filter *.wav | ForEach-Object {
    $number = $_.Name.Split(" ")[0]
    Write-Host $number
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