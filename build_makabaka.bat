@echo off
echo ============================================
echo Building Makabaka Engine
echo ============================================
echo.

REM Check if we should skip certain builds
set SKIP_OPENCODE=0
set SKIP_GODOT=0

if "%1"=="--opencode-only" set SKIP_GODOT=1
if "%1"=="--godot-only" set SKIP_OPENCODE=1

REM Build OpenCode
if %SKIP_OPENCODE%==0 (
    echo [1/2] Building OpenCode...
    echo ----------------------------------------
    cd /d "G:\makabaka-engine\opencode\packages\opencode"

    REM Clean previous build
    if exist dist rmdir /s /q dist

    REM Build
    call bun run build --single

    if errorlevel 1 (
        echo.
        echo ERROR: OpenCode build failed!
        pause
        exit /b 1
    )
    echo OpenCode build complete!
    echo.
) else (
    echo [1/2] Skipping OpenCode build...
    echo.
)

REM Build Godot
if %SKIP_GODOT%==0 (
    echo [2/2] Building Godot Engine...
    echo ----------------------------------------

    REM Set up Visual Studio environment
    call "G:\Microsoft Visual Studio\VC\Auxiliary\Build\vcvars64.bat" >nul 2>&1

    cd /d "G:\makabaka-engine\godot"

    echo Starting SCons build...
    python -m SCons platform=windows target=editor d3d12=no -j%NUMBER_OF_PROCESSORS%

    if errorlevel 1 (
        echo.
        echo ERROR: Godot build failed!
        echo If the error mentions "Access denied", make sure Godot editor is closed.
        pause
        exit /b 1
    )
    echo Godot build complete!
    echo.
) else (
    echo [2/2] Skipping Godot build...
    echo.
)

echo ============================================
echo Makabaka Engine build complete!
echo ============================================
echo.
echo Usage:
echo   build_makabaka.bat              - Build both OpenCode and Godot
echo   build_makabaka.bat --opencode-only  - Build only OpenCode
echo   build_makabaka.bat --godot-only     - Build only Godot
echo.
echo Run start_makabaka.bat to launch the engine.
echo.
pause
