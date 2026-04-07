@echo on
NET SESSION >nul 2>&1
IF %ERRORLEVEL% EQU 0 (
echo 관리자권한
cd C:\Program Files\iSecuService\private
icacls *.sys /deny everyone:f
icacls *.exe /deny everyone:f
echo 재부팅 후 C:\Program Files\iSecuService  에서 private 폴더 모두 삭제
