$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$output = Join-Path $root '.omo/evidence/f10-linux-godot-base-suite'
& 'C:/Program Files/Docker/Docker/resources/bin/docker.exe' run --rm --network none --name rgss-linux-current-package --mount "type=bind,source=$root,target=/repo,readonly" --mount "type=bind,source=$output,target=/output" rgss-linux-clean-runtime:local bash /repo/tools/test_linux_current_package.sh
$code = $LASTEXITCODE
Write-Output "LINUX_CURRENT_PACKAGE_EXIT:$code"
exit $code
