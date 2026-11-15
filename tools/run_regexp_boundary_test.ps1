$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'test_paths.ps1')
$root = Split-Path $PSScriptRoot -Parent
$output = Join-Path $root '.omo/evidence/submission-regexp-boundary'
New-Item -ItemType Directory -Force $output | Out-Null
$env:MSYS_NO_PATHCONV = '1'
& (Get-TestPath 'docker') run --rm --name rgss-submission-regexp-test `
    --mount "type=bind,source=$root,target=/repo,readonly" `
    --mount "type=bind,source=$output,target=/output" `
    $(Get-TestSetting 'linux_build_image') bash /repo/tools/test_regexp_boundary_linux.sh
exit $LASTEXITCODE
