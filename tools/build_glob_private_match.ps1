$ErrorActionPreference = 'Stop'
$process = Start-Process cmd.exe -ArgumentList @('/d','/c',(Join-Path $PSScriptRoot 'build_glob_private_match.cmd')) -NoNewWindow -PassThru
$null = $process.Handle
$process.WaitForExit()
Write-Output "GLOB_BUILD_EXIT:$($process.ExitCode)"
exit $process.ExitCode
