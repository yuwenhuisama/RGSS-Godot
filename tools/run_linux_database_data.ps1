$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'test_paths.ps1')
$root = Split-Path $PSScriptRoot -Parent
$output = Join-Path $root '.omo/evidence/f10-linux-godot-base-suite'
& (Get-TestPath 'docker') run --rm --name rgss-linux-database-data --mount "type=bind,source=$root,target=/repo,readonly" --mount ("type=bind,source=" + (Join-Path (Get-TestPath 'game_project') 'Data') + ",target=/game-data,readonly") --mount "type=bind,source=$output,target=/output" $(Get-TestSetting 'linux_build_image') bash /repo/tools/test_linux_database_data.sh
$code = $LASTEXITCODE
Write-Output "LINUX_DATABASE_DATA_EXIT:$code"
exit $code
