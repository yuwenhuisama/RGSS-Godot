$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$output = Join-Path $root '.omo/evidence/f10-linux-godot-base-suite'
& 'C:/Program Files/Docker/Docker/resources/bin/docker.exe' run --name rgss-linux-export-with-solution --mount "type=bind,source=$root,target=/repo,readonly" --mount "type=bind,source=$output,target=/output" rgss-linux-godot-verified:local bash /repo/tools/export_linux_current_host.sh
$code = $LASTEXITCODE
Write-Output "LINUX_EXPORT_EXIT:$code"
exit $code
