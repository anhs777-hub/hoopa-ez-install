@echo off
setlocal EnableDelayedExpansion
title 후파의 이지워커 시즌2 - 자동 설치

set "EXTID=mgcelohlecfhdjnlfekdbfkepckdjggc"
set "BASE=https://limbj1218-cyber.github.io/hoopa-ez-dist"
set "DEST=%ProgramData%\HoopaEZ"

rem ── 관리자 권한 확인 (없으면 권한 요청 후 재실행) ──────────────
net session >nul 2>&1
if errorlevel 1 (
    echo.
    echo   관리자 권한이 필요합니다.
    echo   권한 요청 창이 뜨면 [예] 를 눌러주세요.
    echo.
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

cls
echo ============================================================
echo    후파의 이지워커 시즌2 - 자동 설치
echo ============================================================
echo.

echo   [1/5] 설치 허용 설정 중...
reg add "HKLM\Software\Policies\Google\Chrome\ExtensionInstallAllowlist" /v "1" /t REG_SZ /d "%EXTID%" /f >nul 2>&1
if errorlevel 1 goto :fail

rem ── 크롬 완전 종료 ────────────────────────────────────────────
rem   창을 닫아도 백그라운드에 남는 경우가 많다.
rem   /T 로 자식 프로세스까지, 사라질 때까지 반복해서 확실히 종료시킨다.
echo   [2/5] 크롬 종료 중...
set /a KILLTRY=0

:killchrome
taskkill /F /T /IM chrome.exe        >nul 2>&1
taskkill /F /T /IM chrome_proxy.exe  >nul 2>&1
taskkill /F /T /IM GoogleCrashHandler.exe   >nul 2>&1
taskkill /F /T /IM GoogleCrashHandler64.exe >nul 2>&1
ping -n 3 127.0.0.1 >nul

tasklist /FI "IMAGENAME eq chrome.exe" 2>nul | find /I "chrome.exe" >nul
if errorlevel 1 goto :chromedead

set /a KILLTRY+=1
echo         아직 실행 중입니다... 다시 종료합니다 (!KILLTRY!/5)
if !KILLTRY! lss 5 goto :killchrome
goto :chromealive

:chromedead
echo         크롬이 완전히 종료되었습니다.

echo   [3/5] 최신 버전 확인 중...
if not exist "%DEST%" mkdir "%DEST%" >nul 2>&1
curl.exe -s -L -o "%TEMP%\hoopa_ver.txt" "%BASE%/version.txt"
if errorlevel 1 goto :neterr
set "VER="
set /p VER=<"%TEMP%\hoopa_ver.txt"
if "%VER%"=="" goto :neterr
echo         최신 버전 : %VER%

echo   [4/5] 프로그램 파일 내려받는 중...
curl.exe -s -L -o "%TEMP%\hoopa_ez.zip" "%BASE%/hoopa-ez-install.zip"
if errorlevel 1 goto :neterr
tar.exe -xf "%TEMP%\hoopa_ez.zip" -C "%DEST%" >nul 2>&1
if not exist "%DEST%\hoopa-ez.crx" goto :fail

echo   [5/5] 크롬에 등록 중...
reg add "HKLM\Software\Google\Chrome\Extensions\%EXTID%" /v "path" /t REG_SZ /d "%DEST%\hoopa-ez.crx" /f >nul 2>&1
reg add "HKLM\Software\Google\Chrome\Extensions\%EXTID%" /v "version" /t REG_SZ /d "%VER%" /f >nul 2>&1
reg add "HKLM\Software\Wow6432Node\Google\Chrome\Extensions\%EXTID%" /v "path" /t REG_SZ /d "%DEST%\hoopa-ez.crx" /f >nul 2>&1
reg add "HKLM\Software\Wow6432Node\Google\Chrome\Extensions\%EXTID%" /v "version" /t REG_SZ /d "%VER%" /f >nul 2>&1

rem ── 크롬 실행 파일 위치 찾기 ──────────────────────────────────
set "CHROME="
if exist "%ProgramFiles%\Google\Chrome\Application\chrome.exe" set "CHROME=%ProgramFiles%\Google\Chrome\Application\chrome.exe"
if not defined CHROME if exist "%ProgramW6432%\Google\Chrome\Application\chrome.exe" set "CHROME=%ProgramW6432%\Google\Chrome\Application\chrome.exe"
if not defined CHROME if exist "%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe" set "CHROME=%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe"

echo.
echo ============================================================
echo    설정 완료  (버전 %VER%)
echo ============================================================
echo.
echo    설치 준비가 끝났습니다.
echo    크롬을 켜면 모든 프로필에 자동으로 설치됩니다.
echo.
echo    ###########################################################
echo    #                                                         #
echo    #   중요! 설치 후 반드시 [토글 스위치]를 켜주세요.        #
echo    #                                                         #
echo    #   크롬은 보안상 새로 설치된 확장을 꺼둔 상태로          #
echo    #   추가합니다. chrome://extensions 화면에서              #
echo    #   "후파의 이지워커 시즌2" 카드 오른쪽 아래의            #
echo    #   동그란 스위치를 눌러 파란색으로 바꿔주세요.           #
echo    #                                                         #
echo    ###########################################################
echo.

rem ── 어느 프로필로 열지 선택 ───────────────────────────────────
echo    ------------------------------------------------------
echo     어느 프로필을 열어서 확인하시겠습니까?
echo    ------------------------------------------------------
set /a IDX=0
for /f "usebackq tokens=1,2 delims=|" %%a in (`powershell -NoProfile -Command "$ls=Join-Path $env:LOCALAPPDATA 'Google\Chrome\User Data\Local State'; if(Test-Path $ls){$j=Get-Content $ls -Raw -Encoding UTF8 | ConvertFrom-Json; $j.profile.info_cache.PSObject.Properties | ForEach-Object { $_.Name + '|' + $_.Value.name + ' (' + $_.Value.user_name + ')' }}"`) do (
    set /a IDX+=1
    set "PDIR[!IDX!]=%%a"
    echo       !IDX!. %%b
)
if !IDX! equ 0 goto :openplain
echo       0. 그냥 기본 프로필로 열기
echo.
set "CHOICE="
set /p CHOICE=      번호를 입력하고 엔터 :
set "SEL="
if defined CHOICE call set "SEL=%%PDIR[!CHOICE!]%%"

echo.
echo    크롬을 실행합니다...
start "" "%DEST%"
if defined SEL (
    if defined CHROME (
        start "" "!CHROME!" --profile-directory="!SEL!" "chrome://extensions"
        goto :done
    )
)

:openplain
start "" "%DEST%"
if defined CHROME (
    start "" "!CHROME!" "chrome://extensions"
) else (
    start "" chrome "chrome://extensions"
)

:done
echo.
echo    ------------------------------------------------------
echo    크롬 화면에서 해주실 일
echo    ------------------------------------------------------
echo      1. "후파의 이지워커 시즌2" 카드를 찾습니다.
echo      2. 카드 오른쪽 아래  동그란 토글 스위치를 눌러
echo         파란색(켜짐)으로 바꿔주세요.
echo.
echo      * 확장 프로그램이 목록에 아예 없다면,
echo        열린 폴더의  hoopa-ez.crx  파일을
echo        chrome://extensions 화면으로 끌어다 놓아 주세요.
echo.
echo    창을 닫으셔도 됩니다.
echo.
pause
exit /b 0

:chromealive
echo.
echo ============================================================
echo    크롬을 종료하지 못했습니다
echo ============================================================
echo.
echo    크롬이 계속 실행 중이라 설치를 진행할 수 없습니다.
echo    아래 방법으로 직접 종료한 뒤 이 파일을 다시 실행해 주세요.
echo.
echo      1. Ctrl + Shift + Esc  를 눌러 작업 관리자 열기
echo      2. 프로세스 탭에서  Google Chrome  찾기
echo      3. 오른쪽 클릭 - "작업 끝내기" 선택
echo.
echo    작업 관리자를 열어 드립니다.
echo.
pause
start "" taskmgr
exit /b 1

:neterr
echo.
echo    [오류] 파일을 내려받지 못했습니다.
echo           인터넷 연결을 확인한 뒤 다시 실행해 주세요.
echo.
pause
exit /b 1

:fail
echo.
echo    [오류] 설치에 실패했습니다.
echo           이 파일을 오른쪽 클릭 - "관리자 권한으로 실행" 으로
echo           다시 시도해 주세요.
echo.
pause
exit /b 1
