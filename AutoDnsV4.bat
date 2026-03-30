@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
color 0F
title DNS 변경 도구 (개선형)

:: 관리자 권한 확인
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [안내] 관리자 권한이 필요합니다. 재실행합니다...
    powershell -Command "Start-Process cmd -ArgumentList '/c %~s0' -Verb runAs"
    exit /b
)

:intro
cls
echo ==========================================================
echo        [간편 네트워크 DNS 변경 프로그램 - 개선형]
echo ==========================================================
echo.
echo ▶ 기능:
echo  - DNS 빠른 변경
echo  - DNS 복구
echo  - 네트워크 재연결
echo  - 실시간 DNS 테스트
echo.
echo ▶ 주의:
echo  - 관리자 권한 필수
echo  - 어댑터 이름 정확히 입력
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
    set /p adapter=▶ 어댑터 이름 입력: 
)

if not defined adapter goto adapter_select

:: 정확한 어댑터 검증
netsh interface show interface name="%adapter%" >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo [오류] "%adapter%" 어댑터를 찾을 수 없습니다.
    echo 실제 이름을 확인하세요.
    pause
    goto adapter_select
)

:main
cls
echo =========================================
echo 선택된 장치: [%adapter%]
echo =========================================
echo 1. Google DNS (빠름/안정)
echo 2. Cloudflare DNS (속도 최상)
echo 3. KT DNS (국내 최적화)
echo 4. DNS 자동 복구 (DHCP)
echo 5. 사용자 지정 DNS
echo 6. 네트워크 재연결
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
echo.
echo [설정] Google DNS 적용 중...
set success=1

netsh interface ipv4 set dnsservers name="%adapter%" static 8.8.8.8 primary >nul
if %errorlevel% neq 0 set success=0

netsh interface ipv4 add dnsservers name="%adapter%" 8.8.4.4 index=2 >nul
if %errorlevel% neq 0 set success=0

goto apply_result

:cloudflare
echo.
echo [설정] Cloudflare DNS 적용 중...
set success=1

netsh interface ipv4 set dnsservers name="%adapter%" static 1.1.1.1 primary >nul
if %errorlevel% neq 0 set success=0

netsh interface ipv4 add dnsservers name="%adapter%" 1.0.0.1 index=2 >nul
if %errorlevel% neq 0 set success=0

goto apply_result

:kt
echo.
echo [설정] KT DNS 적용 중...
set success=1

netsh interface ipv4 set dnsservers name="%adapter%" static 168.126.63.1 primary >nul
if %errorlevel% neq 0 set success=0

netsh interface ipv4 add dnsservers name="%adapter%" 168.126.63.2 index=2 >nul
if %errorlevel% neq 0 set success=0

goto apply_result

:dhcp
echo.
echo [복구] 자동 DNS(DHCP)로 복원 중...
set success=1

netsh interface ipv4 set dnsservers name="%adapter%" source=dhcp >nul
if %errorlevel% neq 0 set success=0

goto apply_result

:custom
cls
echo =========================================
echo         사용자 DNS 설정
echo =========================================

set /p dns1=▶ 기본 DNS 입력: 

echo %dns1% | findstr /R "^[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$" >nul
if %errorlevel% neq 0 (
    echo [오류] 잘못된 형식입니다.
    pause
    goto custom
)

set /p dns2=▶ 보조 DNS 입력 (없으면 Enter): 

set success=1

netsh interface ipv4 set dnsservers name="%adapter%" static %dns1% primary >nul
if %errorlevel% neq 0 set success=0

if not "%dns2%"=="" (
    netsh interface ipv4 add dnsservers name="%adapter%" %dns2% index=2 >nul
    if %errorlevel% neq 0 set success=0
)

goto apply_result

:restart
echo.
echo [재연결] 네트워크 초기화 중...
ipconfig /release >nul
ipconfig /renew >nul
echo 완료
pause
goto main

:apply_result
echo.
if "%success%"=="1" (
    echo [성공] DNS 설정 완료
) else (
    echo [실패] 설정 중 오류 발생
)

timeout /t 2 >nul
goto result

:result
cls
echo =========================================
echo           결과 확인
echo =========================================

echo [현재 DNS]
netsh interface ipv4 show dnsservers name="%adapter%" | findstr "[0-9]"

echo.
echo [DNS 캐시 초기화]
ipconfig /flushdns >nul
echo 완료

echo.
echo [DNS 응답 테스트]
nslookup google.com

echo.
echo =========================================
echo 1. 메인으로
echo 2. DNS 자동 복구
echo 3. 종료
echo =========================================

set /p endchoice=▶ 선택: 

if "%endchoice%"=="1" goto main
if "%endchoice%"=="2" goto dhcp
if "%endchoice%"=="3" exit /b

goto result