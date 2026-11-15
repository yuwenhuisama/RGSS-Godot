$ErrorActionPreference = 'Stop'
$process = Start-Process cmd.exe -ArgumentList @('/d', '/c', (Join-Path $PSScriptRoot 'build_zlib_compatibility.cmd')) -NoNewWindow -PassThru
$null = $process.Handle
$process.WaitForExit()
Write-Output "ZLIB_BUILD_EXIT:$($process.ExitCode)"
exit $process.ExitCode
