# This Backup Script will only work on Windows 10
# These functions were obtained from our p0w3rsh3ll.wordpress.com source


Function Mount-VolumeShadowCopy {
<#
    .SYNOPSIS
        Mount a volume shadow copy.
     
    .DESCRIPTION
        Mount a volume shadow copy.
      
    .PARAMETER ShadowPath
        Path of volume shadow copies submitted as an array of strings
      
    .PARAMETER Destination
        Target folder that will contain mounted volume shadow copies
              
    .EXAMPLE
        Get-CimInstance -ClassName Win32_ShadowCopy | 
        Mount-VolumeShadowCopy -Destination C:\VSS -Verbose
 
#>
[CmdletBinding()]
Param(
    [Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
    [ValidatePattern('\\\\\?\\GLOBALROOT\\Device\\HarddiskVolumeShadowCopy\d{1,}')]
    [Alias("DeviceObject")]
    [String[]]$ShadowPath,
 
    [Parameter(Mandatory)]
    [ValidateScript({
        Test-Path -Path $_ -PathType Container
    }
    )]
    [String]$Destination
)
Begin {
    Try {
        $null = [mklink.symlink]
    } Catch {
        Add-Type @"
        using System;
        using System.Runtime.InteropServices;
  
        namespace mklink
        {
            public class symlink
            {
                [DllImport("kernel32.dll")]
                public static extern bool CreateSymbolicLink(string lpSymlinkFileName, string lpTargetFileName, int dwFlags);
            }
        }
"@
    }
}
Process {
 
    $ShadowPath | ForEach-Object -Process {
 
        if ($($_).EndsWith("\")) {
            $sPath = $_
        } else {
            $sPath = "$($_)\"
        }
        
        $tPath = Join-Path -Path $Destination -ChildPath (
        '{0}-{1}' -f (Split-Path -Path $sPath -Leaf),[GUID]::NewGuid().Guid
        )
         
        try {
            if (
                [mklink.symlink]::CreateSymbolicLink($tPath,$sPath,1)
            ) {
                Write-Verbose -Message "Successfully mounted $sPath to $tPath"
            } else  {
                Write-Warning -Message "Failed to mount $sPath"
            }
        } catch {
            Write-Warning -Message "Failed to mount $sPath because $($_.Exception.Message)"
        }
    }
 
}
End {}
}
 
Function Dismount-VolumeShadowCopy {
<#
    .SYNOPSIS
        Dismount a volume shadow copy.
     
    .DESCRIPTION
        Dismount a volume shadow copy.
      
    .PARAMETER Path
        Path of volume shadow copies mount points submitted as an array of strings
      
    .EXAMPLE
        Get-ChildItem -Path C:\VSS | Dismount-VolumeShadowCopy -Verbose
         
 
#>
 
[CmdletBinding()]
Param(
    [Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
    [Alias("FullName")]
    [string[]]$Path
)
Begin {
}
Process {
    $Path | ForEach-Object -Process {
        $sPath =  $_
        if (Test-Path -Path $sPath -PathType Container) {
            if ((Get-Item -Path $sPath).Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
                try {
                    [System.IO.Directory]::Delete($sPath,$false) | Out-Null
                    Write-Verbose -Message "Successfully dismounted $sPath"
                } catch {
                    Write-Warning -Message "Failed to dismount $sPath because $($_.Exception.Message)"
                }
            } else {
                Write-Warning -Message "The path $sPath isn't a reparsepoint"
            }
        } else {
            Write-Warning -Message "The path $sPath isn't a directory"
        }
     }
}
End {}
}

#Create a temporary folder to mount the shadow copy
New-Item -ItemType directory -Path C:\ShadowCopy

#Enable computer restore if it isn't already enabled
Enable-ComputerRestore "C:\"

#Obtain the current date for a restore point name
$description = Get-Date -UFormat %m/%d/%y


#Make a restore point (Create a shadow copy)
Checkpoint-Computer -Description $description -RestorePointType "MODIFY_SETTINGS"

#Bring the backup disk online
Get-Disk 1 | Set-Disk -IsOffline $False

#Rename the old backup
Rename-Item -path B:\Backup -newName Backup_Old

#Mount the latest shadow copy to a temporary directory
Get-CimInstance -ClassName Win32_ShadowCopy | sort InstallDate | select -last 1 | Mount-VolumeShadowCopy -Destination C:\ShadowCopy

#Determine the mounted shadow copy folder path
$pathname= Get-ChildItem -Path C:\ShadowCopy | Select-Object -ExpandProperty Name 

#Copy the users directory from the shadow copy to the backup disk
XCOPY "C:\ShadowCopy\$pathname\Users\*" "B:\Backup\" /E /H /C /q /r

#Delete the old backup
Remove-Item -Recurse -Force B:\Backup_Old

#Bring the backup disk offline again
Get-Disk 1 | Set-Disk -IsOffline $True

#Dismount the shadow copy
Get-ChildItem -Path C:\ShadowCopy | Dismount-VolumeShadowCopy

#Exit PowerShell
exit