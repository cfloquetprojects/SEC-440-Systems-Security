_____________________________________________________________________________
ReadMe:
The PowerShell proof of concept scripts that are present in this repository represent an example of a common issue faced in the Information Technology world and a solution to that problem.  Ransomware is a form of malware that encrypts a victims device or files, and then forces the victim to pay the attacker in order to receive a decryption key to encrypt their files again.  Victims who have their files backed up properly don’t have to worry as much about the consequences of ransomware, but those who do not will have no choice but to pay the ransom if they want their files back.

This is where our proof of concept comes in.  We have developed a PowerShell script that mimics the effects of ransomware (Attack.ps1).  
Requisite Files (located in the same folder as .ps1 file) are: 
 - Attacker generated public/private key pair to use for passwordless SCP
 - Attacker’s public key to encrypt symmetric key with before exporting
The script works by completing the following (in order of execution):
 - Downloading and installing the GnuPg software we will use to encrypt
 - Generating 32 character symmetric key for encrypting documents
 - Returns all users within the C:\ drive and parses through each directory and subfolders within that user’s profile. 
 - Defines the target path and file types of files to be encrypted
 - Encrypts files of those types within target directory using symmetric key
 - Removes (deletes) unencrypted versions of those files afterwards
 - Importing previously downloaded public key to use for encryption
 - Non-interactively sets the imported key trust to ultimate
 - Finds the UID of the public key from the imported keylist to use for encrypting the symmetric key before exporting. 
 - Encrypts the public key before sending it via scp back to attacker host
 - Also sends a list of encrypted folders to the attacker, for decryption later on. 
 - Passwordless/promptless SSH from the victim host to attacker host for SCP. 
 - Removes all files within the .ssh directory to prevent unauthorized access. 
 - Stores a ‘ransom.txt’ file on the current user desktop showing which files and their associated paths have been encrypted with gpg. 

At this point, the victim has two options:
Pay the ransom
In this case the attacker will send a decrypt script back to the victim along with the unencrypted randomly generated symmetric key so they can decrypt their files (Decrypt.ps1):
Requisite Files (located in the same folder as .ps1 file) are: 
 - List of encrypted files that was exported from the victim’s host 
 - Decrypted symmetric key with which to bulk decrypt files upon payment
Now that we have received our payment, the decryption script reads both the symmetric key and list of encrypted files into powershell variables. 
Then we simply iterate through those folders, decrypting the folder path with the symmetric key, while removing all files with the .gpg file extension afterwards. 

If they were prepared ahead of time they can restore their OS/files and move on with their day
We have developed a PowerShell script that enables users to have #2 as an option if they ever fall victim to ransomware (Backup_Client.ps1, or Backup_Server.ps1).  In order to operate, the computer in question must have an unused HDD or SSD connected.  This script works like this:
Takes a volume shadow of the OS using the vss service
Brings the second HDD or SSD online
If there is an existing backup present on the drive, the script renames it
Copies all existing user directories on the system to a new backup folder on the drive
Deletes the old backup
Unmounts/offlines the backup HDD or SSD
Note: The script should be scheduled to run daily with Windows Task Scheduler

This mitigation technique should be effective at combating ransomware, as after a backup is completed, the OS does not “know” this disk is attached.  As a result, any ransomware that is introduced to the system will not know to encrypt files on that disk.  After falling victim to a ransomware attack, the user can mount/online the disk and recover the backup of their files to avoid having to pay the ransom.

Please note, this proof of concept and the PowerShell scripts it includes are for educational purposes only, and should not be used for any malicious purposes.  These scripts are not guaranteed to work for your use case and in your environment, so use them at your own risk.
_____________________________________________________________________________
