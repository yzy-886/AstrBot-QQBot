@echo off
chcp 65001 >nul
set LOG=%USERPROFILE%\wsl-features.log
echo ==== %DATE% %TIME% ==== > "%LOG%"

echo [1/3] 结束卡住的 wsl.exe ...
taskkill /F /IM wsl.exe /T >> "%LOG%" 2>&1

echo [2/3] 启用 Microsoft-Windows-Subsystem-Linux ...
dism /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart /quiet >> "%LOG%" 2>&1
echo DISM_WSL=%ERRORLEVEL% >> "%LOG%"

echo [3/3] 启用 VirtualMachinePlatform ...
dism /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart /quiet >> "%LOG%" 2>&1
echo DISM_VMP=%ERRORLEVEL% >> "%LOG%"

echo ==== 完成 ==== >> "%LOG%"
type "%LOG%"
timeout /t 6 >nul
