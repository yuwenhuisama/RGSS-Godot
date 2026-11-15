$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'test_paths.ps1')
$root = Split-Path $PSScriptRoot -Parent
$output = Join-Path $root '.omo/evidence/f10-linux-shared-host'
& (Get-TestPath 'docker') run --rm --name rgss-linux-shared-probe --mount "type=bind,source=$root,target=/repo,readonly" --mount "type=bind,source=$output,target=/output" ubuntu:24.04 bash /repo/tools/test_linux_shared_host.sh
$code = $LASTEXITCODE
Write-Output "LINUX_SHARED_PROBE_EXIT:$code"
exit $code
