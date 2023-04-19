@echo off
set scriptName=XWB-Repacker.ps1

for /f "delims=" %%i in ('PowerShell -Command "Get-ChildItem -Path '.\' -Filter '%scriptName%' -Recurse | Select-Object -ExpandProperty FullName | Resolve-Path -Relative"') do set scriptPath=%%i
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "& '%scriptPath%'"