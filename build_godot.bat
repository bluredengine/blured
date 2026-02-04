@echo off
echo ============================================
echo Building Godot Engine for Windows
echo ============================================

REM Set up Visual Studio environment
call "G:\Microsoft Visual Studio\VC\Auxiliary\Build\vcvars64.bat"

REM Navigate to Godot source
cd /d "G:\makabaka-engine\godot"

REM Build Godot editor (release with debug symbols for development)
echo.
echo Starting SCons build... This will take 20-40 minutes.
echo.
python -m SCons platform=windows target=editor -j%NUMBER_OF_PROCESSORS%

echo.
echo Build complete! Check godot\bin\ for the executable.
pause
