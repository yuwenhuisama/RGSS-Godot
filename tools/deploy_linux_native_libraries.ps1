$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$destination = Join-Path $root 'Plugins/linux'
$sources = @{
    'libmruby_x64.so' = '.omo/evidence/f08-linux-all-extensions/libmruby_x64.so'
    'libmruby_marshal_c_ext_x64.so' = '.omo/evidence/f08-linux-all-extensions/libmruby_marshal_c_ext_x64.so'
    'libmruby_onig_regexp_ext_x64.so' = '.omo/evidence/f08-linux-all-extensions/libmruby_onig_regexp_ext_x64.so'
    'libmruby_dir_glob_ext_x64.so' = '.omo/evidence/f10-linux-godot-base-suite/libmruby_dir_glob_ext_x64.so'
    'libmruby_zlib_ext_x64.so' = '.omo/evidence/f10-linux-godot-base-suite/libmruby_zlib_ext_extended_x64.so'
}
foreach ($name in $sources.Keys) {
    $target = Join-Path $destination $name
    if (Test-Path $target) { throw "Production native library already exists: $name" }
}
foreach ($name in $sources.Keys) {
    $source = Join-Path $root $sources[$name]
    $target = Join-Path $destination $name
    Copy-Item $source $target
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $expected = [BitConverter]::ToString($sha.ComputeHash([System.IO.File]::ReadAllBytes($source)))
        $actual = [BitConverter]::ToString($sha.ComputeHash([System.IO.File]::ReadAllBytes($target)))
    } finally { $sha.Dispose() }
    if ($expected -ne $actual) { throw "Native library deployment mismatch: $name" }
    Write-Output "LINUX_NATIVE_DEPLOYED:$name`:$actual"
}
