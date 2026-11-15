$ErrorActionPreference = 'Stop'
foreach ($root in @('HKCU:/Software/Enterbrain','HKCU:/Software/KADOKAWA')) {
    if (Test-Path $root) {
        Get-ItemProperty -LiteralPath $root | Format-List
        Get-ChildItem -LiteralPath $root -Recurse | ForEach-Object {
            Get-ItemProperty -LiteralPath $_.PSPath | Format-List
        }
    }
}
Write-Output 'ORIGINAL_AUDIO_SETTINGS_READ'
