@echo off
rem ALTARIS 80 - manda un archivo a la MailStation: arrastralo encima
cd /d "%~dp0"
where py >nul 2>nul || goto sinpython
if "%~1"=="" goto uso
py pc\altaris_pc.py enviar "%~1" %2
pause
exit /b
:uso
echo Arrastra un archivo .bas o .txt encima de ENVIAR.BAT.
pause
exit /b
:sinpython
echo Falta Python 3. Instalalo desde python.org (ver MANUAL.txt, paso 4).
pause
