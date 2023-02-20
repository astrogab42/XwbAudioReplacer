$InputFolder = "C:\repository\XWB-DUBKIT\RepackerFolder"
$OutputFolder = "D:\Progetti Personali\Monkey Island - Doppiaggio in italiano\xwb-dubkit test\audio doppiato"

$FakeWavPath = "D:\Progetti Personali\Monkey Island - Doppiaggio in italiano\xwb-dubkit test\gnignigni.wav"

$InputList = Get-ChildItem $InputFolder -Filter "*.wav"
foreach ($File in $InputList) {
    $FileName = $File.Name
    Copy-Item -Path $FakeWavPath -Destination $OutputFolder"\"$FileName
}
