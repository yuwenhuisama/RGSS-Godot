$ErrorActionPreference = 'Stop'
$owned = @(
    'E:\Projects\RGSS-Godot\.omo\compatibility-run-tmp\f08-zlib-checksum-original\Game.exe',
    'E:\Projects\RGSS-Godot\.omo\compatibility-run-tmp\f08-zlib-checksum-low-original\Game.exe'
)
Get-CimInstance Win32_Process -Filter "Name='Game.exe'" | ForEach-Object {
    if ($_.ExecutablePath -in $owned) {
        Stop-Process -Id $_.ProcessId
        Write-Output "OWNED_CHECKSUM_STOPPED:$($_.ProcessId)"
    }
}
