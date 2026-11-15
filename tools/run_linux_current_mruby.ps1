param([string]$EvidenceName = 'f10-linux-current-mruby')
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$output = Join-Path $root ('.omo/evidence/' + $EvidenceName)
if (Test-Path $output) { throw 'Linux mruby evidence already exists' }
New-Item -ItemType Directory -Path $output | Out-Null
& 'C:/Program Files/Docker/Docker/resources/bin/docker.exe' run --rm --name rgss-current-mruby-linux --mount "type=bind,source=$root,target=/repo,readonly" --mount "type=bind,source=$output,target=/output" ubuntu:24.04 bash /repo/tools/build_linux_current_mruby.sh
$code = $LASTEXITCODE
Write-Output "LINUX_CURRENT_MRUBY_EXIT:$code"
exit $code
