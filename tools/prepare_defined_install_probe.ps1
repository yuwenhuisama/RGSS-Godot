$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$install = Join-Path $root '.omo/evidence/windows-defined-host-install/install'
$inputFile = Join-Path $install 'RMProject/Audio/BGM/install-tone.wma'
if (-not (Test-Path $inputFile)) { throw 'Installation WMA probe missing' }
function Hash-File([string]$Path) {
    $stream = [System.IO.File]::OpenRead($Path)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try { return [BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-', '') }
    finally { $stream.Dispose(); $sha.Dispose() }
}
foreach ($name in @('libmruby_x64.dll', 'libmruby_onig_regexp_ext_x64.dll', 'libmruby_marshal_c_ext_x64.dll', 'libmruby_zlib_ext_x64.dll')) {
    $production = Hash-File (Join-Path $root ('Plugins/windows/' + $name))
    $exported = Hash-File (Join-Path $install ('data_RGSS-Godot_windows_x86_64/Plugins/windows/' + $name))
    if ($production -ne $exported) { throw "Exported native library differs: $name" }
    Write-Output "INSTALL_NATIVE_MATCH:${name}:$exported"
}
& ruby -c (Join-Path $install 'RGSS/main.rb')
if ($LASTEXITCODE -ne 0) { throw 'Installation Ruby probe syntax failed' }
Write-Output 'DEFINED_INSTALL_PROBE_READY'
