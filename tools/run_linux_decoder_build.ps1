$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$output = Join-Path $root '.omo/evidence/audio-decoder/linux'
if (Test-Path $output) { throw 'Linux decoder evidence already exists' }
New-Item -ItemType Directory -Path $output | Out-Null
& 'C:/Program Files/Docker/Docker/resources/bin/docker.exe' run --rm --name rgss-wma-linux-build --mount "type=bind,source=$root,target=/repo,readonly" --mount "type=bind,source=$output,target=/output" ubuntu:24.04 bash /repo/tools/build_linux_decoder_container.sh
$code = $LASTEXITCODE
Write-Output "LINUX_DECODER_CONTAINER_EXIT:$code"
exit $code
