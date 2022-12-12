

$nu = $(mkdir .\downloads)

# donwload the driverupdator
if(-not(Test-Path -Path .\downloads\DriverUpdater.zip)){
    Write-Output "downloading driverupdater.zip"
    Invoke-WebRequest https://github.com/WOA-Project/DriverUpdater/releases/download/v1.0.0.7/win-x64.zip -OutFile .\downloads\DriverUpdater.zip
    if(-not(Test-Path -Path .\downloads\DriverUpdater.zip)){
      Write-Output "couldn't download driverupdator"
      exit
    }

    Write-Output extracting...
    Expand-Archive .\downloads\DriverUpdater.zip -DestinationPath DriverUpdater

    if (-not(Test-Path -Path .\DriverUpdater)) {
        Write-Output "couldn't extract"
        exit
    }
}  

Write-Output "checking driverupdater.zip"
# donwload the drivers
if(-not(Test-Path -Path .\downloads\drivers.zip)){
    Write-Output "downloading drivers"
    Invoke-WebRequest https://api.github.com/repos/degdag/Vayu-Drivers/releases/latest -OutFile .\temp\res.json
    $downloadlink = (Get-Content '.\temp\res.json' | Out-String | ConvertFrom-Json).assets.browser_download_url
    remove-Item .\temp\res.json
    Invoke-WebRequest $downloadlink -OutFile .\downloads\drivers.zip
    if(-not(Test-Path -Path .\downloads\drivers.zip)){
      Write-Output "couldn't download driverupdator"
      exit
    }

    Write-Output extracting...
    Expand-Archive .\downloads\drivers.zip -DestinationPath drivers

    if (-not(Test-Path -Path .\drivers)) {
        Write-Output "couldn't extract"
        exit
    }
}  

. .\src\get-specifications.ps1
. .\src\setup-partitions.ps1

$tPath = "drivers\Vayu-Drivers-Full\components\QC8150\Device\DEVICE.SOC_QC8150.VAYU\Drivers\Touch"

    
# modify for huaxing
if($phonePanelType -match "huaxing"){
    $f2Path = "$tPath\j20s_novatek_ts_fw02.bin"
    $f1Path = "$tPath\j20s_novatek_ts_fw01.bin"

    if(Test-Path -Path $f2Path){
        Rename-Item -Path $f1Path -NewName "tianma-stuff.bin"
        Rename-Item -Path $f2Path -NewName "j20s_novatek_ts_fw01.bin"
    }
} elseif(Test-Path -Path "$tPath\tianma-stuff.bin"){
    Rename-Item -Path $f1Path -NewName "j20s_novatek_ts_fw02.bin"
    Rename-Item -Path "$f2Path\tianma-stuff.bin" -NewName "j20s_novatek_ts_fw01.bin"
}

# move the sensors config
Write-Output "mounting /persist"
.\platform-tools\adb.exe shell "twrp mount /persist"

$nu = $(mkdir temp)

Write-Output "retriving sensors data"
.\platform-tools\adb.exe pull /persist/sensors/ temp

$dest  = "$($winVolLetter):\Windows\System32\Drivers\DriverData\QUALCOMM\fastRPC\persist\"
# $nu = $(mkdir "$($dest)")

Write-Output "copying sensors data over to windows"
Copy-Item -Path $(Resolve-Path -Path temp\sensors) -Destination $dest -Recurse 
remove-Item -Path temp\sensors



# install drivers
Write-Output "installing drivers"
$driversFolderPath = Get-ChildItem -Path .\drivers -Filter "*" | % { $_.FullName }
DriverUpdater\DriverUpdater.exe -d "$driversFolderPath\definitions\Desktop\ARM64\Internal\vayu.txt" -r $driversFolderPath -p "$($winVolLetter):"



# create esp
Write-Output "creating esp..."
cmd /c "bcdboot $($winVolLetter):\Windows /s $($espVolLetter): /f UEFI"

Write-Output "allowing unsigned drivers..."
cmd /c "bcdedit /store $($espVolLetter):\EFI\Microsoft\BOOT\BCD /set {default} testsigning on" 

