@echo off
setlocal
chcp 65001 >nul
color 0F

:: 관리자 권한 확인
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo 관리자 권한을 요청합니다...
    powershell -Command "Start-Process cmd -ArgumentList '/c %~s0' -Verb runAs"
    exit /b
)

:intro
cls
echo ==========================================================
echo        [간편 네트워크 DNS 변경 프로그램]
echo ==========================================================
echo ※ 어댑터 이름이 다르면 3번(직접 입력)을 사용하세요
echo ==========================================================
pause

:adapter_select
cls
echo =========================================
echo         네트워크 어댑터 선택
echo =========================================
echo 1. Wi-Fi
echo 2. 이더넷
echo 3. 직접 입력
echo =========================================

set "adapter="
set /p adapter_choice=▶ 선택: 

if "%adapter_choice%"=="1" set "adapter=Wi-Fi"
if "%adapter_choice%"=="2" set "adapter=이더넷"

if "%adapter_choice%"=="3" (
    set /p adapter=어댑터 이름 입력: 
)

if not defined adapter goto adapter_select

:main
cls
echo =========================================
echo 선택된 장치: [%adapter%]
echo =========================================

netsh interface show interface | findstr /C:"%adapter%" >nul
if %errorlevel% neq 0 (
    echo [오류] 어댑터를 찾을 수 없습니다.
    pause
    goto adapter_select
)

echo 1. Google DNS
echo 2. Cloudflare DNS
echo 3. KT DNS
echo 4. DNS 초기화
echo 5. 사용자 지정 DNS
echo 6. 네트워크 재시작
echo 7. 어댑터 다시 선택
echo 8. 종료
echo =========================================

set /p choice=▶ 선택: 

if "%choice%"=="1" goto google
if "%choice%"=="2" goto cloudflare
if "%choice%"=="3" goto kt
if "%choice%"=="4" goto dhcp
if "%choice%"=="5" goto custom
if "%choice%"=="6" goto restart
if "%choice%"=="7" goto adapter_select
if "%choice%"=="8" exit /b

goto main

:google
set success=0
netsh interface ipv4 set dnsservers name="%adapter%" static 8.8.8.8 primary validate=no
if %errorlevel%==0 set success=1
netsh interface ipv4 add dnsservers name="%adapter%" 8.8.4.4 index=2 validate=no
netsh interface ipv6 set dnsservers name="%adapter%" static 2001:4860:4860::8888 >nul 2>&1
goto apply_result

:cloudflare
set success=0
netsh interface ipv4 set dnsservers name="%adapter%" static 1.1.1.1 primary validate=no
if %errorlevel%==0 set success=1
netsh interface ipv4 add dnsservers name="%adapter%" 1.0.0.1 index=2 validate=no
netsh interface ipv6 set dnsservers name="%adapter%" static 2606:4700:4700::1111 >nul 2>&1
goto apply_result

:kt
set success=0
netsh interface ipv4 set dnsservers name="%adapter%" static 168.126.63.1 primary validate=no
if %errorlevel%==0 set success=1
netsh interface ipv4 add dnsservers name="%adapter%" 168.126.63.2 index=2 validate=no
goto apply_result

:dhcp
set success=0
netsh interface ipv4 set dnsservers name="%adapter%" source=dhcp
if %errorlevel%==0 set success=1
netsh interface ipv6 set dnsservers name="%adapter%" source=dhcp >nul 2>&1
goto apply_result

:custom
set success=0
set /p dns1=▶ 기본 DNS 입력: 

echo %dns1% | findstr /R "^[0-9.]*$" >nul
if %errorlevel% neq 0 goto main

set /p dns2=▶ 보조 DNS 입력: 

netsh interface ipv4 set dnsservers name="%adapter%" static %dns1% primary validate=no
if %errorlevel%==0 set success=1

if not "%dns2%"=="" (
    netsh interface ipv4 add dnsservers name="%adapter%" %dns2% index=2 validate=no
)

goto apply_result

:apply_result
if "%success%"=="1" (
    echo [성공] 설정 완료
) else (
    echo [실패] 설정 실패
)
timeout /t 2 >nul
goto result

:restart
netsh interface set interface "%adapter%" disable
timeout /t 3 >nul
netsh interface set interface "%adapter%" enable
pause
goto main

:result
cls
echo =========================================
echo           결과 확인
echo =========================================

echo [현재 DNS]
netsh interface ipv4 show dnsservers name="%adapter%" | findstr /R "[0-9]\.[0-9]\.[0-9]\.[0-9]"
echo.

echo [DNS 테스트]
ping google.com -n 2
echo.

echo =========================================
echo 1. 처음으로
echo 2. DNS 복구
echo 3. 종료
echo =========================================

set /p endchoice=▶ 선택: 

if "%endchoice%"=="1" goto main
if "%endchoice%"=="2" goto dhcp
if "%endchoice%"=="3" exit /b

goto result