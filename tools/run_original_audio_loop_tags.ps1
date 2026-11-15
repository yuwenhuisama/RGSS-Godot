$ErrorActionPreference='Stop'
Set-Location (Join-Path $PSScriptRoot '../.omo/compatibility-run-tmp/e06-audio-loop-tags-original')
$refresh=@'
require 'zlib'
fixture=File.read('../../../tests/fixtures/audio_loop_tags_reference.rb')
File.binwrite('Data/Scripts.rvdata2',Marshal.dump([[1,'Compatibility',Zlib::Deflate.deflate(fixture)]]))
'@
$refresh | ruby
if ($LASTEXITCODE -ne 0) { throw 'Loop tags refresh failed' }
$process=Start-Process ./Game.exe -PassThru -Wait
Write-Output "ORIGINAL_EXIT:$($process.ExitCode)"
if ($process.ExitCode -ne 0) { exit 1 }
if (-not (Test-Path './audio_loop_tags_reference.tsv')) { throw 'Loop tags ledger missing' }
Write-Output 'ORIGINAL_AUDIO_LOOP_TAGS_READY'
