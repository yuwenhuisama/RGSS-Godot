param([string]$EvidenceName = 'f11-linux-rendered-resource-profile')
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$output = Join-Path $root ('.omo/evidence/' + $EvidenceName)
$baseline = Join-Path $root '.omo/evidence/f10-linux-godot-base-suite'
if (Test-Path $output) { throw 'Linux dense-map evidence already exists; preserve the previous run.' }
$null = New-Item -ItemType Directory -Path (Join-Path $output 'profile')
& 'C:/Program Files/Docker/Docker/resources/bin/docker.exe' run --rm --name rgss-linux-dense-map --mount "type=bind,source=$root,target=/repo,readonly" --mount 'type=bind,source=E:/Projects/RMProject,target=/game/RMProject,readonly' --mount 'type=bind,source=F:/Softwares/RPG Maker VX Ace/RTP,target=/rtp,readonly' --mount "type=bind,source=$baseline,target=/baseline,readonly" --mount "type=bind,source=$output,target=/output" rgss-linux-godot-verified:local bash /repo/tools/test_linux_dense_map.sh
$code = $LASTEXITCODE
Write-Output "LINUX_RENDERED_DENSE_MAP_EXIT:$code"
exit $code
