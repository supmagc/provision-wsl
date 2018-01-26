Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
Invoke-WebRequest -Uri https://aka.ms/wsl-ubuntu-1604 -OutFile ~/Ubuntu.zip -UseBasicParsing
Expand-Archive ~/Ubuntu.zip ~/Ubuntu
~/Ubuntu/ubuntu.exe
