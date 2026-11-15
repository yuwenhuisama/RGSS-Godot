$ErrorActionPreference = 'Stop'
$process = Start-Process cmd.exe -ArgumentList @('/d', '/c', (Join-Path $PSScriptRoot 'build_regexp_match.cmd')) -NoNewWindow -PassThru
$null = $process.Handle
$process.WaitForExit()
Write-Output "REGEXP_BUILD_EXIT:$($process.ExitCode)"
exit $process.ExitCode
