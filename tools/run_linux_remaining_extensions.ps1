$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$output = Join-Path $root '.omo/evidence/f08-linux-all-extensions'
if (Test-Path $output) { throw 'Linux extension evidence already exists' }
New-Item -ItemType Directory -Path $output | Out-Null
& 'C:/Program Files/Docker/Docker/resources/bin/docker.exe' run --rm --name rgss-linux-extensions --mount "type=bind,source=$root,target=/repo,readonly" --mount "type=bind,source=$output,target=/output" ubuntu:24.04 bash /repo/tools/build_linux_remaining_extensions.sh
$code = $LASTEXITCODE
Write-Output "LINUX_EXTENSIONS_EXIT:$code"
exit $code
