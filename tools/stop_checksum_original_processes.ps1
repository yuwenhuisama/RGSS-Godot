$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/test_paths.ps1"
$owned = @(
    (Get-TestRepoPath '.omo/compatibility-run-tmp/f08-zlib-checksum-original/Game.exe'),
    (Get-TestRepoPath '.omo/compatibility-run-tmp/f08-zlib-checksum-low-original/Game.exe')
)
Get-CimInstance Win32_Process -Filter "Name='Game.exe'" | ForEach-Object {
    if ($_.ExecutablePath -in $owned) {
        Stop-Process -Id $_.ProcessId
        Write-Output "OWNED_CHECKSUM_STOPPED:$($_.ProcessId)"
    }
}
