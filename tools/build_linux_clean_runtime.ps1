$ErrorActionPreference = 'Stop'
& 'C:/Program Files/Docker/Docker/resources/bin/docker.exe' build --tag rgss-linux-clean-runtime:local --file (Join-Path $PSScriptRoot 'linux_clean_runtime.Dockerfile') $PSScriptRoot
exit $LASTEXITCODE
