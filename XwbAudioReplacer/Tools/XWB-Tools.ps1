#########################################################################
# XWB-AudioReplacer - XWB-Tools.ps1
# Copyright (C) 2026 Steve2811, astrogab42, Piero-93
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#########################################################################

###############################
######## Tool Functions #######
###############################

# Welcome message
function Set-WelcomeMessage {
    param (
        $ScriptName
    )
    Clear-Host
    Write-Host "Welcome to $ScriptName of the XwbAudioReplacer Project!" -ForegroundColor blue
    Write-Host "Credits -> Think: Steve2811 | Create: astrogab42 | Support: Piero-93" -ForegroundColor green
}

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

    #Write-HostInfo -Text "Check existance of $Folder."
    if (-not(Test-Path $Folder)) {
        # if the folder does not exists
        Write-HostWarn -Text "The path you selected does not exists."
        Write-HostInfo -Text "Path: $Folder"

        $Output = $false
                
        <# DEPRECATED
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
        #>
    }
    else {
        #Write-HostInfo -Text "$Folder exists!"
        $Output = $true
    }

    return $Output
}

# Check file existance 
function Assert-FileExists {
    param (
        $File
    )

    #Write-HostInfo -Text "Check existance of $File"
    if (-not(Test-Path $File)) {
        # if the file does not exists
        Write-HostWarn -Text "The path you selected for your file does not exists."
        Write-HostInfo -Text "Path: $File"

        $Output = $false

        <# DEPRECATED
        Write-HostError -Text "It is impossibile to continue. The script will be stopped."
        exit
        #>
    }
    else {
        #Write-HostInfo -Text "$File exists!"
        $Output = $true
    }
    
    return $Output
}
