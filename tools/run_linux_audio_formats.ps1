param([string]$Mode = '')
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$output = Join-Path $root '.omo/evidence/f10-linux-godot-base-suite'
& 'C:/Program Files/Docker/Docker/resources/bin/docker.exe' run --rm --name rgss-linux-audio-formats --mount "type=bind,source=$root,target=/repo,readonly" --mount 'type=bind,source=F:/Softwares/RPG Maker VX Ace/RTP,target=/rtp,readonly' --mount "type=bind,source=$output,target=/output" rgss-linux-godot-verified:local bash /repo/tools/test_linux_audio_formats.sh $Mode
$code = $LASTEXITCODE
Write-Output "LINUX_AUDIO_FORMATS_EXIT:$code"
exit $code
