param([Parameter(Mandatory=$true)][string]$Destination)
$ErrorActionPreference = 'Stop'
$project = Split-Path $PSScriptRoot -Parent
if (!(Test-Path (Join-Path $Destination 'RGSS-Godot.exe'))) {
    throw 'Export RGSS-Godot.exe before packaging its filesystem resources'
}
Copy-Item (Join-Path $project 'RGSS') $Destination -Recurse -Force
$config = @{ project_path = '.'; rtp_path = 'RTP'; legacy_mode = $true;
    legacy_mode_width = 544; legacy_mode_height = 416; cn_ver_rmva = $true }
$config | ConvertTo-Json | Set-Content (Join-Path $Destination 'rm_conf.json') -Encoding UTF8
Write-Output 'WINDOWS_FILESYSTEM_PACKAGE_PASS'
