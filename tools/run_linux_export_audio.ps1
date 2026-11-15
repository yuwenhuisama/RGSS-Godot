$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$output = Join-Path $root '.omo/evidence/f10-linux-godot-base-suite'
& 'C:/Program Files/Docker/Docker/resources/bin/docker.exe' run --rm --name rgss-linux-export-audio-mode --mount "type=bind,source=$root,target=/repo,readonly" --mount "type=bind,source=$output,target=/output" rgss-linux-godot-verified:local bash /repo/tools/repair_linux_export_audio_mode.sh
$code = $LASTEXITCODE
Write-Output "LINUX_EXPORT_AUDIO_EXIT:$code"
exit $code
