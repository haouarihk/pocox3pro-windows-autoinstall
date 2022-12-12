Write-Output "getting adbtools"


if (-not(Test-Path -Path .\platform-tools))  {
  if (-not(Test-Path -Path .\downloads\adbtools.zip)) {
    Invoke-WebRequest https://dl.google.com/android/repository/platform-tools_r33.0.3-windows.zip -OutFile .\downloads\adbtools.zip
    if(-not(Test-Path -Path .\downloads\adbtools.zip)){
      Write-Output "couldn't download"
      exit
    }
  }

  Write-Output extracting...
  Expand-Archive .\downloads\adbtools.zip -DestinationPath .

  if (-not(Test-Path -Path .\platform-tools)) {
    Write-Output "couldn't extract"
    exit
  }
} else{
  Write-Output "Found platform-tools,  skipping download"
}