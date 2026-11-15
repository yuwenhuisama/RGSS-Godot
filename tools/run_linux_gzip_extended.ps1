param([string]$Mode = '')
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$output = Join-Path $root '.omo/evidence/f10-linux-godot-base-suite'
& 'C:/Program Files/Docker/Docker/resources/bin/docker.exe' run --rm --name rgss-linux-gzip-extended --mount "type=bind,source=$root,target=/repo,readonly" --mount 'type=bind,source=E:/Projects/RMProject/Data,target=/game-data,readonly' --mount "type=bind,source=$output,target=/output" rgss-linux-godot-verified:local bash /repo/tools/test_linux_gzip_extended.sh $Mode
$code = $LASTEXITCODE
Write-Output "LINUX_GZIP_EXTENDED_EXIT:$code"
exit $code
