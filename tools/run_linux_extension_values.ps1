$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$output = Join-Path $root '.omo/evidence/f08-linux-all-extensions'
& 'C:/Program Files/Docker/Docker/resources/bin/docker.exe' run --rm --name rgss-linux-extension-values --mount "type=bind,source=$root,target=/repo,readonly" --mount "type=bind,source=$output,target=/output" ubuntu:24.04 bash /repo/tools/test_linux_extension_values.sh
$code = $LASTEXITCODE
Write-Output "LINUX_EXTENSION_VALUES_EXIT:$code"
exit $code
