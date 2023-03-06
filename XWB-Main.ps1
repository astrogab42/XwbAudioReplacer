########################################
################## MAIN ################
########################################

##########################
######## XWB info ########
##########################
##### Get info from XWB file #####
$ByteStreamLimit = 150 # Limit the number of bytes to speed up the process
$XwbHeader = Get-Content $XwbPath -AsByteStream -TotalCount $ByteStreamLimit # Get content of XWB file as stream of bytes (limit to $ByteStreamLimit)

# Tool version, aka dwVersion / XACT_CONTENT_VERSION
$DwVersionBytePosition = [uint32]"0x08" # Byte at position 0x08 (see Documentation)
$DwVersion = $XwbHeader[$DwVersionBytePosition] # Get byte in position $DwVersionBytePosition
Write-HostInfo -Text "dwVersion of original XWB file: $DwVersion"

# File format, aka dwHeaderVersion
$DwHeaderVersionBytePosition = [uint32]"0x04" # Byte at position 0x04 (see Documentation)
$DwHeaderVersion = $XwbHeader[$DwHeaderVersionBytePosition] # Get byte in position $DwHeaderVersionBytePosition
Write-HostInfo -Text "dwHeaderVersion of original XWB file: $DwHeaderVersion"

<# DEPRECATED
# Timestamp
$XwbTimestampBytePosition = [uint32]"0x8c" # byte at position 0x8c (see Documentation)
$XwbTimestampByteLength = 8 # 8 byte (see Documentation)
$XwbTimestamp = $XwbHeader[$XwbTimestampBytePosition..($XwbTimestampBytePosition + $XwbTimestampByteLength - 1)]
Write-HostInfo -Text "Timestamp in original XWB header: $XwbTimestamp"
#>

##### Preparation for xwb file built #####
# Repacker Folder (see Documentation)
if (-not(Test-Path -Path $RepackerFolderPath)) {
    # Create Repacker folder if it does not exist
    Write-HostInfo -Text "Creating Repacker folder: $RepackerFolderPath..."
    New-Item $RepackerFolderPath -ItemType Directory | Out-Null
}
else {
    Write-HostInfo -Text "Repacker Folder exists."
}


# Print info about folders
Write-HostInfo -Text "Original Folder: $OriginalWavPath. This folder contains the original WAV files extracted from original XWB file."
Write-HostInfo -Text "Dubbed Folder: $CustomWavPath. This folder contains the WAV files that has been dubbed."
Write-HostInfo -Text "Repacker Folder: $RepackerFolderPath. This folder contains the WAV files (original and/or dubbed) that will be packed into the new XWB file."

# Copy of original WAV files in Repacker folder
Write-HostInfo -Text "Construction of Repacker folder: $RepackerFolderPath with Robocopy..."
robocopy /xc /xn /xo $OriginalWavPath $RepackerFolderPath /if *.wav | Out-Null # Flags: /xc (eXclude Changed files) /xn (eXclude Newer files) /xo (eXclude Older files) /if (Include the following Files)

##########################
######## Dubbing #########
##########################
# Copy dubbed audio files from Dubbed folder to Repacker folder
$DubbedFileList = Get-ChildItem $CustomWavPath -Filter "*.wav" # Retrieve list of dubbed WAV files in Dubbed folder
$OriginalWavesList = Get-ChildItem $OriginalWavPath -Filter "*.wav" # Retrieve list of WAV files in Original folder
$RepackerWavesList = Get-ChildItem $RepackerFolderPath -Filter "*.wav" # Retrieve list of WAV files in Repacker folder
$DubbedFilesSizeError = "DubbedFilesError-Size-tmp.txt" # Temporary files to store errors
$DubbedFilesNameError = "DubbedFilesError-Name-tmp.txt"
$DubbedFilesDateError = "DubbedFilesError-Date-tmp.txt"
ForEach ($DubbedFile in $DubbedFileList) {
    if ($OriginalWavesList.Name.Contains($DubbedFile.Name)) {
        # The dubbed file exists among the original ones
        $ID = [uint32]($DubbedFile.Name.Split("_")[0]) # Take the ID (aka number of the file) as number (int32)
        if ($DubbedFile.Length -le $OriginalWavesList[$ID - 1].Length) {
            # Use the ID to get the corresponding file in Repacker folder and compare file size
            if (-not($DubbedFile.LastWriteTime -eq $OriginalWavesList[$ID - 1].LastWriteTime)) {
                # Files do not have the same LastWriteDate, i.e. they are not the same file (optimization check)
                <# FOR OPTIMIZATION
                Write-HostInfo "Copying dubbed file $DubbedFile to Repacker folder $RepackerFolderPath..."
                #>
                robocopy $CustomWavPath $RepackerFolderPath $DubbedFile.Name # Perform the copy and display a summary to the user
            }
            <# FOR OPTIMIZATION
            else {
                Write-HostWarn -Text "File dubbed file $DubbedFile already copied."
                Write-HostInfo "Storing log to file $DubbedFilesDateError..."
                $DubbedFile.Name >> $DubbedFilesDateError
                Write-HostInfo "The script will continue"
                continue
            }
            #>
        }
        else {
            $LengthDelta = $DubbedFile.Length - $OriginalWavesList[$ID - 1].Length # Size difference in byte
            Write-HostWarn "The size of file $($DubbedFile.Name) is greater than the original one's by $LengthDelta byte."
            Write-HostInfo "Storing log to file $DubbedFilesSizeError..."
            $DubbedFile.Name >> $DubbedFilesSizeError
            Write-HostInfo "The script will continue"
            continue
        }
    }
    else {
        Write-HostWarn "The dubbed file $($DubbedFile.Name) has a wrong name."
        Write-HostInfo "Storing log to file $DubbedFilesNameError..."
        $DubbedFile.Name >> $DubbedFilesNameError
        Write-HostInfo "The script will continue"
        continue
    }
}

##### Clean and reorder files in error #####
$DubbedFilesSizeErrorFinal = "DubbedFilesError-Size.txt"
$DubbedFilesNameErrorFinal = "DubbedFilesError-Name.txt"
$DubbedFilesDateErrorFinal = "DubbedFilesError-Date.txt"

if (Test-Path -Path $DubbedFilesSizeError) {
    # If tmp file exists, sort by name and make the list disting (unique)
    Get-Content $DubbedFilesSizeError | Sort-Object | Get-Unique > $DubbedFilesSizeErrorFinal
}
if (Test-Path -Path $DubbedFilesNameError) {
    Get-Content $DubbedFilesNameError | Sort-Object | Get-Unique > $DubbedFilesNameErrorFinal
}
if (Test-Path -Path $DubbedFilesDateError) {
    Get-Content $DubbedFilesDateError | Sort-Object | Get-Unique > $DubbedFilesDateErrorFinal
}

# Display to the user how to use error log files
Write-HostInfo -Text "Check $DubbedFilesSizeErrorFinal for files with wrong size.
`tCheck $DubbedFilesNameErrorFinal for files with wrong name.
`tCheck $DubbedFilesDateErrorFinal for files already copied, with the same last-write date."

##########################
###### Build new XWB #####
##########################
##### Build xwb file from WAV #####
Write-HostInfo -Text "Building $XwbName with XWBTool version $DwVersion/$DwHeaderVersion..."
$buildXWB = .\XWBTool_GPS.exe -o $XwbName -tv $DwVersion -fv $DwHeaderVersion -s -f -y "$RepackerFolderPath\*.wav" # see XWBTool usage on Documentation for details
$XwbToolOutputLogTailLinesNumber = 1 # How many lines at the end of the output in XwbTool log
$NumberOfFileElaboratedByXwbTool = $buildXWB.Length - $XwbToolOutputLogHeadLinesNumber - $XwbToolOutputLogTailLinesNumber
$NumberOfFilesInRepackerFolder = $RepackerWavesList.Length
if ($NumberOfFileElaboratedByXwbTool -lt $NumberOfFilesInRepackerFolder) {
    # In case we have less files elaborated by XwbTool w.r.t. the number of WAV files in Repacker Folder
    Write-HostError "XwbTool elaborated $NumberOfFileElaboratedByXwbTool files, whilst the Repacker Folder contains $NumberOfFilesInRepackerFolder files!"
    Write-HostError "Fatal Error! Exiting..."
    exit
}

##### Update XWB Header #####
$XwbHeader | Set-Content -Path $Header -AsByteStream # Save header to temporary binary file
[GPSTools]::ReplaceBytes($XwbName, $Header, $ByteStreamLimit) # Substitute the first $ByteStreamLimit bytes in the brand-new $XwbName file in current folder
<# DEPRECATED
# Specific change of "timestamp" in header
$XwbTimestamp | Set-Content -Path $Header -AsByteStream # Save header to temporary binary file
[GPSTools]::ReplaceBytes($XwbName, $XwbTimestamp, $XwbTimestampByteLength, $XwbTimestampBytePosition)
#>
Remove-Item $Header # Delete temporary binary file

##########################
######### Outtro #########
##########################
##### Move XWB file to game folder #####
if (-not(Test-Path -Path $GameAudioPath"\"$XwbName".original" -PathType Leaf)) {
    # Create a backup of the original XWB file (adding ".original" at the end of the filename) if not already done
    Rename-Item -Path $GameAudioPath"\"$XwbName -NewName $XwbName".original"
    Write-HostInfo -Text "File $XwbName (assumed to be The Original) renamed in $XwbName.original."
}
else {
        # If the backup of the original XWB file already exists, show the message and do nothing
        Write-HostInfo -Text "File $XwbName.original NOT created because it already exists."
}
Move-Item -Path $XwbName -Destination $GameAudioPath -Force # Copy rebuilt XWB file to game folder


##### Run the game #####
if ($RunGame) {
    # Run the game only if it is set so in the configuration
    Write-HostInfo -Text $GameName" is starting..."
    Start-Process -FilePath $GameExePath -WorkingDirectory "C:\GOG Games\Monkey Island 1 SE" -Wait
}
else {
    Write-HostInfo -Text "You chose not to start $GameName."
}
