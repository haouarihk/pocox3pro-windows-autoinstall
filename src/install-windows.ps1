$isodriveLetter = "q:"




$nu = $(mkdir temp)
if(-not(Test-Path -Path .\downloads\uefi.zip)){
    Invoke-WebRequest https://api.github.com/repos/degdag/edk2-msm/releases/latest -OutFile .\temp\res.json
    $downloadlink = (Get-Content '.\temp\res.json' | Out-String | ConvertFrom-Json).assets.browser_download_url
    remove-Item .\temp\res.json
    Invoke-WebRequest $downloadlink -OutFile .\downloads\uefi.zip

    if(-not(Test-Path -Path .\downloads\uefi.zip)){
      Write-Output "couldn't download driverupdator"
      exit
    }

    Write-Output extracting...
    Expand-Archive .\downloads\uefi.zip -DestinationPath uefi

    if (-not(Test-Path -Path .\uefi)) {
        Write-Output "couldn't extract"
        exit
    }
}  




Write-Output "Formatting esp"
.\platform-tools\adb.exe shell "mkfs.fat -F32 -s1 /dev/block/by-name/esp"

Write-Output "Formatting win"
.\platform-tools\adb.exe shell "mkfs.ntfs -f /dev/block/by-name/win"


. ./src/setup-partitions.ps1

#------------------------ install ------------------------

$isoFile = $(Resolve-Path -Path windows-arm.iso)
$DiskImage = Mount-DiskImage -ImagePath $isoFile -StorageType iso -PassThru -NoDriveLetter
# Get mounted ISO volume
$volInfo = $DiskImage | Get-Volume
# Mount volume with specified drive letter (requires Administrator access)
mountvol $isodriveLetter $volInfo.UniqueId
sleep 1



Write-Output "installing windows, $isodriveLetter\sources\install.wim, ApplyDir:$($winVolLetter):\"
dism /apply-image /ImageFile:$isodriveLetter\sources\install.wim /index:1 /ApplyDir:$($winVolLetter):\

Dismount-DiskImage -ImagePath $isoFile




Write-Output "making backup of boot image"
.\platform-tools\adb.exe shell "twrp backup boot"


Write-Output "getting the appropriate uefi file, $phonePanelType-$($phoneRamSize)G"
$uefiFilePath = Get-ChildItem -Path .\uefi -Filter "$phonePanelType-$phoneRamSize*" -Recurse | % { $_.FullName }

Write-Output "moving uefi image"
.\platform-tools\adb.exe push $uefiFilePath /sdcard/uefi.img

Write-Output "flashing the boot image"
.\platform-tools\adb.exe shell "twrp backup boot"

