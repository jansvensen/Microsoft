#region parameter

Param(
	[String]$SoftwareName
	)

# End region

#region variables

    $MSIXAppAttachFolder = "\\dc01\Share\MSIXAppAttach"
    $JSONFileName = "AppAttachInfo.json"
    
    $SoftwarePath = $MSIXAppAttachFolder + "\" + $SoftwareName

    $vhdSrc= (get-ChildItem -Path $SoftwarePath -Filter *.vhd*)[0].FullName

    $VHDFolder = (Get-Item $vhdSrc).DirectoryName

    $JsonFile = "$VHDFolder\$JSONFileName"


    If(Test-Path -Path $JsonFile){
        $Json = get-content $JsonFile |ConvertFrom-Json
        $packageName = $Json.PackageName
    }
    else{
        Write-Host "$JsonFile not found"
    }
    
#endregion

#region deregister

    Remove-AppxPackage -PreserveRoamableApplicationData $packageName

#endregion