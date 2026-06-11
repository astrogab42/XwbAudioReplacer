@echo off
REM XWB-AudioReplacer - XWB-Extractor-Launcher.bat
REM Copyright (C) 2026 Steve2811, astrogab42, Piero-93
REM
REM This program is free software: you can redistribute it and/or modify
REM it under the terms of the GNU General Public License as published by
REM the Free Software Foundation, either version 3 of the License, or
REM (at your option) any later version.
REM
REM This program is distributed in the hope that it will be useful,
REM but WITHOUT ANY WARRANTY; without even the implied warranty of
REM MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
REM GNU General Public License for more details.
REM
REM You should have received a copy of the GNU General Public License
REM along with this program.  If not, see <https://www.gnu.org/licenses/>.

set scriptName=XWB-Extractor.ps1

for /f "delims=" %%i in ('PowerShell -Command "Get-ChildItem -Path '.\' -Filter '%scriptName%' -Recurse | Select-Object -ExpandProperty FullName | Resolve-Path -Relative"') do set scriptPath=%%i
pwsh.exe -noexit -NoProfile -ExecutionPolicy Bypass -Command "& '%scriptPath%'"