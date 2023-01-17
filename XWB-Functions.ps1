##########################
######## Functions #######
##########################

# Basic logging
function Write-HostError {
    param (
        $Text
    )
    Write-Host "ERROR`t$Text" -ForegroundColor Red
}

function Write-HostWarn {
    param (
        $Text
    )
    Write-Host "WARN`t$Text" -ForegroundColor Yellow
}

function Write-HostInfo {
    param (
        $Text
    )
    Write-Host "INFO`t$Text" # -ForegroundColor Blue
}

# Check folder existance and ask user to or not to create it
function Assert-FolderExists {
    param (
        $Folder
    )

    Write-HostInfo -Text "Check existance of $Folder."
    if (-not(Test-Path $Folder)) {
        # if the folder does not exists
        Write-HostWarn -Text "The path you selected does not exists."
        Write-HostInfo -Text "Path: $Folder" 
        
        $Title = ""
        $Message = "Do you want to create it?"
        $Options = "&Yes", "&No"
        $Default = 1  # 0=Yes, 1=No
        do {
            $Response = $Host.UI.PromptForChoice($Title, $Message, $Options, $Default)
            if ($Response -eq 0) {
                Write-HostInfo -Text "Creating new folder..."
                New-Item -Path $Folder -ItemType Directory
            }
            else {
                Write-HostError -Text "It is impossibile to continue. The script will be stopped."
                exit
            }
        } until ($Response -eq $Default -Or (Test-Path $Folder))

    }
    else {
        Write-HostInfo -Text "$Folder exists!"
    }
}

# Check file existance 
function Assert-FileExists {
    param (
        $File
    )

    Write-HostInfo -Text "Check existance of $File"
    if (-not(Test-Path $File)) {
        # if the file does not exists
        Write-HostWarn -Text "The path you selected for you file does not exists."
        Write-HostInfo -Text "Path: $File"
        
        Write-HostError -Text "It is impossibile to continue. The script will be stopped."
        exit
    }
    else {
        Write-HostInfo -Text "$File exists!"
    }
}

# Edit config file
function Edit-Configuration {
    param (
        $ConfigKey,
        $ConfigFile,
        [int16]$Index
    )

    if ($ConfigKey -eq "RunGame") {
        # Specific case to match true/false values
        do {
            $Prompt = Read-Host "What is the new value? [True/False]" # Prompt user to insert new value from keyboard 
        } until ($Prompt -eq "True" -Or $Prompt -eq "False")

        if ($Prompt -eq "False") {
            $Output = $false
        }
        else {
            $Output = $true
        }
        
    }
    elseif ($ConfigKey -eq "DeleteModeWaves") {
        # specific case to match true/false values
        do {
            $Prompt = Read-Host "What is the new value? [True/False]" # Prompt user to insert new value from keyboard 
        } until ($Prompt -eq "True" -Or $Prompt -eq "False")

        if ($Prompt -eq "False") {
            $Output = $false
        }
        else {
            $Output = $true
        }
        
    }
    else {
        $Output = (Read-Host "Please, enter the new value:").Replace("`"", "") # Prompt user to insert new value from keyboard
    }

    $Content = Get-Content $ConfigFile # Get file content and store it into variable
    $Content[$Index - 1] = $Output # Replace the line number 0 by a new text
    $Content | Set-Content $ConfigFile # Set the new content

    return $Output
}

# Build config table to be shown the user on screen
function Build-ConfigTable {
    param (
        [int16[]]$TableId,
        [string[]]$TableKey,
        [string[]]$TableVal
    )

    $ConfigTable = for ($i = 0; $i -lt $max; $i++) {
        [PSCustomObject]@{
            ID        = $TableId[$i]
            Parameter = $TableKey[$i]
            Value     = $TableVal[$i]
        }
    }

    return $ConfigTable
}
