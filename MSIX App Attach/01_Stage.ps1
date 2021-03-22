#MSIX app attach staging sample
#region variables

    $MSIXAppAttachFolder = "\\dc01\Share\MSIXAppAttach"
    $JSONFileName = "AppAttachInfo.json"    

#endregion
Get-ChildItem $MSIXAppAttachFolder -Directory | foreach-object{
    
    #region variables

        $msixJunction = "$Env:WinDir\Temp\AppAttach\"

        $vhdSrc= (get-ChildItem -Path $_.FullName -Filter *.vhd*)[0].FullName

        $VHDFolder = (Get-Item $vhdSrc).DirectoryName

        $JsonFile = "$VHDFolder\$JSONFileName"
        $Json = get-content $JsonFile | ConvertFrom-Json

        $packageName = $Json.PackageName
        $parentFolder = $Json.ParentFolder
        $parentFolder = "\" + $parentFolder + "\"
        $volumeGuid = $Json.VolumeGUID

     #endregion

     #region mountvhd

        try
        {
              Mount-Diskimage -ImagePath $vhdSrc -NoDriveLetter -Access ReadOnly | out-null
              Write-Host ("Mounting of " + $vhdSrc + " was completed!") -BackgroundColor Green
        }
        catch
        {
              Write-Host ("Mounting of " + $vhdSrc + " has failed!") -BackgroundColor Red
        }

    #endregion
    
    #region makelink

        $msixDest = "\\?\Volume{" + $volumeGuid + "}\"
        if (!(Test-Path $msixJunction))
        {
             md $msixJunction
        }

        $msixJunction = $msixJunction + $packageName
        cmd.exe /c mklink /j $msixJunction $msixDest
        "MSIXDest: " + $msixDest
        
    #endregion

    #region stage

        [Windows.Management.Deployment.PackageManager,Windows.Management.Deployment,ContentType=WindowsRuntime] | Out-Null

        Add-Type -AssemblyName System.Runtime.WindowsRuntime

        $asTask = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where { $_.ToString() -eq 'System.Threading.Tasks.Task`1[TResult] AsTask[TResult,TProgress](Windows.Foundation.IAsyncOperationWithProgress`2[TResult,TProgress])'})[0]

        $asTaskAsyncOperation = $asTask.MakeGenericMethod([Windows.Management.Deployment.DeploymentResult], [Windows.Management.Deployment.DeploymentProgress])
        $packageManager = [Windows.Management.Deployment.PackageManager]::new()
        "MSIXJunction: " + $msixJunction
        "ParentFolder: " + $parentFolder
        "PackageName: " + $packageName
        $path = $msixJunction + $parentFolder + $packageName
        "Path: " + $path 
        $path = ([System.Uri]$path).AbsoluteUri
        $asyncOperation = $packageManager.StagePackageAsync($path, $null, "StageInPlace")
        $task = $asTaskAsyncOperation.Invoke($null, @($asyncOperation))

        $path = ""
        $msixJunction = ""

    #endregion
}