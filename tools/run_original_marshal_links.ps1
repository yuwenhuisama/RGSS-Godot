$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '../.omo/compatibility-run-tmp/f04-marshal-links-original')
$refresh = @'
require 'zlib'
fixture = "$marshal_links_peer='E:/Projects/RGSS-Godot/.omo/evidence/rmva-compatibility/godot/marshal-links/marshal_links_payload.bin'\n" + File.read('../../../tests/fixtures/marshal_links_reference.rb')
wrapper = "begin\n" + fixture + "\nrescue SystemExit\nraise\nrescue Exception => error\nFile.open('marshal_peer_error.txt','w') { |file| file.puts error.class,error.message,error.backtrace }; exit\nend\n"
File.binwrite('Data/Scripts.rvdata2', Marshal.dump([[1, 'Compatibility', Zlib::Deflate.deflate(wrapper)]]))
'@
$refresh | ruby
if ($LASTEXITCODE -ne 0) { throw 'Marshal fixture refresh failed' }
Remove-Item './marshal_peer_error.txt' -ErrorAction SilentlyContinue
$process = Start-Process ./Game.exe -PassThru -Wait
Write-Output "ORIGINAL_EXIT:$($process.ExitCode)"
if ($process.ExitCode -ne 0) { exit 1 }
if (Test-Path './marshal_peer_error.txt') { throw 'Marshal peer exception recorded' }
if (-not (Test-Path './marshal_links_reference.tsv')) { throw 'Marshal links ledger missing' }
Write-Output 'ORIGINAL_MARSHAL_LINKS_READY'
