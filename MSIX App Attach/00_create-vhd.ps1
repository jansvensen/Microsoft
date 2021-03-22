<#
.SYNOPSIS
The script creates a VHD/X File and copies the MSIX Data
.DESCRIPTION
Use this script to create a MSIX App Attach Container VHDX file and the corresponding json file
.NOTES
  Version:         1.0
  Author:          Sven Jansen <sven.jansen@devicetrust.com>
  Creation Date:   2021-03-22
  Purpose/Change:
#>

### region manual variable

    $MSIXPackageName = "C:\Users\devicetrust\Desktop\WireShark_1.0.0.0_x64__dpaxz3091nv8m.msix"
    $MSIXMgrPath = "C:\msixmgr\x64\msixmgr.exe"
    $parentFolder = "MSIX"
   
### end region

### region automatic variable

    $SoftwareName = [String][io.path]::GetFileNameWithoutExtension("$MSIXPackageName")
    $VHDFolder = "\\dc01\share\MSIXAppAttach" + "\" + $SoftwareName
    $VHDPath = $VHDFolder + "\" + $SoftwareName + ".vhd"    
    $JsonFile = $VHDFolder + "\" + "AppAttachInfo.json"
    
### end region

### region create VHD

    # create a VHD
    $VHDDisk = New-VHD -SizeBytes 1000MB -Path $VHDPath -Dynamic -Confirm:$false

    # mount the VHD
    $vhdObject = Mount-VHD $VHDPath -Passthru

    # initialize the mounted VHD
    $disk = Initialize-Disk -Passthru -Number $vhdObject.Number

    # create a new partition for the initialized VHD:
    $partition = New-Partition -AssignDriveLetter -UseMaximumSize -DiskNumber $disk.Number

    # format the partition
    $format = Format-Volume -FileSystem NTFS -Confirm:$false -DriveLetter $partition.DriveLetter -Force

    # Get expand target path
    $Path = $partition.DriveLetter + ":" + $parentFolder

### end region

### region expand MSIX

    # unpack the MSIX into the VHD
    &$MSIXMgrPath -Unpack -packagePath $MSIXPackageName -destination $Path -applyacls

### end region

### Region create json file

$UUID = $format.UniqueId.Split("{")[1]
$UUID = $UUID.Split("}")[0]

$JsonContent = @"
{
    "PackageName" : "$SoftwareName",
    "ParentFolder" : "$ParentFolder",
	"VolumeGUID" : "$UUID"
}
"@
$JsonContent | Out-File -FilePath $JSONFile

### end region

### Region unmount VHD

    $VHD = Get-VHD $VHDPath
    Dismount-VHD $VHD.DiskNumber

### end region