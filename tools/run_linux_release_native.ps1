param([string]$EvidenceName = 'f10-linux-release-native', [string]$PackageName = 'f10-linux-release-export')
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$package = Join-Path $root ('.omo/evidence/' + $PackageName + '/linux-headless-verified.tar')
$output = Join-Path $root ('.omo/evidence/' + $EvidenceName)
if (Test-Path $output) { throw 'Native Release evidence already exists; preserve the previous run.' }
$null = New-Item -ItemType Directory -Path $output
& 'C:/Program Files/Docker/Docker/resources/bin/docker.exe' run --rm --network none --mount "type=bind,source=$root,target=/repo,readonly" --mount "type=bind,source=$package,target=/package.tar,readonly" --mount "type=bind,source=$output,target=/evidence" rgss-linux-clean-runtime:local bash /repo/tools/test_linux_release_native.sh
$code = $LASTEXITCODE
Write-Output "LINUX_RELEASE_CLEAN_NATIVE_EXIT:$code"
exit $code
