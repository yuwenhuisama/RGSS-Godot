param([string]$EvidenceName = 'marshal-identity')
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$source = Join-Path $root 'mruby-ext/build/windows/x64/release/libmruby_marshal_c_ext_x64.dll'
$target = Join-Path $root 'Plugins/windows/libmruby_marshal_c_ext_x64.dll'
$evidence = Join-Path $root ('.omo/evidence/' + $EvidenceName)
if (Test-Path $evidence) { throw 'Identity deployment evidence already exists' }
New-Item -ItemType Directory -Path $evidence | Out-Null
Copy-Item $target (Join-Path $evidence 'prior-marshal.dll')
Copy-Item $source (Join-Path $evidence 'candidate-marshal.dll')
Copy-Item $source $target -Force
$sha = [System.Security.Cryptography.SHA256]::Create()
try {
    $hash = [BitConverter]::ToString($sha.ComputeHash([System.IO.File]::ReadAllBytes($source))).Replace('-', '')
    $targetHash = [BitConverter]::ToString($sha.ComputeHash([System.IO.File]::ReadAllBytes($target))).Replace('-', '')
} finally {
    $sha.Dispose()
}
if ($targetHash -ne $hash) { throw 'Deployment hash mismatch' }
Write-Output "MARSHAL_IDENTITY_DEPLOYED:$hash"
