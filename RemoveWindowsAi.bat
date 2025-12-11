@echo off
setlocal

REM === Imposta URL raw di GitHub e nome file locale ===
set "URL=https://raw.githubusercontent.com/smartphonexpress/winutilmirror/e9a92f7e2e2b5d962fa8cab15b9636495744fd2c/RemoveWindowsAi.ps1"
set "OUTPUT=RemoveWindowsAi.ps1"

echo Scarico lo script PowerShell da GitHub...

REM === Tenta prima con curl (presente su Windows 10/11) ===
where curl >nul 2>&1
if %errorlevel%==0 (
    curl -L -o "%OUTPUT%" "%URL%"
) else (
    echo curl non trovato, uso PowerShell per scaricare il file...
    powershell -Command "try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%URL%' -OutFile '%OUTPUT%' -UseBasicParsing } catch { Write-Error $_; exit 1 }"
)

if not exist "%OUTPUT%" (
    echo ERRORE: il file %OUTPUT% non è stato scaricato correttamente.
    pause
    exit /b 1
)

echo Download completato. Avvio lo script PowerShell...

REM === Esegui lo script con PowerShell bypassando l'ExecutionPolicy per questa sola esecuzione ===
powershell -ExecutionPolicy Bypass -NoProfile -File "%OUTPUT%"

echo.
echo Script completato.
pause
endlocal
