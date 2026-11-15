$ErrorActionPreference = 'Stop'
$destination = Join-Path $PSScriptRoot '../.omo/compatibility-run-tmp/d08-shop-name-original'
Get-ChildItem 'E:/Projects/RMProject/Data/*.rvdata2' | Where-Object Name -ne 'Scripts.rvdata2' | Copy-Item -Destination (Join-Path $destination 'Data')
New-Item -ItemType Directory -Force (Join-Path $destination 'Graphics/System') | Out-Null
New-Item -ItemType Directory -Force (Join-Path $destination 'Graphics/Faces') | Out-Null
Copy-Item 'F:/Softwares/RPG Maker VX Ace/RTP/Graphics/System/*' (Join-Path $destination 'Graphics/System')
Copy-Item 'F:/Softwares/RPG Maker VX Ace/RTP/Graphics/Faces/*' (Join-Path $destination 'Graphics/Faces')
Set-Location $destination
$ruby = @'
require 'zlib'
fixture = File.read('../../../tests/fixtures/shop_name_reference.rb')
wrapper = "begin\n" + fixture + "\nrescue SystemExit\nraise\nrescue Exception => error\nFile.open('shop_name_error.txt','w') { |f| f.puts error.class, error.message, error.backtrace }; exit\nend\n"
scripts = Marshal.load(File.binread('Data/Scripts.rvdata2'))
scripts[-1][2] = Zlib::Deflate.deflate(wrapper)
File.binwrite('Data/Scripts.rvdata2', Marshal.dump(scripts))
'@
$ruby | ruby
if ($LASTEXITCODE -ne 0) { throw 'Could not refresh original fixture' }
$process = Start-Process ./Game.exe -PassThru -Wait
Write-Output "ORIGINAL_EXIT:$($process.ExitCode)"
if ($process.ExitCode -ne 0) { exit 1 }
if (-not (Test-Path './shop_name_reference.tsv')) { throw 'Original shop/name fixture did not finish' }
Write-Output 'ORIGINAL_SHOP_NAME_READY'
