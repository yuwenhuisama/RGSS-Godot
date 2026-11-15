param([string]$StageName = 'wrapper-fix-stage')
$ErrorActionPreference = 'Stop'
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$owned = Join-Path $root '.omo/compatibility-run-tmp/f05-defined-compiler'
$stage = Join-Path $owned $StageName
if (Test-Path $stage) { throw 'Wrapper fix stage already exists' }
New-Item -ItemType Directory -Path $stage | Out-Null
Copy-Item (Join-Path $owned 'extended-host-stage/extended_host_probe.exe') $stage
Copy-Item (Join-Path $owned 'mruby-shared/build/windows/x64/release/libmruby_x64.dll') $stage
Copy-Item (Join-Path $root 'Plugins/windows/*_ext_x64.dll') $stage
Copy-Item (Join-Path $root 'mruby-ext/build/windows/x64/release/libmruby_onig_regexp_ext_x64.dll') $stage -Force
& (Join-Path $stage 'extended_host_probe.exe') (Join-Path $root 'RGSS') $stage (Join-Path $PSScriptRoot 'defined_yield_super_reference.rb') (Join-Path $root 'tests/fixtures/ruby_runtime_reference.rb') '' (Join-Path $root 'tests/fixtures/zlib_stream_reference.rb')
if ($LASTEXITCODE -ne 0) { throw "Wrapper probe failed: $LASTEXITCODE" }
Write-Output 'WRAPPER_FIX_PROBE_EXECUTED'
