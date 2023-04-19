@echo off
for /f "delims=" %%i in ('PowerShell -Command "Get-ChildItem -Path '.\' -Filter 'XWB-Repacker.ps1' -Recurse | Select-Object -ExpandProperty FullName | Resolve-Path -Relative"') do set scriptPath=%%i
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "& '%scriptPath%'"