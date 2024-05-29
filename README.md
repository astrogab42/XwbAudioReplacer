# XWB-AudioReplacer

## INTRODUCTION

“XWBExtractor.ps1” and “XWBRepacker.ps1” are Powershell scripts that make possible to replace audio files of games using XACT WaveBanks (XWB), file with XWB extension that contain game sounds, music or voicelines. The XWB file is created by the game developers with the DirectX SDK tool called "Cross-platform Audio Creation Tool" (a.k.a. XACT). Thanks to the scripts in this GitHub project, users can replace original audio files with their own ones, such as music, sounds or voicelines in the game. The scripts have been  tested with 'The Secret of Monkey Island: Special Edition', but we did our best to make them compatible with all the other older games that use XWB files. This script required months of reverse engineering, programming, documentation and study of 3 Italian Engineers. The essential information for the realisation of these scripts was in part very difficult to be found online and in part discovered directly by our team, since it was not present online at all. If you would like to support us and the project, please consider a donation at the following link: https://www.paypal.com/donate/?hosted_button_id=GRRUY4KGSLFPA.

### PREREQUISITES

The scripts use PowerShell 7.x (Core), so make sure to have it installed.
Reference: https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell

### COMPATIBILITY

XWB-Audio-Replacer has been tested on Windows 10 and Windows 11 with PowerShell Core 7.4 already installed.
Thanks to the cross-compatibility of PowerShell Core with MacOS and Linux, it could potentially work with other operating systems with some small adaptations.

## XWB-EXTRACTOR
### EXTRACTING WAV FILES FROM XWB FILE

The script allows you to extract the WAV files from the XWB file contained in the game installation folder.
Within the installation folder of the game, locate the XWB file (containing the WAV files) and copy its full path. Then run *XWB-Extractor-Launcher.bat* and enter:

*   the path to the XWB file in the game folder containing the WAV files to be extracted;
*   the path to the folder that will contain the extracted WAV files.

## XWB-REPACKER

The script allows you to insert your own audio files into the game.

### STEP 1 - PREPARING CUSTOM WAV FILES

Create or prepare your own custom WAV files, whether sound, music, or voicelines and place them together in a folder.
The ***size in bits*** of custom files MUST be less than or equal to the original counterpart: if the custom file is larger than the original file, reduce the duration or the quality of the custom file. Since the game expects files with a maximum size in bits equal to the original file size, this limit is not removable by this script as otherwise the game would not start - the script will warn the user of this particular issue, exiting the process and avoid to continue.
User custom files SHALL have the same name as the original WAV files extracted from the XWB file.
The user folder does not need to contain all original audio files: if a custom audio file is not present, the REPACKER will use the original audio file.

### STEP 2 - CREATING THE NEW XWB FILE
#### CONFIGURATION
Run XWB-Repacker-Launcher.bat.
The first time the REPACKER script is started, you will be asked to configure it. This configuration includes:

- *OriginalWavPath*: the path containing the WAV files extracted from the XWB file with the EXTRACTOR;
- *CustomWavPath*: the path containing user audio files;
- *XWBPath*: the path to the XWB file inside the game folder;
- *GameExePath*: the path to the exe file of the game launcher;
- *RunGame = True/False*: if you want to run the game after the execution of the script or not.

#### REPACKER MENU
The REPACKER script will now show a menu with the following choices. Select the desired option and wait for the output.

- *1. Add all custom audio files.* - Pack and push in the game all the custom WAV files. Use whenever you add or edit a WAV file to the custom file folder.
- *2. Synchronise custom audio files.* - Pack and push all custom audio files currently in the custom files folder into the game and restores the original version for all other WAV files. Use this function if you wish to remove previously loaded custom sound files from the game that are no longer present in the custom sound files folder.
- *3. Edit configuration.* - Use this function if you want to change the script's working folders and decide whether or not to start the game after execution.
- *4. Clear Cache.* - Deletes cached WAV files. No user files will be deleted. Use this function if you do not plan to use the script for a long time and wish to archive the script without occupying too much disk space. The cache will be rebuilt each time the user adds custom sound files to the XWB file through this script.
- *5. Restore the original XWB file.* - Restores the original XWB file created by the game developers. To be used in case something goes wrong and, for example, the game starts no longer.
- *Q. Quit from the script.* - Exit and quit.

The game should now be ready with custom audio files inserted.

## CONCLUSIONS

We donate this script to the community so that anyone with little technical skills can customise their favourite games by inserting their own music, sounds, or recording all voicelines in their own language.

## NOTES FOR THE COMMUNITY
As reported above, at the moment the script only allows the use of audio files with a byte size less than or equal to that of the original audio file. If desired, this limitation can be removed by rebuilding the XSB file. We leave this information here for our or the community's future developments.

------------
*Credits -> Think: Steve2811 | Create: astrogab42 | Support: Piero-93*
