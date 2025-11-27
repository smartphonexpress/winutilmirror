@echo off
REM Disabilita inclusione driver con Windows Update
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /f /v ExcludeWUDriversInQualityUpdate /t REG_DWORD /d 1

REM Disabilita ricerca automatica driver per nuove periferiche
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" /f /v SearchOrderConfig /t REG_DWORD /d 0

echo Impostazioni applicate. Riavvia il computer per renderle effettive.
pause
