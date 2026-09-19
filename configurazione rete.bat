@echo off
setlocal EnableExtensions EnableDelayedExpansion

title Fix Condivisione Rete - Windows 10/11
echo.
echo ============================================
echo   FIX CONDIVISIONE CARTELLE IN RETE (LAN)
echo ============================================
echo   - Imposta profilo rete su PRIVATA
echo   - Abilita Network Discovery
echo   - Abilita File and Printer Sharing
echo   - Avvia e imposta servizi necessari
echo ============================================
echo.

:: --- Check admin ---
net session >nul 2>&1
if %errorlevel% neq 0 (
  echo [ERRORE] Devi eseguire questo file come AMMINISTRATORE.
  echo Tasto destro ^> Esegui come amministratore
  pause
  exit /b 1
)

echo [1/4] Imposto il profilo di rete su PRIVATA...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "Get-NetConnectionProfile | ForEach-Object { if($_.NetworkCategory -ne 'Private'){ Set-NetConnectionProfile -InterfaceIndex $_.InterfaceIndex -NetworkCategory Private } }" ^
  >nul 2>&1

echo [2/4] Abilito le regole Firewall per Network Discovery e File Sharing...
netsh advfirewall firewall set rule group="Network Discovery" new enable=Yes >nul 2>&1
netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes >nul 2>&1

echo [3/4] Configuro e avvio i servizi necessari...
call :SvcAutoStart FDResPub
call :SvcAutoStart fdPHost
call :SvcAutoStart LanmanServer
call :SvcAutoStart LanmanWorkstation
call :SvcAutoStart SSDPSRV
call :SvcAutoStart upnphost

echo [4/4] Abilito la pubblicazione risorse (condivisione visibile in rete)...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "try { Enable-NetFirewallRule -DisplayGroup 'Network Discovery' -ErrorAction SilentlyContinue | Out-Null } catch {}" ^
  >nul 2>&1

echo.
echo ============================================
echo FATTO.
echo - Se prima non si vedevano, riavvia il PC.
echo - Verifica che i PC siano nello stesso WORKGROUP (default: WORKGROUP).
echo ============================================
echo.
pause
exit /b 0

:SvcAutoStart
set "SVC=%~1"
sc query "%SVC%" >nul 2>&1
if %errorlevel% neq 0 (
  echo   - %SVC%: non presente su questo Windows (ok).
  goto :eof
)
sc config "%SVC%" start= auto >nul 2>&1
sc start "%SVC%" >nul 2>&1
echo   - %SVC%: OK
goto :eof