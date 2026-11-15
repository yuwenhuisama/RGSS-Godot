$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'test_paths.ps1')
& (Get-TestPath 'docker') build --tag rgss-linux-clean-runtime:local --file (Join-Path $PSScriptRoot 'linux_clean_runtime.Dockerfile') $PSScriptRoot
exit $LASTEXITCODE
