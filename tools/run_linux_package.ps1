$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$output = Join-Path $root '.omo/evidence/f10-linux-godot-base-suite'
& 'C:/Program Files/Docker/Docker/resources/bin/docker.exe' run --rm --network none --mount "type=bind,source=$output,target=/output" --mount "type=bind,source=$root/tools/package_linux_verified.sh,target=/package.sh,readonly" ubuntu:24.04 bash /package.sh
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& 'C:/Program Files/Docker/Docker/resources/bin/docker.exe' run --rm --network none --mount "type=bind,source=$output/linux-headless-verified.tar,target=/package.tar,readonly" --mount "type=bind,source=$output,target=/evidence" --mount "type=bind,source=$root/tools/test_linux_clean_export.sh,target=/check.sh,readonly" --mount "type=bind,source=$root/.omo/evidence/audio-decoder/linux/decoded.wav,target=/reference.wav,readonly" rgss-linux-clean-runtime:local bash /check.sh
$code = $LASTEXITCODE
Write-Output "LINUX_ARCHIVED_PACKAGE_EXIT:$code"
exit $code
