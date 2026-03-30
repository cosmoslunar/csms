@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul 2>&1
color 0A
title DNS Tool

echo 실행 중...
:: 관리자 권한 확인
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo 관리자 권한이 필요합니다. 재실행 중...
    powershell -Command "Start-Process cmd -ArgumentList '/c %~s0' -Verb runAs"
    exit /b
)

:intro
cls
echo ==================================================
echo       DNS Tool          (https://github.com/cosmoslunar/csms)
echo ==================================================
echo  - IPv4 + IPv6 지원
echo  - 12개 DNS 서버 지원
echo  - 자동 추천 기능
echo  - 속도 측정
echo  - DNS 캐시 관리
echo ==================================================
echo.
pause

:adapter
cls
echo 사용 중인 네트워크 어댑터 목록:
echo ==================================================
netsh interface show interface | find "연결됨"
echo ==================================================
echo.
echo 1. Wi-Fi
echo 2. 이더넷
echo 3. 직접 입력
echo 4. 새로고침
echo 5. 뒤로
set /p sel=선택 (1-5): 

if "%sel%"=="1" set "adapter=Wi-Fi"
if "%sel%"=="2" set "adapter=이더넷"
if "%sel%"=="3" set /p adapter=어댑터 이름 입력: 
if "%sel%"=="4" goto adapter
if "%sel%"=="5" goto intro

:: 어댑터 존재 확인
netsh interface show interface name="%adapter%" >nul 2>&1
if errorlevel 1 (
    echo.
    echo [오류] '%adapter%' 어댑터를 찾을 수 없습니다.
    timeout /t 2 >nul
    goto adapter
)

:menu
cls
echo ==================================================
echo  현재 어댑터: [%adapter%]
echo ==================================================
echo  1. Google DNS (8.8.8.8, 8.8.4.4)
echo  2. Cloudflare (1.1.1.1, 1.0.0.1)
echo  3. KT (168.126.63.1, 168.126.63.2)
echo  4. SK Broadband (219.250.36.130, 210.220.163.82)
echo  5. LG U+ (164.124.101.2, 203.248.252.2)
echo  6. Quad9 (9.9.9.9, 149.112.112.112)
echo  7. OpenDNS (208.67.222.222, 208.67.220.220)
echo  8. AdGuard (94.140.14.14, 94.140.15.15)
echo  9. CleanBrowsing (185.228.168.9, 185.228.169.9)
echo 10. Alternate DNS (76.76.19.19, 76.223.122.150)
echo 11. Comodo Secure (8.26.56.26, 8.20.247.20)
echo 12. Verisign (64.6.64.6, 64.6.65.6)
echo ==================================================
echo 13. 자동 추천 (속도 기준)
echo 14. 속도 테스트 (모든 DNS)
echo 15. DHCP 복구 (자동 설정)
echo 16. DNS 캐시 초기화
echo 17. 현재 DNS 확인
echo 18. 어댑터 재연결
echo 19. 종료
echo ==================================================

set /p c=선택 (1-19): 

if "%c%"=="1" call :setdns "8.8.8.8" "8.8.4.4" "2001:4860:4860::8888"
if "%c%"=="2" call :setdns "1.1.1.1" "1.0.0.1" "2606:4700:4700::1111"
if "%c%"=="3" call :setdns "168.126.63.1" "168.126.63.2" "::"
if "%c%"=="4" call :setdns "219.250.36.130" "210.220.163.82" "::"
if "%c%"=="5" call :setdns "164.124.101.2" "203.248.252.2" "::"
if "%c%"=="6" call :setdns "9.9.9.9" "149.112.112.112" "2620:fe::fe"
if "%c%"=="7" call :setdns "208.67.222.222" "208.67.220.220" "2620:119:35::35"
if "%c%"=="8" call :setdns "94.140.14.14" "94.140.15.15" "2a10:50c0::ad1:ff"
if "%c%"=="9" call :setdns "185.228.168.9" "185.228.169.9" "::"
if "%c%"=="10" call :setdns "76.76.19.19" "76.223.122.150" "::"
if "%c%"=="11" call :setdns "8.26.56.26" "8.20.247.20" "::"
if "%c%"=="12" call :setdns "64.6.64.6" "64.6.65.6" "::"
if "%c%"=="13" goto auto
if "%c%"=="14" goto speedtest_all
if "%c%"=="15" goto dhcp
if "%c%"=="16" goto flushdns
if "%c%"=="17" goto showdns
if "%c%"=="18" goto reset
if "%c%"=="19" exit

goto menu

:setdns
echo.
echo [적용 중] DNS 설정 변경...
echo IPv4 주 DNS: %~1
echo IPv4 보조 DNS: %~2
if not "%~3"=="::" echo IPv6 DNS: %~3

:: IPv4 설정
netsh interface ipv4 set dns name="%adapter%" static %~1 >nul 2>&1
if errorlevel 1 (
    echo [오류] IPv4 DNS 설정 실패
    goto result_error
)

if not "%~2"=="" netsh interface ipv4 add dns name="%adapter%" %~2 index=2 >nul 2>&1

:: IPv6 설정
if not "%~3"=="::" (
    netsh interface ipv6 set dns name="%adapter%" static %~3 >nul 2>&1
) else (
    netsh interface ipv6 set dns name="%adapter%" source=dhcp >nul 2>&1
)

goto result_success

:auto
cls
echo ==================================================
echo        자동 DNS 추천 (속도 측정 기반)
echo ==================================================
echo 측정 중... (약 10초 소요)
echo.

set best_time=9999
set best_name=none
set best_ip1=none
set best_ip2=none
set best_ip6=none

:: DNS 목록 (이름, IPv4주DNS, IPv4보조DNS, IPv6DNS)
set dns_list[0]=Google 8.8.8.8 8.8.4.4 2001:4860:4860::8888
set dns_list[1]=Cloudflare 1.1.1.1 1.0.0.1 2606:4700:4700::1111
set dns_list[2]=KT 168.126.63.1 168.126.63.2 ::
set dns_list[3]=SK 219.250.36.130 210.220.163.82 ::
set dns_list[4]=LG 164.124.101.2 203.248.252.2 ::
set dns_list[5]=Quad9 9.9.9.9 149.112.112.112 2620:fe::fe
set dns_list[6]=OpenDNS 208.67.222.222 208.67.220.220 2620:119:35::35
set dns_list[7]=AdGuard 94.140.14.14 94.140.15.15 2a10:50c0::ad1:ff

set /a count=8

for /l %%i in (0,1,7) do (
    call :measure_dns %%i
)

echo ==================================================
echo [추천 결과] 최적 DNS: !best_name! (평균 !best_time! ms)
echo ==================================================

if "!best_name!"=="none" (
    echo 측정 실패. 수동으로 선택하세요.
    pause
    goto menu
)

call :setdns "!best_ip1!" "!best_ip2!" "!best_ip6!"
goto result_success

:measure_dns
set idx=%1
set name=
set ip1=
set ip2=
set ip6=

for /f "tokens=1-5" %%a in ("!dns_list[%idx%]!") do (
    set name=%%a
    set ip1=%%b
    set ip2=%%c
    set ip6=%%d
)

set total_time=0
set success=0

for /l %%t in (1,1,3) do (
    for /f "tokens=7 delims== " %%m in ('ping -n 2 !ip1! ^| find "평균" 2^>nul') do (
        set /a total_time+=%%m
        set /a success+=1
    )
)

if !success! gtr 0 (
    set /a avg_time=!total_time!/!success!
    echo !name!: !avg_time! ms
    if !avg_time! lss !best_time! (
        set best_time=!avg_time!
        set best_name=!name!
        set best_ip1=!ip1!
        set best_ip2=!ip2!
        set best_ip6=!ip6!
    )
) else (
    echo !name!: 측정 실패
)
exit /b

:speedtest_all
cls
echo ==================================================
echo        DNS 속도 테스트 (전체)
echo ==================================================
echo.

call :measure_dns 0
call :measure_dns 1
call :measure_dns 2
call :measure_dns 3
call :measure_dns 4
call :measure_dns 5
call :measure_dns 6
call :measure_dns 7

echo ==================================================
pause
goto menu

:dhcp
echo.
echo [적용 중] DHCP 자동 설정으로 복구...
netsh interface ipv4 set dns name="%adapter%" source=dhcp >nul 2>&1
netsh interface ipv6 set dns name="%adapter%" source=dhcp >nul 2>&1
goto result_success

:flushdns
echo.
echo [실행 중] DNS 캐시 초기화...
ipconfig /flushdns >nul 2>&1
echo DNS 캐시가 초기화되었습니다.
pause
goto menu

:showdns
cls
echo ==================================================
echo        현재 DNS 설정 [%adapter%]
echo ==================================================
echo.
echo [IPv4 DNS]
netsh interface ipv4 show dns name="%adapter%" | findstr "DNS"
echo.
echo [IPv6 DNS]
netsh interface ipv6 show dns name="%adapter%" | findstr "DNS"
echo.
pause
goto menu

:reset
echo.
echo [적용 중] 어댑터 재연결...
netsh interface set interface "%adapter%" admin=disable >nul 2>&1
timeout /t 2 /nobreak >nul
netsh interface set interface "%adapter%" admin=enable >nul 2>&1
echo 어댑터가 재연결되었습니다.
timeout /t 1 >nul
goto result_success

:result_success
echo.
echo [완료] DNS 설정이 성공적으로 변경되었습니다.
ipconfig /flushdns >nul 2>&1
echo.
echo [DNS 확인 테스트]
nslookup naver.com 2>nul
echo.
pause
goto menu

:result_error
echo.
echo [오류] DNS 설정에 실패했습니다.
echo 관리자 권한과 어댑터 이름을 확인하세요.
pause
goto menu
