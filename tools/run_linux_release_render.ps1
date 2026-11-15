param([string]$EvidenceName = 'f10-linux-release-render')
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'test_paths.ps1')
$root = Split-Path $PSScriptRoot -Parent
$package = Join-Path $root '.omo/evidence/f10-linux-release-export/linux-headless-verified.tar'
$output = Join-Path $root ('.omo/evidence/' + $EvidenceName)
if (Test-Path $output) { throw 'Render evidence already exists; preserve the previous run.' }
$null = New-Item -ItemType Directory -Path $output
& (Get-TestPath 'docker') run --rm --mount "type=bind,source=$root,target=/repo,readonly" --mount "type=bind,source=$package,target=/package.tar,readonly" --mount "type=bind,source=$output,target=/evidence" $(Get-TestSetting 'linux_build_image') bash /repo/tools/test_linux_release_render.sh
$code = $LASTEXITCODE
Write-Output "LINUX_RELEASE_RENDER_EXIT:$code"
exit $code
