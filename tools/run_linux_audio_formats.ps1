param([string]$Mode = '')
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'test_paths.ps1')
$root = Split-Path $PSScriptRoot -Parent
$output = Join-Path $root '.omo/evidence/f10-linux-godot-base-suite'
& (Get-TestPath 'docker') run --rm --name rgss-linux-audio-formats --mount "type=bind,source=$root,target=/repo,readonly" --mount ("type=bind,source=" + (Get-TestPath 'rtp') + ",target=/rtp,readonly") --mount "type=bind,source=$output,target=/output" $(Get-TestSetting 'linux_build_image') bash /repo/tools/test_linux_audio_formats.sh $Mode
$code = $LASTEXITCODE
Write-Output "LINUX_AUDIO_FORMATS_EXIT:$code"
exit $code
