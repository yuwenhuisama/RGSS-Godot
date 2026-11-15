$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$output = Join-Path $root '.omo/evidence/f10-linux-godot-base-suite'
& 'C:/Program Files/Docker/Docker/resources/bin/docker.exe' run --rm --name rgss-linux-database-data --mount "type=bind,source=$root,target=/repo,readonly" --mount 'type=bind,source=E:/Projects/RMProject/Data,target=/game-data,readonly' --mount "type=bind,source=$output,target=/output" rgss-linux-godot-verified:local bash /repo/tools/test_linux_database_data.sh
$code = $LASTEXITCODE
Write-Output "LINUX_DATABASE_DATA_EXIT:$code"
exit $code
