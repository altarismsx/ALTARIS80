@echo off
rem ALTARIS 80 - prueba los cables entre el Arduino y la MailStation
cd /d "%~dp0"
where py >nul 2>nul || goto sinpython
py pc\altaris_pc.py cables %1
pause
exit /b
:sinpython
echo Falta Python 3. Instalalo desde python.org (ver MANUAL.txt, paso 4).
pause
