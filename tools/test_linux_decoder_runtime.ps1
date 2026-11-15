$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$output = Join-Path $root '.omo/evidence/audio-decoder/linux'
& 'C:/Program Files/Docker/Docker/resources/bin/docker.exe' run --rm --name rgss-wma-linux-runtime --network none --mount "type=bind,source=$root,target=/repo,readonly" --mount "type=bind,source=$output,target=/output" ubuntu:24.04 /repo/Plugins/linux/audio/ffmpeg -hide_banner -loglevel error -y -i /repo/tests/fixtures/audio/tone.wma -vn -acodec pcm_s16le /output/production-path-runtime.wav
$code = $LASTEXITCODE
Write-Output "LINUX_CLEAN_DECODER_EXIT:$code"
exit $code
