param([string]$PackageName='linux-midi-release',[string]$EvidenceName='linux-midi-release-clean')
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'test_paths.ps1')
$root=Split-Path $PSScriptRoot -Parent
$package=Join-Path $root ".omo/evidence/$PackageName/linux-headless-verified.tar"
$output=Join-Path $root ".omo/evidence/$EvidenceName"
if(Test-Path $output){throw 'Preserve existing MIDI Release evidence.'}
New-Item -ItemType Directory $output | Out-Null
& (Get-TestPath 'docker') run --rm --network none --mount "type=bind,source=$root,target=/repo,readonly" --mount "type=bind,source=$package,target=/package.tar,readonly" --mount "type=bind,source=$output,target=/evidence" rgss-linux-clean-runtime:local bash /repo/tools/test_linux_release_midi.sh
exit $LASTEXITCODE
