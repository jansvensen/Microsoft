#MSIX app attach staging sample
#region variables

    $MSIXAppAttachFolder = "\\dc01\Share\MSIXAppAttach"
    $JSONFileName = "AppAttachInfo.json"

    $msixJunction = "$Env:WinDir\Temp\AppAttach\"

#endregion

Get-ChildItem $MSIXAppAttachFolder -Directory | foreach-object{
    
    #region variables

        $vhdSrc= (get-ChildItem -Path $_.FullName -Filter *.vhd*)[0].FullName

        $VHDFolder = (Get-Item $vhdSrc).DirectoryName

        $JsonFile = "$VHDFolder\$JSONFileName"

        If(Test-Path -Path $JsonFile){
            $Json = get-content $JsonFile |ConvertFrom-Json
            $packageName = $Json.PackageName
            $PackageMountPoint = "$msixJunction\$packageName"
            $packageName #= $Json.PackageName
            $PackageMountPoint #= "$msixJunction\$packageName"
        }
        else{
            Write-Host "$JsonFile not found"
        }
        
    #region deregister

        Remove-AppxPackage -AllUsers -Package $packageName

    #cd $msixJunction

        Remove-Item -Path $PackageMountPoint -Recurse -Force

    # rmdir $packageName -Force -Verbose

        Dismount-DiskImage -ImagePath $vhdSrc

    #endregion
}