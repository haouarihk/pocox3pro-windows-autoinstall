$winVolLetter = "B"
$espVolLetter  = "T"

Write-Output "DO NOT RUN THIS BEFORE THE SETUP FILE"



function wait-for-recovery-device{
    Write-Output "<waiting for recovery device>"
    DO{
      sleep 2
      $rdevices  = $(.\platform-tools\adb.exe devices | findstr "recovery" )
    } Until ($rdevices -gt "")
}

# Downloading windows.iso
if(-not(Test-Path -Path .\windows-arm.iso)){
    Write-Output "Download it yourself, and rename it as windows-arm.iso"
  }


function setup-binaries{
    if(-not(Test-Path -Path .\bin\msc.sh)){
    Invoke-WebRequest https://dl.google.com/android/repository/platform-tools_r33.0.3-windows.zip -OutFile bin\msc.sh
    if(-not(Test-Path -Path .\bin\msc.sh)){
        Write-Output "couldn't download msc"
        exit
    }
    }

    Write-Output "-- pushing binaries"
    .\platform-tools\adb.exe push .\bin /sbin 
    .\platform-tools\adb.exe shell mv ./sbin/bin/* /sbin 

    Write-Output "-- Setting permission"
    .\platform-tools\adb.exe shell "chmod +x /sbin/*"
}




  


#------------------------ setting up letters step ------------------------
setup-binaries

Write-Output "-- Assigning letters"
Write-Output "DO NOT PLUG A USB DRIVER, OR REMOVE ONE. JUST DO NOT TOUCH THE PC IN ANY WAY. THE SCRIPT IS DUMB"
# get diskpart volume list
$volsbefore = $(diskpart /s .\diskpart\listvol.diskpart | findstr 'Partition')

$lastVolBefore = [int] $($($volsbefore[-1] -split " ")).Where({ $_ -ne "" })[1]

$lastVolLetter =  $($($volsbefore[-1] -split " ")).Where({ $_ -ne "" })[2]
$beforeLastVolLetter =  $($($volsbefore[-2] -split " ")).Where({ $_ -ne "" })[2]

# check if this step is already done
if(($espVolLetter -match $lastVolLetter) -and ($winVolLetter -match $beforeLastVolLetter ) ){
    Write-Output "continuing without modifications"
    exit
}

# disable mtp
# .\platform-tools\adb.exe shell EnMTP
# wait-for-recovery-device
# .\platform-tools\adb.exe shell DisMTP
wait-for-recovery-device
# run msc
.\platform-tools\adb.exe shell "sh /sbin/msc.sh"




Write-Output "note: if this stays like this, try to enable mtp, then wait a second and then disable it then wait another second. repeatedly"
Write-Output "Still waiting to read the phone"
do{
    sleep 3
    $volsafter = $(diskpart /s .\diskpart\listvol.diskpart | findstr 'Partition')
    $lastVolAfter = [int] $($($volsafter[-1] -split " ")).Where({ $_ -ne "" })[1]
} until($lastVolAfter -gt $lastVolBefore)

# volume number of the before last one
$lastVolBeforeAfter = [int] $($($volsafter[-2] -split " ")).Where({ $_ -ne "" })[1]

$lastVolLetter =  $($($volsafter[-1] -split " ")).Where({ $_ -ne "" })[2]
$beforeLastVolLetter =  $($($volsafter[-2] -split " ")).Where({ $_ -ne "" })[2]

remove-Item .\tmp
New-Item .\tmp

Write-Output $lastVolAfter $lastVolBeforeAfter

Write-Output "-- Assigning letters"
if($winVolLetter -match $beforeLastVolLetter){
    Write-Output "win already assigned $winVolLetter"
} else{
    # assign letter for win
    $content = "
    select vol $($lastVolBeforeAfter)
    assign letter=$winVolLetter 
    "
    Set-Content .\tmp $content 

    diskpart /s .\tmp
}


if($espVolLetter -match $lastVolLetter){
    Write-Output "esp already assigned $espVolLetter"

} else{
    # assign letter for esp
    $content = "
    select vol $($lastVolAfter)
    assign letter=$espVolLetter
    "

    Set-Content .\tmp $content 

    diskpart /s .\tmp
}



