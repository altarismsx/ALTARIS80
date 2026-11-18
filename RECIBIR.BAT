@echo off
rem ALTARIS 80 - trae un archivo de la MailStation a la carpeta "recibidos"
cd /d "%~dp0"
where py >nul 2>nul || goto sinpython
set NOMBRE=
set /p NOMBRE=Nombre del archivo en la MailStation: 
if "%NOMBRE%"=="" exit /b
if not exist recibidos mkdir recibidos
cd recibidos
py ..\pc\altaris_pc.py recibir "%NOMBRE%" %1
echo.
echo Los archivos recibidos quedan en la carpeta "recibidos".
pause
exit /b
:sinpython
echo Falta Python 3. Instalalo desde python.org (ver MANUAL.txt, paso 4).
pause
