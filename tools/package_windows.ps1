param([Parameter(Mandatory=$true)][string]$Destination)
$ErrorActionPreference = 'Stop'
$project = Split-Path $PSScriptRoot -Parent
if (!(Test-Path (Join-Path $Destination 'RGSS-Godot.exe'))) {
    throw 'Export RGSS-Godot.exe before packaging its filesystem resources'
}
Copy-Item (Join-Path $project 'RGSS') $Destination -Recurse -Force
Copy-Item (Join-Path $project 'rm_conf.json') $Destination -Force
Write-Output 'WINDOWS_FILESYSTEM_PACKAGE_PASS'
