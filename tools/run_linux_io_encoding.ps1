param([string]$Name='file-binary-native')
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'test_paths.ps1')
$root=Split-Path $PSScriptRoot -Parent
$output=Join-Path $root ".omo/evidence/$Name"
if(Test-Path $output){throw 'Preserve existing native candidate.'}
New-Item -ItemType Directory $output | Out-Null
& (Get-TestPath 'docker') run --rm --network none --mount "type=bind,source=$root,target=/repo,readonly" --mount "type=bind,source=$output,target=/output" $(Get-TestSetting 'linux_build_image') bash /repo/tools/build_linux_io_encoding.sh
exit $LASTEXITCODE
