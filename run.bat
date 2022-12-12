powershell Set-ExecutionPolicy RemoteSigned

powershell ./src/get-adb.ps1 

powershell ./src/setup.ps1 

powershell ./src/setup-partitions.ps1

powershell ./src/install-windows.ps1

powershell ./src/install-drivers.ps1

powershell Set-ExecutionPolicy Restricted