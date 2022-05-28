

# Change directory: place you "towav"-wav folder as next variable
$toWavExtactionPath = "C:\MISE-ITA\DoppiaggioITA\audio estratto\con numero davanti (towav)"
Set-Location $toWavExtactionPath # cd path

# WAV file list with new names
$wavNewNameList = Import-Csv "C:\MISE-ITA\DoppiaggioITA\audio estratto\ListaWavNames.csv"

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