$ErrorActionPreference = 'Stop'
Get-CimInstance Win32_Process -Filter "Name='Game.exe'" | ForEach-Object {
    if ($_.ExecutablePath -like 'E:\Projects\RGSS-Godot\.omo\compatibility-run-tmp\*') {
        Write-Output "OWNED_ORIGINAL:$($_.ProcessId):$($_.ExecutablePath)"
    }
}
