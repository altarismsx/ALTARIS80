@echo off
rem ALTARIS 80 - copia la memoria de la MailStation a la PC, sin cambiar nada
cd /d "%~dp0"
where py >nul 2>nul || goto sinpython
py pc\altaris_pc.py respaldo %1
pause
exit /b
:sinpython
echo Falta Python 3. Instalalo desde python.org (ver MANUAL.txt, paso 4).
pause
