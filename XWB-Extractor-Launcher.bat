@echo off
set scriptName=XWB-Extractor.ps1

for /f "delims=" %%i in ('PowerShell -Command "Get-ChildItem -Path '.\' -Filter '%scriptName%' -Recurse | Select-Object -ExpandProperty FullName | Resolve-Path -Relative"') do set scriptPath=%%i
pwsh.exe -noexit -NoProfile -ExecutionPolicy Bypass -Command "& '%scriptPath%'"