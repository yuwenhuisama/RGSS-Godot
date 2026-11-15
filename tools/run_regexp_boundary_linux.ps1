$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$output = Join-Path $root '.omo/evidence/submission-regexp-boundary'
New-Item -ItemType Directory -Force $output | Out-Null
$env:MSYS_NO_PATHCONV = '1'
& 'C:/Program Files/Docker/Docker/resources/bin/docker.exe' run --rm --name rgss-submission-regexp `
    --mount "type=bind,source=$root,target=/repo,readonly" `
    --mount "type=bind,source=$output,target=/output" `
    rgss-linux-godot-verified:local bash /repo/tools/build_regexp_boundary.sh /repo `
    /repo/.omo/evidence/f10-linux-current-mruby-config-fix/build/include /repo/Plugins/linux `
    /output/libmruby_onig_regexp_ext_x64.so
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& 'C:/Program Files/Docker/Docker/resources/bin/docker.exe' run --rm --name rgss-submission-regexp-test `
    --mount "type=bind,source=$root,target=/repo,readonly" `
    --mount "type=bind,source=$output,target=/output" `
    rgss-linux-godot-verified:local bash /repo/tools/test_regexp_boundary_linux.sh
exit $LASTEXITCODE
