$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '../.omo/compatibility-run-tmp/e06-audio-position-original')
$refresh = @'
require 'zlib'
fixture = File.read('../../../tests/fixtures/audio_position_reference.rb')
File.binwrite('Data/Scripts.rvdata2', Marshal.dump([[1, 'Compatibility', Zlib::Deflate.deflate(fixture)]]))
'@
$refresh | ruby
if ($LASTEXITCODE -ne 0) { throw 'Position fixture refresh failed' }
$process = Start-Process ./Game.exe -PassThru -Wait
Write-Output "ORIGINAL_EXIT:$($process.ExitCode)"
if ($process.ExitCode -ne 0) { exit 1 }
if (-not (Test-Path './audio_position_reference.tsv')) { throw 'Audio position output missing' }
Write-Output 'ORIGINAL_AUDIO_POSITION_READY'
