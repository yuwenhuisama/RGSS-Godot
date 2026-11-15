$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$evidence = Join-Path $root '.omo/evidence/glob-private-match'
if (Test-Path $evidence) { throw 'Glob deployment evidence already exists' }
New-Item -ItemType Directory -Path $evidence | Out-Null
$target = Join-Path $root 'Plugins/windows/libmruby_dir_glob_ext_x64.dll'
$candidate = Join-Path $root 'mruby-ext/build/windows/x64/release/libmruby_dir_glob_ext_x64.dll'
Copy-Item $target (Join-Path $evidence 'prior-glob.dll')
Copy-Item $candidate (Join-Path $evidence 'candidate-glob.dll')
Copy-Item $candidate $target -Force
Write-Output 'GLOB_PRIVATE_MATCH_DEPLOYED'
