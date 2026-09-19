@echo off
setlocal EnableExtensions EnableDelayedExpansion
title KMS/KMSpico cleanup (Windows 10)

:: --- Admin check ---
net session >nul 2>&1
if %errorlevel% neq 0 (
  echo [ERRORE] Avvia questo file come AMMINISTRATORE.
  echo Tasto destro ^> Esegui come amministratore
  pause
  exit /b 1
)

echo ==========================================================
echo   KMS / KMSpico cleanup - Windows 10
echo   - servizi / task / cartelle / autorun
echo ==========================================================
echo.

set "LOG=%USERPROFILE%\Desktop\kms_cleanup_log.txt"
echo ==== LOG %DATE% %TIME% ==== > "%LOG%"

call :log "Avvio cleanup..."

:: --- Stop + delete services containing "kms" in name/display ---
call :log "Ricerca e rimozione servizi sospetti (kms/autokms)..."
for /f "tokens=2 delims=:" %%S in ('sc query type^= service state^= all ^| findstr /i "SERVICE_NAME:"') do (
  set "SVC=%%S"
  set "SVC=!SVC: =!"
  echo !SVC! | findstr /i "kms" >nul
  if !errorlevel! == 0 (
    call :log "Servizio trovato: !SVC!"
    sc stop "!SVC!" >> "%LOG%" 2>&1
    sc delete "!SVC!" >> "%LOG%" 2>&1
  )
)

:: --- Delete scheduled tasks containing kms/autokms ---
call :log "Ricerca e rimozione Task pianificati (kms/autokms)..."
for /f "delims=" %%T in ('schtasks /Query /FO LIST /V ^| findstr /i /c:"TaskName:"') do (
  set "LINE=%%T"
  for /f "tokens=2* delims=:" %%A in ("!LINE!") do (
    set "TN=%%B"
    set "TN=!TN:~1!"
    echo !TN! | findstr /i "kms autokms" >nul
    if !errorlevel! == 0 (
      call :log "Task trovato: !TN!"
      schtasks /Delete /TN "!TN!" /F >> "%LOG%" 2>&1
    )
  )
)

:: --- Common folders/files ---
call :log "Rimozione cartelle tipiche..."
call :delpath "C:\Program Files\KMSpico"
call :delpath "C:\Program Files (x86)\KMSpico"
call :delpath "C:\Windows\AutoKMS"
call :delpath "C:\Windows\System32\Tasks\AutoKMS"
call :delpath "%ProgramData%\KMSpico"
call :delpath "%ProgramData%\AutoKMS"

:: --- Registry autorun (Run/RunOnce) entries containing "kms" ---
call :log "Pulizia voci di avvio nel Registro (Run/RunOnce con 'kms')..."
call :cleanrun "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
call :cleanrun "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"
call :cleanrun "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
call :cleanrun "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"

:: --- Hosts check (just report lines with kms) ---
call :log "Controllo file hosts (solo segnalazione righe con 'kms')..."
set "HOSTS=%WINDIR%\System32\drivers\etc\hosts"
if exist "%HOSTS%" (
  findstr /i "kms" "%HOSTS%" >nul
  if !errorlevel! == 0 (
    call :log "ATTENZIONE: trovate righe con 'kms' nel file hosts:"
    findstr /i "kms" "%HOSTS%" >> "%LOG%" 2>&1
    echo (Vedi log sul Desktop) 
  ) else (
    call :log "OK: nessuna riga 'kms' nel file hosts."
  )
)

call :log "Fine cleanup. Riavvia il PC."
echo.
echo ==========================================================
echo COMPLETATO. Log salvato su:
echo   %LOG%
echo ==========================================================
echo.
pause
exit /b 0

:: ----------------- FUNCTIONS -----------------
:log
echo [%DATE% %TIME%] %~1
echo [%DATE% %TIME%] %~1 >> "%LOG%"
exit /b

:delpath
set "P=%~1"
if exist "%P%" (
  call :log "Elimino: %P%"
  rmdir /s /q "%P%" >> "%LOG%" 2>&1
  del /f /q "%P%" >> "%LOG%" 2>&1
) else (
  call :log "Non trovato: %P%"
)
exit /b

:cleanrun
set "K=%~1"
reg query "%K%" >nul 2>&1
if %errorlevel% neq 0 (
  call :log "Chiave non presente: %K%"
  exit /b
)
for /f "tokens=1,2,*" %%A in ('reg query "%K%" ^| findstr /i "REG_"') do (
  echo %%C | findstr /i "kms" >nul
  if !errorlevel! == 0 (
    call :log "Rimuovo autorun: [%K%] %%A = %%C"
    reg delete "%K%" /v "%%A" /f >> "%LOG%" 2>&1
  )
)
exit /b