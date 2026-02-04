@echo off
echo ============================================
echo Starting Makabaka Engine
echo ============================================

REM Check if AI server is already running
curl -s http://localhost:4096/godot/health >nul 2>&1
if %errorlevel% equ 0 (
    echo AI Server already running on port 4096
) else (
    echo Starting AI Server on port 4096...
    start "" /B "%~dp0opencode\packages\opencode\dist\opencode-windows-x64\bin\opencode.exe" serve --port 4096
    timeout /t 3 /nobreak > nul
)

REM Start Makabaka Engine (Godot with native AI module)
set "PROJECT_PATH=G:\MakabakaGames\Test"
echo Starting Makabaka Engine...
start "" "%~dp0godot\bin\godot.windows.editor.x86_64.exe" --path "%PROJECT_PATH%" --editor

echo.
echo Makabaka Engine started!
echo - AI Server: http://localhost:4096
echo - Makabaka Editor: Opening %PROJECT_PATH%
echo - AI Assistant: Built-in (bottom panel)
echo.
pause
2