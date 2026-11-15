$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/test_paths.ps1"
Set-Location (Join-Path $PSScriptRoot '../.omo/compatibility-run-tmp/e06-audio-replay-original')
$refresh = @'
require 'zlib'
require File.join(ENV.fetch('RGSS_TEST_REPO_ROOT'), 'tools/test_paths')
fixture = File.read('../../../tests/fixtures/audio_replay_reference.rb')
File.binwrite('Data/Scripts.rvdata2', Marshal.dump([[1, 'Compatibility', Zlib::Deflate.deflate(TestPathsConfig.fixture_source(fixture))]]))
'@
$refresh | ruby
if ($LASTEXITCODE -ne 0) { throw 'Replay fixture refresh failed' }
$process = Start-Process ./Game.exe -PassThru -Wait
Write-Output "ORIGINAL_EXIT:$($process.ExitCode)"
if ($process.ExitCode -ne 0) { exit 1 }
if (-not (Test-Path './audio_replay_reference.tsv')) { throw 'Audio replay output missing' }
Write-Output 'ORIGINAL_AUDIO_REPLAY_READY'
