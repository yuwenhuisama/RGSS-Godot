$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '../.omo/compatibility-run-tmp/e06-audio-seek-units-original')
$refresh = @'
require 'zlib'
fixture = File.read('../../../tests/fixtures/audio_seek_units_reference.rb')
File.binwrite('Data/Scripts.rvdata2', Marshal.dump([[1, 'Compatibility', Zlib::Deflate.deflate(fixture)]]))
'@
$refresh | ruby
if ($LASTEXITCODE -ne 0) { throw 'Audio seek fixture refresh failed' }
$process = Start-Process ./Game.exe -PassThru -Wait
Write-Output "ORIGINAL_EXIT:$($process.ExitCode)"
if ($process.ExitCode -ne 0) { exit 1 }
if (-not (Test-Path './audio_seek_units_reference.tsv')) { throw 'Audio seek units ledger missing' }
Write-Output 'ORIGINAL_AUDIO_SEEK_UNITS_READY'
