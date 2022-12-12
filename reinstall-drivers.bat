powershell Set-ExecutionPolicy RemoteSigned

powershell ./src/get-adb.ps1 

@REM powershell ./src/setup-partitions.ps1

powershell ./src/install-drivers.ps1

powershell Set-ExecutionPolicy Restricted