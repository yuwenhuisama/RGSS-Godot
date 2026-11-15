param([string]$Name = 'f10-linux-release-export')
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'test_paths.ps1')
$root = Split-Path $PSScriptRoot -Parent
$baseline = Join-Path $root '.omo/evidence/f10-linux-godot-base-suite'
$output = Join-Path $root ('.omo/evidence/' + $Name)
if (Test-Path $output) { throw 'Release evidence directory already exists; preserve the previous run.' }
$null = New-Item -ItemType Directory -Path $output
$docker = Get-TestPath 'docker'
& $docker run --rm --name rgss-linux-release-export --mount "type=bind,source=$root,target=/repo,readonly" --mount "type=bind,source=$baseline,target=/baseline,readonly" --mount "type=bind,source=$output,target=/output" $(Get-TestSetting 'linux_build_image') bash /repo/tools/export_linux_release.sh
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $docker run --rm --network none --mount "type=bind,source=$output/linux-headless-verified.tar,target=/package.tar,readonly" --mount "type=bind,source=$output,target=/evidence" --mount "type=bind,source=$root/tools/test_linux_clean_export.sh,target=/check.sh,readonly" --mount "type=bind,source=$root/.omo/evidence/audio-decoder/linux/decoded.wav,target=/reference.wav,readonly" rgss-linux-clean-runtime:local bash /check.sh
$code = $LASTEXITCODE
Write-Output "LINUX_RELEASE_CLEAN_EXIT:$code"
exit $code
