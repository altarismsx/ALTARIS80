@echo off
rem ALTARIS 80 - instalacion directa, SIN respaldo (el firmware original se pierde)
cd /d "%~dp0"
where py >nul 2>nul || goto sinpython
py pc\altaris_pc.py directo %1
pause
exit /b
:sinpython
echo Falta Python 3. Instalalo desde python.org (ver MANUAL.txt, paso 4).
pause
