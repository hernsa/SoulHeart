@echo off
title SoulHeart
cd /d "%~dp0"
if exist "dist\SoulHeart.exe" (
    start "" "dist\SoulHeart.exe"
) else (
    start "" "tools\godot.exe" --path "%~dp0"
)
