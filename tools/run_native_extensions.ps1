$ErrorActionPreference = 'Stop'
$output = Join-Path $PSScriptRoot '../.omo/evidence/rmva-compatibility/godot/native-extensions'
New-Item -ItemType Directory -Path (Join-Path $output 'glob-probe/nested') -Force | Out-Null
if (-not (Test-Path (Join-Path $output 'junction-probe'))) {
    New-Item -ItemType Junction -Path (Join-Path $output 'junction-probe') -Target (Join-Path $output 'glob-probe/nested') | Out-Null
}
& 'E:/Godot/Godot_v4.6.1-stable_mono_win64_console.exe' --headless --path (Join-Path $PSScriptRoot '..') -s tests/test_native_extensions.gd
exit $LASTEXITCODE
