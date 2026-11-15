$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '../.omo/compatibility-run-tmp/f08-native-original')
$refresh = @'
require 'zlib'
fixture = File.read('../../../tests/fixtures/native_extensions_reference.rb')
File.binwrite('Data/Scripts.rvdata2', Marshal.dump([[1, 'Compatibility', Zlib::Deflate.deflate(fixture)]]))
'@
$refresh | ruby
if ($LASTEXITCODE -ne 0) { throw 'Native extension fixture refresh failed' }
New-Item -ItemType Directory -Path ./glob-probe/nested -Force | Out-Null
if (-not (Test-Path ./junction-probe)) {
    New-Item -ItemType Junction -Path ./junction-probe -Target (Join-Path (Get-Location) 'glob-probe/nested') | Out-Null
}
$process = Start-Process ./Game.exe -PassThru -Wait
Write-Output "ORIGINAL_EXIT:$($process.ExitCode)"
if ($process.ExitCode -ne 0) { exit 1 }
if (-not (Test-Path './native_extensions_reference.tsv')) { throw 'Native extension ledger missing' }
Write-Output 'ORIGINAL_NATIVE_EXTENSIONS_READY'
