

$InputFolder = "C:\MISE-ITA\MISE-ITA-Master\Dialoghi\Tracce-WAV"
$OutputFolder = "C:\MISE-ITA\MISE-ITA-Master\Dialoghi\Dubbed-Folder"

$FakeWavPath = "C:\MISE-ITA\MISE-ITA-Master\Dialoghi\bbb.wav"

$InputList = Get-ChildItem $InputFolder -Filter "*.wav"
foreach ($File in $InputList) {
    $FileName = $File.Name
    Copy-Item -Path $FakeWavPath -Destination $OutputFolder"\"$FileName
}
