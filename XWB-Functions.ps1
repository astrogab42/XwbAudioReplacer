##########################
######## Functions #######
##########################

# Basic logging
function Write-HostError {
    param (
        $Text
    )
    Write-Host "ERROR`t$Text" -ForegroundColor red
}

function Write-HostWarn {
    param (
        $Text
    )
    Write-Host "WARN`t$Text" -ForegroundColor yellow
}

function Write-HostInfo {
    param (
        $Text
    )
    Write-Host "INFO`t$Text" # -ForegroundColor blue
}

# check folder existance and ask user to or not to create it
function Assert-FolderExists {
    param (
        $Folder
    )

    if (-not(Test-Path $Folder)) { # if the folder does not exists
        Write-HostWarn -Text "The path you selected does not exists."
        Write-HostInfo -Text "Path: $Folder" 
        
        $title   = "" #"$scriptName Configuration"
        $msg     = "Do you want to create it?"
        $options = "&Yes", "&No"
        $default = 1  # 0=Yes, 1=No
        do {
            $response = $Host.UI.PromptForChoice($title, $msg, $options, $default)
            if ($response -eq 0) {
                Write-HostInfo -Text "Creating new folder..."
                New-Item -Path $Folder -ItemType directory
            }
            else {
                Write-HostError -Text "It is impossibile to continue. The script will be stopped."
                exit
            }
        } until ($response -eq $default -Or (Test-Path $Folder))

    }
}

# check file existance 
function Assert-FileExists {
    param (
        $File
    )

    if (-not(Test-Path $File)) { # if the file does not exists
        Write-HostWarn -Text "The path you selected for you file does not exists."
        Write-HostInfo -Text "Path: $File"
        
        Write-HostError -Text "It is impossibile to continue. The script will be stopped."
        exit
    }
}

# get and store configuration in config file
function Set-Configuration {
    param (
        $ConfigFile
    )

    # Get configuration
    $runGame                =       $false; # do you want to run the game at the end of the script? $true/$false
    $wavListFolder          =       "C:\MISE-ITA\MISE-ITA-Master\Dialoghi\Tracce-WAV"
    $XWBToolFolder          =       ".\XWB-Extractor"
    $SpeechxwbOriginal      =       "C:\MISE-ITA\MISE-ITA-Master\originalSpeechFiles\Speech.xwb"
    $gameFolder             =       "C:\GOG Games\Monkey Island 1 SE"
    $audioGameFolder        =       "C:\GOG Games\Monkey Island 1 SE\audio"
    ######### andrebbe rimosso per pulizia
    $gameName               =       $gameFolder.Split("\")[-1] # use game path to store game name
    ######### andrebbe rimosso per pulizia
    $exeGame                =       "MISE.exe"
    
    # Store configuration to file
    Add-Content -Path $configFile -Value $runGame, $wavListFolder, $XWBToolFolder, $SpeechxwbOriginal, $gameFolder, $audioGameFolder, $gameName, $exeGame
}

# edit config file
function Edit-Configuration {
    param (
        $ConfigKey,
        $ConfigFile,
        [int16]$Index
    )

    if ($ConfigKey -eq "runGame") { # specific case to match true/false values
        do {
            $prompt = Read-Host "What is the new value? [True/False]" # prompt user to insert new value from keyboard 
        } until ($prompt -eq "True" -Or $prompt -eq "False")

        if ($prompt -eq "False") {
            $output = $false
        }
        else {
            $output = $true
        }
        
    }
    else {
        $output = Read-Host "Please, enter the new value" # prompt user to insert new value from keyboard
    }

    $content = Get-Content $ConfigFile # Get file content and store it into variable
    $content[$Index-1] = $output # Replace the line number 0 by a new text
    $content | Set-Content $ConfigFile # Set the new content

    return $output
}

# build config table
function Build-ConfigTable {
    param (
        [int16[]]$TableId,
        [string[]]$TableKey,
        [string[]]$TableVal
    )

    $configTable = for ($i = 0; $i -lt $max; $i++) {
        [PSCustomObject]@{
            ID = $TableId[$i]
            Parameter = $TableKey[$i]
            Value = $TableVal[$i]
        }
    }

    return $configTable
}
