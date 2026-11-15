$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/test_paths.ps1"
Get-CimInstance Win32_Process -Filter "Name='Game.exe'" | ForEach-Object {
    if ($_.ExecutablePath -like (Get-TestRepoPath '.omo/compatibility-run-tmp/*')) {
        Write-Output "OWNED_ORIGINAL:$($_.ProcessId):$($_.ExecutablePath)"
    }
}
