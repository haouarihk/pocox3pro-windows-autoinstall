powershell Set-ExecutionPolicy RemoteSigned

powershell . ./src/get-adb.ps1

@REM powershell ./src/setup.ps1

echo "run this only if you previewsly installed using this script"

powershell . ./src/install-windows.ps1


powershell Set-ExecutionPolicy Restricted