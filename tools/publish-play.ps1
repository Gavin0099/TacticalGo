param([switch]$SelfContained)
$ErrorActionPreference = 'Stop'
$repoPath = Split-Path $PSScriptRoot -Parent
$publishPath = Join-Path $repoPath 'dist/TacticalGo.Play'
dotnet publish (Join-Path $repoPath 'src/TacticalGo.Play/TacticalGo.Play.csproj') -c Release -r win-x64 --self-contained $SelfContained.IsPresent.ToString().ToLowerInvariant() -o $publishPath
if ($LASTEXITCODE -ne 0) { throw 'Windows publish failed.' }
@'
@echo off
cd /d "%~dp0"
start "" "TacticalGo.Play.exe" --free
'@ | Set-Content -LiteralPath (Join-Path $publishPath 'Start-7x7.cmd') -Encoding ascii
@'
@echo off
cd /d "%~dp0"
start "" "TacticalGo.Play.exe" --level 2
'@ | Set-Content -LiteralPath (Join-Path $publishPath 'Start-Tutorial-2.cmd') -Encoding ascii
Write-Output "Ready: $publishPath\Start-7x7.cmd"
