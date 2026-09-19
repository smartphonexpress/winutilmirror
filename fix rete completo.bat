@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Fix Condivisione Rete - Compat

set "LOG=%USERPROFILE%\Desktop\FixShare_log.txt"
echo ==== START %DATE% %TIME% ==== > "%LOG%"

:: Check admin
net session >nul 2>&1
if %errorlevel% neq 0 (
  echo [ERRORE] Esegui come amministratore.>>"%LOG%"
  echo [ERRORE] Devi eseguire questo file come AMMINISTRATORE.
  pause
  exit /b 1
)

:: Config
set "SHARE_FOLDER=C:\Condivisa"
set "SHARE_NAME=Condivisa"
set "SHARE_USER=ShareUser"
set "WORKGROUP_NAME=WORKGROUP"

:MENU
cls
echo ==========================================
echo  Fix Condivisione Rete - COMPAT
echo  Log: %LOG%
echo ==========================================
echo [1] Fix rete (Privata + Firewall + Servizi)
echo [2] Crea share + utente + permessi
echo [3] Diagnostica
echo [0] Esci
echo.
set /p "CHOICE=Scelta: "
if "%CHOICE%"=="1" goto FIX_NETWORK
if "%CHOICE%"=="2" goto SHARE_SETUP
if "%CHOICE%"=="3" goto DIAG
if "%CHOICE%"=="0" goto END
goto MENU

:FIX_NETWORK
echo --- FIX_NETWORK --- >> "%LOG%"

echo Imposto profilo rete su Privata...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "Get-NetConnectionProfile | ForEach-Object { if($_.NetworkCategory -ne 'Private'){ Set-NetConnectionProfile -InterfaceIndex $_.InterfaceIndex -NetworkCategory Private } }" ^
  >>"%LOG%" 2>&1

echo Abilito firewall Discovery e File Sharing...
netsh advfirewall firewall set rule group="Network Discovery" new enable=Yes >>"%LOG%" 2>&1
netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes >>"%LOG%" 2>&1

echo Avvio servizi...
call :SvcAutoStart FDResPub
call :SvcAutoStart fdPHost
call :SvcAutoStart LanmanServer
call :SvcAutoStart LanmanWorkstation

echo Flush DNS...
ipconfig /flushdns >>"%LOG%" 2>&1

echo.
echo OK. (Se vuoi, riavvia dopo)
pause
goto MENU

:SHARE_SETUP
echo --- SHARE_SETUP --- >> "%LOG%"

echo.
echo Imposta una password per l'utente %SHARE_USER%:
for /f "usebackq delims=" %%P in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "$p=Read-Host 'Password' -AsSecureString; $b=[Runtime.InteropServices.Marshal]::SecureStringToBSTR($p); [Runtime.InteropServices.Marshal]::PtrToStringBSTR($b)"`) do set "PASS=%%P"

if not defined PASS (
  echo Password non letta.>>"%LOG%"
  echo [ERRORE] Non sono riuscito a leggere la password (PowerShell bloccato?).
  pause
  goto MENU
)

echo Creo cartella...
if not exist "%SHARE_FOLDER%" mkdir "%SHARE_FOLDER%" >>"%LOG%" 2>&1

echo Creo/aggiorno utente...
net user "%SHARE_USER%" >nul 2>&1
if %errorlevel% neq 0 (
  net user "%SHARE_USER%" "%PASS%" /add /y >>"%LOG%" 2>&1
) else (
  net user "%SHARE_USER%" "%PASS%" >>"%LOG%" 2>&1
)

echo Permessi NTFS...
icacls "%SHARE_FOLDER%" /inheritance:r >>"%LOG%" 2>&1
icacls "%SHARE_FOLDER%" /grant "Administrators:(OI)(CI)F" "SYSTEM:(OI)(CI)F" >>"%LOG%" 2>&1
icacls "%SHARE_FOLDER%" /grant "%COMPUTERNAME%\%SHARE_USER%:(OI)(CI)M" >>"%LOG%" 2>&1

echo Ricreo share...
net share "%SHARE_NAME%" >nul 2>&1
if %errorlevel%==0 net share "%SHARE_NAME%" /delete /y >>"%LOG%" 2>&1

net share "%SHARE_NAME%=%SHARE_FOLDER%" ^
  /grant:"%COMPUTERNAME%\%SHARE_USER%",CHANGE ^
  /grant:"Administrators",FULL ^
  /grant:"SYSTEM",FULL >>"%LOG%" 2>&1

echo.
echo ✅ Share pronta: \\%COMPUTERNAME%\%SHARE_NAME%
echo Utente: %COMPUTERNAME%\%SHARE_USER%
pause
goto MENU

:DIAG
echo --- DIAG --- >> "%LOG%"
cls
echo ====== DIAGNOSTICA ======
echo.

echo Profili rete:
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-NetConnectionProfile | Select InterfaceAlias,NetworkCategory,IPv4Connectivity | Format-Table -AutoSize" 2>nul

echo.
echo Share presenti:
net share

echo.
echo IPv4:
ipconfig | findstr /I "IPv4"

echo.
echo (Dettagli nel log: %LOG%)
pause
goto MENU

:SvcAutoStart
set "SVC=%~1"
sc query "%SVC%" >>"%LOG%" 2>&1
sc config "%SVC%" start= auto >>"%LOG%" 2>&1
sc start "%SVC%" >>"%LOG%" 2>&1
goto :eof

:END
echo ==== END %DATE% %TIME% ====>>"%LOG%"
endlocal
exit /b 0