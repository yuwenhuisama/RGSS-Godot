param([switch]$Midi)
$ErrorActionPreference = 'Stop'
$destination = Join-Path $PSScriptRoot '../.omo/compatibility-run-tmp/e07-audio-me-original'
Set-Location $destination
$refresh = @'
require 'zlib'
fixture = File.read('../../../tests/fixtures/audio_me_reference.rb')
if ARGV[0] == 'midi'
  fixture = "$audio_me_bgm='E:/Projects/RGSS-Godot/tests/fixtures/midi-reference.mid'; $rgss_compat_output='midi'\n" + fixture
end
File.binwrite('Data/Scripts.rvdata2', Marshal.dump([[1, 'Compatibility', Zlib::Deflate.deflate(fixture)]]))
'@
if ($Midi) {
    New-Item -ItemType Directory -Force './midi' | Out-Null
    $refresh | ruby - midi
} else {
    $refresh | ruby
}
if ($LASTEXITCODE -ne 0) { throw 'ME fixture refresh failed' }
$process = Start-Process ./Game.exe -PassThru -Wait
Write-Output "ORIGINAL_EXIT:$($process.ExitCode)"
if ($process.ExitCode -ne 0) { exit 1 }
if (-not (Test-Path './audio_me_reference.tsv')) { throw 'Audio ME output missing' }
Write-Output 'ORIGINAL_AUDIO_ME_READY'
