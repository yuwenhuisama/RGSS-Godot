param([string]$EvidenceName = 'f11-linux-rendered-resource-profile')
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'test_paths.ps1')
$root = Split-Path $PSScriptRoot -Parent
$output = Join-Path $root ('.omo/evidence/' + $EvidenceName)
$baseline = Join-Path $root '.omo/evidence/f10-linux-godot-base-suite'
if (Test-Path $output) { throw 'Linux dense-map evidence already exists; preserve the previous run.' }
$null = New-Item -ItemType Directory -Path (Join-Path $output 'profile')
& (Get-TestPath 'docker') run --rm --name rgss-linux-dense-map --mount "type=bind,source=$root,target=/repo,readonly" --mount ("type=bind,source=" + (Get-TestPath 'game_project') + ",target=/game/RMProject,readonly") --mount ("type=bind,source=" + (Get-TestPath 'rtp') + ",target=/rtp,readonly") --mount "type=bind,source=$baseline,target=/baseline,readonly" --mount "type=bind,source=$output,target=/output" $(Get-TestSetting 'linux_build_image') bash /repo/tools/test_linux_dense_map.sh
$code = $LASTEXITCODE
Write-Output "LINUX_RENDERED_DENSE_MAP_EXIT:$code"
exit $code
