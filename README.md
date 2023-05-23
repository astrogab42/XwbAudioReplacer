## XWB-AudioReplacer

### INTRODUCTION

“XWBExtractor.ps1” and “XWBRepacker.ps1” are Powershell scripts that make possible to replace audio files of games using XWB wavebanks, file with XWB extension that contain game sounds, music or voicelines. The XWB file is created by the game developers with the DirectX SDK tool called "Cross-platform Audio Creation Tool" (a.k.a. XACT). Thanks to the scripts in this GitHub project, users can replace original audio files with their own ones, such as music, sounds or voicelines in the game. The scripts were only tested with 'The Secret of Monkey Island: Special Edition', but we did our best to make them compatible with all other older games that use XWB files. This script required months of reverse engineering, programming, documentation and study by 3 Italian engineers/programmers. The information essential for the realisation of this scripts was in part very difficult to find online and in part discovered directly by our team and not present online at all. If you would like to support us, please consider a donation at the following link: https://www.paypal.com/donate/?hosted_button_id=GRRUY4KGSLFPA.

### STEP 0 - Bat script launcher files

We decided to provide the user a "few-click" solution to handle the tools, say the scripts. In the root folder the two bat launcher “XWB-Extractor-Launcher.bat” and “XWB-Repacker-Launcher.bat”. They are simple solutions to run the scripts located in the inner folders.

### STEP 1 - "XWBExtractor.ps1": EXTRACT WAV FILES FROM XWB FILE

Within the installation folder of the game, locate the XWB file (containing the WAV files) and copy its path. Then start the script XWBExtractor.ps1 and enter:

*   the path to the XWB file in the game folder containing the WAV files to be extracted;
*   the path to the folder that will contain the extracted WAV files.

### STEP 2 - PREPARING THE NEW WAV FILES

Create or prepare your own custom WAV files, whether sound, music, or voicelines and place them together in a folder.
The size in bits of custom files must be less than or equal to the original counterpart: if the custom file is larger in size than the original file, reduce the duration or the quality of the custom file. Since the game expects files with a maximum size in bits equal to the original file size, this limit is not removable by this script as otherwise the game would not start.
User custom files shall have the same name as the original WAV files extracted from the XWB file.
The user folder does not have to contain all original audio files: if a custom audio file is not present, "XWBRepacker.ps1" will use the original audio file.

### STEP 3 - "XWBRepacker.ps1": CREATION OF NEW XWB FILE

The first time the script is started, you will be asked to configure it. This configuration includes:

*   OriginalWavPath: the path containing the WAV files extracted from the XWB file with "XWBExtractor.ps1";
*   CustomWavPath: the path containing user audio files;
*   XWBPath: the path to the XWB file inside the game folder;
*   GameExePath: the path to the exe file of the game launcher;
*   RunGame = True/False: toggle game launching after the execution of the script.

Then the "XWBRepacker.ps1" script will show a menu with 4 choices:

1.  Add all custom audio files.  
    Pushes in the the game all user WAV files. Use whenever you add or edit a WAV file to the custom file folder.
2.  Synchronise custom audio files.  
    Pushes all custom audio files currently in the custom files folder into the game and restores the original version for all other WAV files. Use this function if you wish to remove previously loaded custom sound files from the game that are no longer present in the custom sound files folder.
3.  Edit configuration.  
    Use this function if you want to change the script's working folders and decide whether or not to start the game after execution.
4.  Clear Cache  
    Deletes cached WAV files. No user files will be deleted. Use this function if you do not plan to use the script for a long time and wish to archive the script without occupying too much disk space. The cache will be rebuilt each time the user adds custom sound files to the XWB file via this script.
5.  Restore the original XWB file  
    Restores the original XWB file created by the game developers. To be used in case something goes wrong and the game no longer starts.
Q.  Quit from the script.

### CONCLUSION

The game should now start with the new audio files. We donate this script to the community so that anyone with little or no technical skills can customise their favourite games by inserting their own music, sounds, or recording all voicelines in their own language.
