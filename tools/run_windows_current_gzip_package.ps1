$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'test_paths.ps1')
$root = Split-Path $PSScriptRoot -Parent
$work = Join-Path $root '.omo/evidence/windows-current-gzip-package'
if (Test-Path $work) { throw 'Evidence already exists' }
New-Item -ItemType Directory -Path (Join-Path $work 'install') | Out-Null
$install = Join-Path $work 'install'
$prior = Join-Path $root '.omo/evidence/windows-defined-host-install/install'
foreach ($name in @('RGSS-Godot.exe', 'RGSS-Godot.pck', 'data_RGSS-Godot_windows_x86_64', 'RGSS')) {
    Copy-Item (Join-Path $prior $name) (Join-Path $install $name) -Recurse
}
Copy-Item (Join-Path $root 'Plugins/windows/libmruby_zlib_ext_x64.dll') (Join-Path $install 'data_RGSS-Godot_windows_x86_64/Plugins/windows/libmruby_zlib_ext_x64.dll') -Force
Copy-Item (Join-Path $PSScriptRoot 'windows_current_gzip_main.rb') (Join-Path $install 'RGSS/main.rb') -Force
Copy-Item (Join-Path $root 'tests/fixtures/gzip_encoding_extended_reference.rb') $install
Copy-Item (Join-Path $root 'tests/fixtures/gzip_encoding_extended_original.tsv') $install
Copy-Item (Join-Path $PSScriptRoot 'linux_export_config.json') (Join-Path $install 'rm_conf.json')
New-Item -ItemType Directory -Path (Join-Path $install 'RMProject') | Out-Null
New-Item -ItemType Directory -Path (Join-Path $work 'empty-working-directory') | Out-Null
& (Join-Path $PSScriptRoot 'run_clean_windows_install.ps1') -Name 'windows-current-gzip-package' -ExpectedMarker 'WINDOWS_CURRENT_EXPORTED_GZIP_PASS:14'
