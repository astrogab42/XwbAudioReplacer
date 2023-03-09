########################################
################## MAIN ################
########################################

function Add-AllCustomSoundFiles {
    param (
        $XwbPath,
        $RepackerFolderPath,
        $OriginalWavPath,
        $CustomWavPath,
        $XwbName,
        $Header,
        $GameAudioPath,
        $GameName,
        $GameExePath,
        $RunGame
    )

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
    Write-HostInfo -Text "Custom Folder: $CustomWavPath. This folder contains the WAV files that has been customized."
    Write-HostInfo -Text "Repacker Folder: $RepackerFolderPath. This folder contains the WAV files (original and/or custom) that will be packed into the new XWB file."

    # Copy of original WAV files in Repacker folder
    Write-HostInfo -Text "Construction of Repacker folder: $RepackerFolderPath with Robocopy..."
    robocopy /xc /xn /xo $OriginalWavPath $RepackerFolderPath /if *.wav | Out-Null # Flags: /xc (eXclude Changed files) /xn (eXclude Newer files) /xo (eXclude Older files) /if (Include the following Files)

    ################################
    ######## Customization #########
    ################################
    # Copy custom audio files from Custom folder to Repacker folder
    $CustomFileList = Get-ChildItem $CustomWavPath -Filter "*.wav" # Retrieve list of custom WAV files in Custom folder
    $OriginalWavesList = Get-ChildItem $OriginalWavPath -Filter "*.wav" # Retrieve list of WAV files in Original folder
    $RepackerWavesList = Get-ChildItem $RepackerFolderPath -Filter "*.wav" # Retrieve list of WAV files in Repacker folder
    $CustomFilesSizeError = "Log-CustomFilesError-Size-tmp.txt" # Temporary files to store errors
    $CustomFilesNameError = "Log-CustomFilesError-Name-tmp.txt"
    $CustomFilesDateError = "Log-CustomFilesError-Date-tmp.txt"
    ForEach ($CustomFile in $CustomFileList) {
        if ($OriginalWavesList.Name.Contains($CustomFile.Name)) {
            # The custom file exists among the original ones
            $ID = [uint32]($CustomFile.Name.Split("_")[0]) # Take the ID (aka number of the file) as number (int32)
            if ($CustomFile.Length -le $OriginalWavesList[$ID - 1].Length) {
                # Use the ID to get the corresponding file in Repacker folder and compare file size
                if (-not($CustomFile.LastWriteTime -eq $OriginalWavesList[$ID - 1].LastWriteTime)) {
                    # Files do not have the same LastWriteDate, i.e. they are not the same file (optimization check)
                    <# FOR OPTIMIZATION
                    Write-HostInfo "Copying custom file $CustomFile to Repacker folder $RepackerFolderPath..."
                    #>
                    robocopy $CustomWavPath $RepackerFolderPath $CustomFile.Name # Perform the copy and display a summary to the user
                }
                <# FOR OPTIMIZATION
                else {
                    Write-HostWarn -Text "Custom file $CustomFile already copied."
                    Write-HostInfo "Storing log to file $CustomFilesDateError..."
                    $CustomFile.Name >> $CustomFilesDateError
                    Write-HostInfo "The script will continue"
                    continue
                }
                #>
            }
            else {
                $LengthDelta = $CustomFile.Length - $OriginalWavesList[$ID - 1].Length # Size difference in byte
                Write-HostWarn "The size of file $($CustomFile.Name) is greater than the original one's by $LengthDelta byte."
                Write-HostInfo "Storing log to file $CustomFilesSizeError..."
                $CustomFile.Name >> $CustomFilesSizeError
                Write-HostInfo "The script will continue"
                continue
            }
        }
        else {
            Write-HostWarn "The custom file $($CustomFile.Name) has a wrong name."
            Write-HostInfo "Storing log to file $CustomFilesNameError..."
            $CustomFile.Name >> $CustomFilesNameError
            Write-HostInfo "The script will continue"
            continue
        }
    }

    ##### Clean and reorder files in error #####
    $DubbedFilesSizeErrorFinal = "Log-CustomFilesError-Size.txt"
    $DubbedFilesNameErrorFinal = "Log-CustomFilesError-Name.txt"
    $DubbedFilesDateErrorFinal = "Log-CustomFilesError-Date.txt"

    if (Test-Path -Path $CustomFilesSizeError) {
        # If tmp file exists, sort by name and make the list disting (unique)
        Get-Content $CustomFilesSizeError | Sort-Object | Get-Unique > $DubbedFilesSizeErrorFinal
        # Display to the user how to use error log files
        Write-HostWarn -Text "Check $DubbedFilesSizeErrorFinal for files with wrong size."
    }
    if (Test-Path -Path $CustomFilesNameError) {
        Get-Content $CustomFilesNameError | Sort-Object | Get-Unique > $DubbedFilesNameErrorFinal
        Write-HostWarn -Text "Check $DubbedFilesNameErrorFinal for files with wrong name."
    }
    if (Test-Path -Path $CustomFilesDateError) {
        Get-Content $CustomFilesDateError | Sort-Object | Get-Unique > $DubbedFilesDateErrorFinal
        Write-HostWarn -Text "Check $DubbedFilesDateErrorFinal for files already copied, with the same last-write date."
    }

    # Work clean
    if (Test-Path -Path $CustomFilesSizeError) {
        # If tmp file exists, delete it
        Remove-Item $CustomFilesSizeError
    }
    if (Test-Path -Path $CustomFilesNameError) {
        Remove-Item $CustomFilesNameError
    }
    if (Test-Path -Path $CustomFilesDateError) {
        Remove-Item $CustomFilesDateError
    }

    ##########################
    ###### Build new XWB #####
    ##########################
    ##### Build xwb file from WAV #####
    Write-HostInfo -Text "Building $XwbName with XWBTool version $DwVersion/$DwHeaderVersion..."
    $buildXWB = .\XWBTool_GPS.exe -o $XwbName -tv $DwVersion -fv $DwHeaderVersion -s -f -y "$RepackerFolderPath\*.wav" # see XWBTool usage on Documentation for details
    $XwbToolOutputLogHeadLinesNumber = 0 # How many lines at the beginning of the output in XwbTool log
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

}

