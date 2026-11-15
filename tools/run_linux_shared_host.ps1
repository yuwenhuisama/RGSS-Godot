$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'test_paths.ps1')
$root = Split-Path $PSScriptRoot -Parent
$output = Join-Path $root '.omo/evidence/f10-linux-shared-host'
if (Test-Path $output) { throw 'Shared host evidence already exists' }
New-Item -ItemType Directory -Path $output | Out-Null
& (Get-TestPath 'docker') run --rm --name rgss-shared-host-linux --mount "type=bind,source=$root,target=/repo,readonly" --mount "type=bind,source=$output,target=/output" ubuntu:24.04 bash /repo/tools/build_linux_shared_host.sh
$code = $LASTEXITCODE
Write-Output "LINUX_SHARED_HOST_EXIT:$code"
exit $code
