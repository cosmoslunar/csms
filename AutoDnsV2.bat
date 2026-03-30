@echo off
chcp 65001 >nul
color 0F

:: 관리자 권한 확인
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo 관리자 권한을 요청합니다...
    powershell -Command "Start-Process cmd -ArgumentList '/c %~s0' -Verb runAs"
    exit
)

:adapter_select
cls
echo ===============================
echo   네트워크 어댑터 선택
echo ===============================
echo 1. Wi-Fi
echo 2. 이더넷
echo 3. 직접 입력
echo ===============================
set adapter=
set /p adapter_choice=번호 선택: 

if "%adapter_choice%"=="1" set adapter=Wi-Fi
if "%adapter_choice%"=="2" set adapter=이더넷

if "%adapter_choice%"=="3" (
    set /p adapter=어댑터 이름 입력: 
    if "%adapter%"=="" (
        echo 어댑터 이름은 비울 수 없습니다.
        pause
        goto adapter_select
    )
)

if "%adapter%"=="" (
    echo 잘못된 입력입니다.
    pause
    goto adapter_select
)

:main
cls
echo =========================================
echo 선택된 어댑터: [%adapter%]
echo =========================================

echo [현재 네트워크 상태]
netsh interface show interface | findstr "%adapter%"
echo.

echo 1. Google DNS
echo 2. Cloudflare DNS
echo 3. KT DNS
echo 4. DNS 초기화 (자동)
echo 5. 사용자 지정 DNS
echo 6. 네트워크 재시작
echo 7. 어댑터 다시 선택
echo 8. 종료
echo =========================================

set /p choice=선택: 

if "%choice%"=="1" goto google
if "%choice%"=="2" goto cloudflare
if "%choice%"=="3" goto kt
if "%choice%"=="4" goto dhcp
if "%choice%"=="5" goto custom
if "%choice%"=="6" goto restart
if "%choice%"=="7" goto adapter_select
if "%choice%"=="8" exit

echo 잘못된 입력
pause
goto main

:apply_success
if %errorlevel%==0 (
    echo [성공] DNS 설정 완료!
) else (
    echo [실패] 설정 실패. 어댑터 이름 확인 필요
)
timeout /t 2 >nul
goto result

:google
echo Google DNS 적용중...
netsh interface ipv4 set dnsservers name="%adapter%" static 8.8.8.8 primary
netsh interface ipv4 add dnsservers name="%adapter%" 8.8.4.4 index=2

netsh interface ipv6 set dnsservers name="%adapter%" static 2001:4860:4860::8888
netsh interface ipv6 add dnsservers name="%adapter%" 2001:4860:4860::8844 index=2
goto apply_success

:cloudflare
echo Cloudflare DNS 적용중...
netsh interface ipv4 set dnsservers name="%adapter%" static 1.1.1.1 primary
netsh interface ipv4 add dnsservers name="%adapter%" 1.0.0.1 index=2

netsh interface ipv6 set dnsservers name="%adapter%" static 2606:4700:4700::1111
netsh interface ipv6 add dnsservers name="%adapter%" 2606:4700:4700::1001 index=2
goto apply_success

:kt
echo KT DNS 적용중...
netsh interface ipv4 set dnsservers name="%adapter%" static 168.126.63.1 primary
netsh interface ipv4 add dnsservers name="%adapter%" 168.126.63.2 index=2
goto apply_success

:dhcp
echo DNS 자동 설정 복구중...
netsh interface ipv4 set dnsservers name="%adapter%" dhcp
netsh interface ipv6 set dnsservers name="%adapter%" dhcp
goto apply_success

:custom
set /p dns1=기본 DNS 입력: 
if "%dns1%"=="" (
    echo 값이 비어있습니다.
    pause
    goto main
)

set /p dns2=보조 DNS 입력 (없으면 엔터): 

netsh interface ipv4 set dnsservers name="%adapter%" static %dns1% primary

if not "%dns2%"=="" (
    netsh interface ipv4 add dnsservers name="%adapter%" %dns2% index=2
)

echo 적용 완료
timeout /t 2 >nul
goto result

:restart
echo 네트워크 재시작 중...
netsh interface set interface "%adapter%" disable
timeout /t 3 >nul
netsh interface set interface "%adapter%" enable
echo 재연결 완료
pause
goto main

:result
cls
echo =========================================
echo           설정 결과 확인
echo =========================================

echo [현재 DNS 상태]
netsh interface ip show dnsservers name="%adapter%"
echo.

echo [핑 테스트 - Google]
ping 8.8.8.8 -n 4
echo.

echo =========================================
echo 1. 종료
echo 2. 처음으로 돌아가기
echo 3. DNS 자동 복구
echo =========================================

set /p endchoice=선택: 

if "%endchoice%"=="1" exit
if "%endchoice%"=="2" goto main
if "%endchoice%"=="3" goto dhcp

echo 잘못된 입력
pause
goto result