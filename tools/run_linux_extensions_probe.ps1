$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'test_paths.ps1')
$root = Split-Path $PSScriptRoot -Parent
$output = Join-Path $root '.omo/evidence/f08-linux-all-extensions'
& (Get-TestPath 'docker') run --rm --name rgss-linux-extensions-probe --mount "type=bind,source=$root,target=/repo,readonly" --mount "type=bind,source=$output,target=/output" ubuntu:24.04 bash /repo/tools/test_linux_extensions.sh
$code = $LASTEXITCODE
Write-Output "LINUX_EXTENSIONS_PROBE_EXIT:$code"
exit $code
