@echo off
rem ALTARIS 80 - vuelve a grabar un respaldo: arrastra el archivo encima
cd /d "%~dp0"
where py >nul 2>nul || goto sinpython
if "%~1"=="" goto uso
py pc\altaris_pc.py restaurar "%~1" %2
pause
exit /b
:uso
echo Arrastra el archivo respaldo_mailstation_....bin encima de RESTAURAR.BAT.
pause
exit /b
:sinpython
echo Falta Python 3. Instalalo desde python.org (ver MANUAL.txt, paso 4).
pause
