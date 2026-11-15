$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '../.omo/compatibility-run-tmp/d06-weather-bounds-original')
$refresh = @'
require 'zlib'
scripts = Marshal.load(File.binread('Data/Scripts.rvdata2'))
fixture = File.read('../../../tests/fixtures/weather_bounds_reference.rb')
scripts[-1][2] = Zlib::Deflate.deflate(fixture)
File.binwrite('Data/Scripts.rvdata2', Marshal.dump(scripts))
'@
$refresh | ruby
if ($LASTEXITCODE -ne 0) { throw 'Weather bounds refresh failed' }
$process = Start-Process ./Game.exe -PassThru -Wait
Write-Output "ORIGINAL_EXIT:$($process.ExitCode)"
if ($process.ExitCode -ne 0) { exit 1 }
if (-not (Test-Path './weather_bounds_reference.tsv')) { throw 'Weather bounds output missing' }
Write-Output 'ORIGINAL_WEATHER_BOUNDS_READY'
