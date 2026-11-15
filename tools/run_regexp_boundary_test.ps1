$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$output = Join-Path $root '.omo/evidence/submission-regexp-boundary'
$env:MSYS_NO_PATHCONV = '1'
& 'C:/Program Files/Docker/Docker/resources/bin/docker.exe' run --rm --name rgss-submission-regexp-test `
    --mount "type=bind,source=$root,target=/repo,readonly" `
    --mount "type=bind,source=$output,target=/output" `
    rgss-linux-godot-verified:local bash /repo/tools/test_regexp_boundary_linux.sh
exit $LASTEXITCODE
