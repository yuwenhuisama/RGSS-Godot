param([string]$EvidenceName = 'f10-linux-godot-host', [string]$Mode = '')
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'test_paths.ps1')
$root = Split-Path $PSScriptRoot -Parent
$output = Join-Path $root ('.omo/evidence/' + $EvidenceName)
if (Test-Path $output) { throw 'Linux Godot host evidence already exists' }
New-Item -ItemType Directory -Path $output | Out-Null
& (Get-TestPath 'docker') run --name rgss-linux-godot-suite --mount "type=bind,source=$root,target=/repo,readonly" --mount "type=bind,source=$output,target=/output" ubuntu:24.04 bash /repo/tools/test_linux_godot_host.sh $Mode
$code = $LASTEXITCODE
Write-Output "LINUX_GODOT_HOST_EXIT:$code"
exit $code
