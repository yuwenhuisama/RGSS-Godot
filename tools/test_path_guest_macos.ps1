$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/test_paths.ps1"
$workspace = Get-TestPath 'mac_workspace'
$remote = Get-TestSetting 'mac_host'
$remoteProject = "$workspace/project"
$files = @('tools/test_paths.gd', 'tests/fixtures/test_paths.rb', 'tests/test_audio_seek_units.gd',
    'tests/fixtures/audio_seek_units_reference.rb', 'Scripts/TestPathConfig.cs', 'Scripts/GlobalConfig.cs')
foreach ($file in $files) {
    & scp -o BatchMode=yes (Join-Path $TestRepoRoot $file) "${remote}:$remoteProject/$file"
    if ($LASTEXITCODE -ne 0) { throw "Upload failed: $file" }
}
$config = Get-TestRepoPath '.omo/evidence/test-path-contract/macos-local.json'
@{game_project = "$remoteProject/RMProject"; rtp = "$remoteProject/RTP"} | ConvertTo-Json |
    Set-Content -LiteralPath $config -Encoding UTF8
& scp -o BatchMode=yes $config "${remote}:$remoteProject/.test-paths.local.json"
if ($LASTEXITCODE -ne 0) { throw 'Mac config upload failed' }
& ssh -o BatchMode=yes $remote "cd '$remoteProject' && '$workspace/dotnet/dotnet' build RGSS-Godot.csproj --no-restore && '$workspace/godot/Godot_mono.app/Contents/MacOS/Godot' --windowed --max-fps 60 --path . -s tests/test_audio_seek_units.gd"
exit $LASTEXITCODE
