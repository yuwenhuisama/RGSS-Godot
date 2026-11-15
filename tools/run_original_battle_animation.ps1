$ErrorActionPreference = 'Stop'
$destination = Join-Path $PSScriptRoot '../.omo/compatibility-run-tmp/e05-battle-animation-original'
Get-ChildItem 'E:/Projects/RMProject/Data/*.rvdata2' | Where-Object Name -ne 'Scripts.rvdata2' | Copy-Item -Destination (Join-Path $destination 'Data')
New-Item -ItemType Directory -Force (Join-Path $destination 'Graphics/System') | Out-Null
Copy-Item 'F:/Softwares/RPG Maker VX Ace/RTP/Graphics/System/Window.png' (Join-Path $destination 'Graphics/System/Window.png') -Force
Set-Location $destination
$refresh = @'
require 'zlib'
fixture = File.read('../../../tests/fixtures/battle_animation_reference.rb')
wrapper = "begin\n" + fixture + "\nrescue SystemExit\nraise\nrescue Exception => error\nFile.open('battle_animation_error.txt','w') { |file| file.puts error.class,error.message,error.backtrace }; exit\nend\n"
scripts = Marshal.load(File.binread('Data/Scripts.rvdata2'))
scripts[-1][2] = Zlib::Deflate.deflate(wrapper)
File.binwrite('Data/Scripts.rvdata2', Marshal.dump(scripts))
'@
$refresh | ruby
if ($LASTEXITCODE -ne 0) { throw 'Animation fixture refresh failed' }
if (Test-Path './battle_animation_error.txt') { Move-Item './battle_animation_error.txt' ('battle_animation_error-' + [Guid]::NewGuid().ToString('N') + '.txt') }
$process = Start-Process ./Game.exe -PassThru -Wait
Write-Output "ORIGINAL_EXIT:$($process.ExitCode)"
if ($process.ExitCode -ne 0) { exit 1 }
if (Test-Path './battle_animation_error.txt') { throw 'Animation fixture exception recorded' }
if (-not (Test-Path './battle_animation_reference.tsv')) { throw 'Battle animation ledger missing' }
Write-Output 'ORIGINAL_BATTLE_ANIMATION_READY'
