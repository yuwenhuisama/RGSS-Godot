$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$source = Join-Path $root '.omo/evidence/windows-defined-host-install/install'
$work = Join-Path $root '.omo/evidence/windows-relocated-install'
if (Test-Path $work) { throw 'Relocated installation evidence already exists' }
New-Item -ItemType Directory -Path $work | Out-Null
Copy-Item $source (Join-Path $work 'install') -Recurse
New-Item -ItemType Directory -Path (Join-Path $work 'empty-working-directory') | Out-Null
Write-Output 'RELOCATED_INSTALL_READY'
