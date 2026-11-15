$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'test_paths.ps1')
$root = Split-Path $PSScriptRoot -Parent
$output = Join-Path $root '.omo/evidence/f10-linux-godot-base-suite'
& (Get-TestPath 'docker') run --name rgss-linux-export-with-solution --mount "type=bind,source=$root,target=/repo,readonly" --mount "type=bind,source=$output,target=/output" $(Get-TestSetting 'linux_build_image') bash /repo/tools/export_linux_current_host.sh
$code = $LASTEXITCODE
Write-Output "LINUX_EXPORT_EXIT:$code"
exit $code
