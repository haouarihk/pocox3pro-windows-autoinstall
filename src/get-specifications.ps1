$phoneDisplay = [string] $(.\platform-tools\adb.exe shell "cat /proc/cmdline | sed 's: :\n:g; q' | grep 'display' | sed 's:=:\n:g; q' | grep 'j20'")
$device = $(.\platform-tools\adb.exe shell "getprop ro.product.device")
$m = $(.\platform-tools\adb shell "grep MemTotal /proc/meminfo")

if($m -match "7687524"){
  $phoneRamSize=8
  $phoneStorage=256
}else{
  $phoneRamSize=6
  $phoneStorage=128
}




if($phoneDisplay -match "_42_02"){
  $phonePanelType= "huaxing"
} elseif($phoneDisplay -match "_36"){
  $phonePanelType= "tianma"
} else {
  Write-Output $phoneDisplay
  $phonePanelType= "unknown"
}


if($phonePanelType -ne "unknown"){
    Write-Output "Your Specifications are:"
    Write-Output "Device      = $device"
    Write-Output "Panel Type  = $phonePanelType"
    Write-Output "Ram size    = $phoneRamSize GB"
    Write-Output "Storage     = $phoneStorage GB"
} else{
    Write-Output "couldn't detect your device"
}


