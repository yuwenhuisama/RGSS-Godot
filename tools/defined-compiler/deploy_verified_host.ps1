$ErrorActionPreference = 'Stop'
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$stage = Join-Path $root '.omo/compatibility-run-tmp/f05-defined-compiler/wrapper-fix-direct-stage'
$evidence = Join-Path $root '.omo/evidence/f05-host-deployment'
if (Test-Path $evidence) { throw 'Host deployment evidence already exists' }
$actual = (Get-Content (Join-Path $stage 'defined_yield_super_reference.tsv') -Raw).Replace("`r`n", "`n").Trim()
$expected = (Get-Content (Join-Path $PSScriptRoot 'defined_yield_super_original.tsv') -Raw).Replace("`r`n", "`n").Trim()
if ($actual -ne $expected) { throw 'Candidate77-row evidence differs' }
New-Item -ItemType Directory -Path $evidence | Out-Null
foreach ($name in @('libmruby_x64.dll', 'libmruby_onig_regexp_ext_x64.dll')) {
    $target = Join-Path $root ('Plugins/windows/' + $name)
    Copy-Item $target (Join-Path $evidence ('prior-' + $name))
    Copy-Item (Join-Path $stage $name) (Join-Path $evidence ('candidate-' + $name))
    Copy-Item (Join-Path $stage $name) $target -Force
}
Write-Output 'DEFINED_VERIFIED_HOST_DEPLOYED'
