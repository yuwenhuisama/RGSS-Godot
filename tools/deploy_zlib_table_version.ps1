param([string]$EvidenceName = 'zlib-table-version')
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$source = Join-Path $root 'mruby-ext/build/windows/x64/release/libmruby_zlib_ext_x64.dll'
$target = Join-Path $root 'Plugins/windows/libmruby_zlib_ext_x64.dll'
$evidence = Join-Path $root ('.omo/evidence/' + $EvidenceName)
if (Test-Path $evidence) { throw 'Deployment evidence already exists' }
New-Item -ItemType Directory -Path $evidence | Out-Null
Copy-Item $target (Join-Path $evidence 'prior-zlib.dll')
Copy-Item $source (Join-Path $evidence 'candidate-zlib.dll')
Copy-Item $source $target -Force
Write-Output 'ZLIB_TABLE_VERSION_DEPLOYED'
