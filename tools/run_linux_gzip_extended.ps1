param([string]$Mode = '')
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'test_paths.ps1')
$root = Split-Path $PSScriptRoot -Parent
$output = Join-Path $root '.omo/evidence/f10-linux-godot-base-suite'
& (Get-TestPath 'docker') run --rm --name rgss-linux-gzip-extended --mount "type=bind,source=$root,target=/repo,readonly" --mount ("type=bind,source=" + (Join-Path (Get-TestPath 'game_project') 'Data') + ",target=/game-data,readonly") --mount "type=bind,source=$output,target=/output" $(Get-TestSetting 'linux_build_image') bash /repo/tools/test_linux_gzip_extended.sh $Mode
$code = $LASTEXITCODE
Write-Output "LINUX_GZIP_EXTENDED_EXIT:$code"
exit $code
