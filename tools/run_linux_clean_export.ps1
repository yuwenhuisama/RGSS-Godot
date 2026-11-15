$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/test_paths.ps1"
$root = Split-Path $PSScriptRoot -Parent
$output = Join-Path $root '.omo/evidence/f10-linux-godot-base-suite'
& (Get-TestPath 'docker') run --rm --name rgss-linux-clean-export --network none --mount "type=bind,source=$output/install,target=/install,readonly" --mount "type=bind,source=$output,target=/evidence" --mount "type=bind,source=$root/tools/test_linux_clean_export.sh,target=/check.sh,readonly" --mount "type=bind,source=$root/.omo/evidence/audio-decoder/linux/decoded.wav,target=/reference.wav,readonly" rgss-linux-clean-runtime:local bash /check.sh
$code = $LASTEXITCODE
Write-Output "LINUX_CLEAN_EXPORT_EXIT:$code"
exit $code
