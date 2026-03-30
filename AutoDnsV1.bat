@echo off
:: 한글 깨짐 방지를 위해 UTF-8 인코딩 설정
chcp 65001 >nul
color 0F

:: 관리자 권한 자동 획득 (네트워크 설정 변경에 필수)
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo 관리자 권한을 요청하고 있습니다...
    echo 예(Y)를 눌러주세요.
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
"%temp%\getadmin.vbs"
exit /B

:gotAdmin
if exist "%temp%\getadmin.vbs" ( del "%temp%\getadmin.vbs" )
pushd "%CD%"
CD /D "%~dp0"

:intro
cls
echo ==========================================================
echo               간편 네트워크 DNS 변경 프로그램
echo ==========================================================
echo [프로그램 설명]
echo 이 프로그램은 복잡한 설정 없이 인터넷 DNS를 변경해줍니다.
echo 인터넷 접속 속도를 개선하거나 특정 사이트 접속 문제를 
echo 해결할 때 매우 유용합니다. 코딩을 몰라도 번호만 누르면 됩니다.
echo ==========================================================
echo.
echo [1단계] 현재 연결된 네트워크 어댑터 이름을 확인하세요.
echo (보통 "이더넷" 또는 "Wi-Fi" 중 하나입니다.)
echo.
netsh interface show interface | findstr /C:"연결됨" /C:"Connected"
echo.
set /p adapter="▶ 위 목록을 보고 변경할 어댑터 이름을 정확히 입력하세요 (예: 이더넷): "

:main_menu
cls
echo ==========================================================
echo 선택된 어댑터: [%adapter%]
echo ==========================================================
echo 적용할 DNS 서버를 숫자로 선택해주세요.
echo.
echo   1. 구글 DNS 설정 (8.8.8.8) - 안정성이 높고 무난함
echo   2. 클라우드플레어 DNS 설정 (1.1.1.1) - 반응 속도가 빠름
echo   3. KT 기본 DNS 설정 (168.126.63.1) - 국내 환경에 최적화
echo   4. DNS 설정 초기화 (자동 방식 - 원래대로 복구)
echo   5. 프로그램 종료
echo ==========================================================
set /p choice="▶ 원하는 작업의 번호를 입력하고 엔터를 누르세요: "

if "%choice%"=="1" goto set_google
if "%choice%"=="2" goto set_cloudflare
if "%choice%"=="3" goto set_kt
if "%choice%"=="4" goto set_dhcp
if "%choice%"=="5" exit

:: 잘못된 입력 처리
echo 잘못된 입력입니다. 1~5 사이의 숫자를 입력해주세요.
timeout /t 2 >nul
goto main_menu

:set_google
echo.
echo 구글 DNS로 변경을 시작합니다...
netsh interface ipv4 set dnsservers name="%adapter%" static 8.8.8.8 primary validate=no
netsh interface ipv4 add dnsservers name="%adapter%" 8.8.4.4 index=2 validate=no
echo 설정이 완료되었습니다!
pause
goto main_menu

:set_cloudflare
echo.
echo 클라우드플레어 DNS로 변경을 시작합니다...
netsh interface ipv4 set dnsservers name="%adapter%" static 1.1.1.1 primary validate=no
netsh interface ipv4 add dnsservers name="%adapter%" 1.0.0.1 index=2 validate=no
echo 설정이 완료되었습니다!
pause
goto main_menu

:set_kt
echo.
echo KT DNS로 변경을 시작합니다...
netsh interface ipv4 set dnsservers name="%adapter%" static 168.126.63.1 primary validate=no
netsh interface ipv4 add dnsservers name="%adapter%" 168.126.63.2 index=2 validate=no
echo 설정이 완료되었습니다!
pause
goto main_menu

:set_dhcp
echo.
echo DNS 설정을 초기화하여 자동으로 IP를 받도록 설정합니다...
netsh interface ipv4 set dnsservers name="%adapter%" dhcp
echo 설정이 완료되었습니다! (초기화 완료)
pause
goto main_menu