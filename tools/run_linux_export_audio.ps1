$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'test_paths.ps1')
$root = Split-Path $PSScriptRoot -Parent
$output = Join-Path $root '.omo/evidence/f10-linux-godot-base-suite'
& (Get-TestPath 'docker') run --rm --name rgss-linux-export-audio-mode --mount "type=bind,source=$root,target=/repo,readonly" --mount "type=bind,source=$output,target=/output" $(Get-TestSetting 'linux_build_image') bash /repo/tools/repair_linux_export_audio_mode.sh
$code = $LASTEXITCODE
Write-Output "LINUX_EXPORT_AUDIO_EXIT:$code"
exit $code
