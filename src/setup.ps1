
function wait-for-recovery-device{
  Write-Output "<waiting for recovery device>"
  DO{
    sleep 2
    $rdevices  = $(.\platform-tools\adb.exe devices | findstr "recovery" )
  } Until ($rdevices -gt "")
}


function wait-for-fastboot-device{
  Write-Output "<waiting for fastboot device>"
  DO{
    sleep 2
    $rdevices  = $(.\platform-tools\adb.exe devices | findstr "fastboot" )
  } Until ($rdevices -gt "")
}



function setup-binaries{
  if(-not(Test-Path -Path .\bin\parted)){
    Invoke-WebRequest https://dl.google.com/android/repository/platform-tools_r33.0.3-windows.zip -OutFile bin\msc.sh
    if(-not(Test-Path -Path .\bin\parted)){
      Write-Output "couldn't download parted"
      exit
    }
  }  

  Write-Output "-- pushing binaries"
  .\platform-tools\adb.exe push .\bin /sbin 
  .\platform-tools\adb.exe shell mv ./sbin/bin/* /sbin 

  Write-Output "-- Setting permission"
  .\platform-tools\adb.exe shell "chmod +x /sbin/*"
}

# check if adbInstaller.exe exists, if it doesn't then
# get https://dl.google.com/android/repository/platform-tools_r33.0.3-windows.zip > adbtools.zip


# if(-not($(.\platform-tools\adb.exe devices) -match "recovery"))
# {
#   # assumes that you're anywhere, without twrp
#   .\platform-tools\adb.exe reboot fastboot
#   $fastboot wait-for-device shell "echo connected"

#   # install recovery
#   # Boot into recovery

#   $fastboot reboot recovery
#   sleep 15
# } else {
#   Write-Output "already in recovery, nice"
# }

# get phone specifications
Write-Output "Getting phone specifications.."


clear
. .\get-specifications.ps1

# Check if vayu
if(-not($device -match "vayu")){
  Write-Output "Your Phone isn't vayu(poco x3 pro) get oooutta here."
  exit
}


$phoneStorageWithoutEsp = [math]::Round($phoneStorage - 1 - 12.2, 2)

# ask the user
Write-Output "How much are you gonna give to windows"
Write-Output "note that whatever is left, android will take"

$defaultWinSize = [math]::Round($phoneStorageWithoutEsp / 2)
do{
  $winSize = [int] $(Read-Host -Prompt "Enter Amount (in GB) default:$defaultWinSize, [40 - $($phoneStorageWithoutEsp-10)] ")
  if($winSize -eq 0){
    $winSize = $phoneStorageWithoutEsp / 2
  }
} until(($winSize -gt 40)-and($winSize -lt $phoneStorageWithoutEsp-10))

$winEnd = 12.2 + [math]::Round($winSize)
Write-Output "$($phoneStorage-1 - $winEnd)GB will be left for android, and windows will take $winSize"
sleep 2


# ------------------------ partition step ------------------------
Write-Output "-- resizing table"
.\platform-tools\adb.exe shell sgdisk --resize-table 64 /dev/block/sda


setup-binaries



# Checking if 32 is the userdata
# retrives the line data for 
$userdatanum = [int]$(.\platform-tools\adb.exe shell "parted /dev/block/sda -s print all | grep -w ' userdata ' | awk '{print `$1}'")
$espnum = [int]$(.\platform-tools\adb.exe shell "parted /dev/block/sda -s print all | grep -w ' esp ' | awk '{print `$1}'")
$winnum = [int]$(.\platform-tools\adb.exe shell "parted /dev/block/sda -s print all | grep -w ' win ' | awk '{print `$1}'")


if($espnum -gt 30){
  Write-Output "About to delete esp that is located in sda$espnum, press ctrl+c to cancel .. in 3 seconds"
  sleep 3
  .\platform-tools\adb.exe shell "parted /dev/block/sda -s rm $espnum"
} elseIf(-not($espnum -eq 0)){
  Write-Output "esp was located in sda$espnum, seek help"
  exit
}


if($winnum -gt 30){
  Write-Output "About to delete win that is located in sda$winnum, press ctrl+c to cancel .. in 3 seconds"
  sleep 3
  .\platform-tools\adb.exe shell "parted /dev/block/sda -s rm $winnum"
} elseIf(-not($winnum -eq 0)){
  Write-Output "win was located in sda$winnum, seek help"
  exit
}

# Checks if its more than 30th place atleast
if ($userdatanum -gt 30){
  Write-Output "About to delete userdata that is located in sda$userdatanum, press ctrl+c to cancel ..continuing in 3 seconds"
  sleep 3
  .\platform-tools\adb.exe shell "parted /dev/block/sda -s rm $userdatanum"
} elseIf(-not($userdatanum -eq 0)){
  Write-Output "userdata was located in sda$userdatanum, seek help"
  exit
} else{
  Write-Output "you don't have userdata, ..continuing in 2 seconds"
  sleep 2
}


Write-Output "now for the creation"

Write-Output "Creating esp..."
.\platform-tools\adb.exe shell "parted /dev/block/sda -s mkpart esp fat32 11.8GB 12.2GB"


Write-Output "Creating win partition..."
.\platform-tools\adb.exe shell "parted /dev/block/sda -s mkpart win ntfs 12.2GB $($winEnd)GB"

Write-Output "Creating userdata partition..."
.\platform-tools\adb.exe shell "parted /dev/block/sda -s mkpart userdata ext4 $($winEnd)GB $($phoneStorage - 1)GB"


Write-Output "Formatting userdata"
.\platform-tools\adb.exe shell "twrp format data"


.\platform-tools\adb reboot recovery

wait-for-recovery-device

setup-binaries


Write-Output "setting esp on"
.\platform-tools\adb.exe shell "parted /dev/block/sda -s set 32 esp on"

# ------------------------ ;                    ------------------------

