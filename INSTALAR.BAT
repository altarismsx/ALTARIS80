@echo off
rem ALTARIS 80 - instala el sistema en la MailStation (ver MANUAL.txt, paso 5)
cd /d "%~dp0"
where py >nul 2>nul || goto sinpython
py pc\altaris_pc.py instalar %1
pause
exit /b
:sinpython
echo Falta Python 3. Instalalo desde python.org (ver MANUAL.txt, paso 4).
pause
