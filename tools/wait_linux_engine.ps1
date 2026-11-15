$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'test_paths.ps1')
$deadline = [DateTime]::UtcNow.AddMinutes(3)
while ([DateTime]::UtcNow -lt $deadline) {
    $type = & (Get-TestPath 'docker') info --format '{{.OSType}}' 2>$null
    if ($LASTEXITCODE -eq 0 -and $type -eq 'linux') {
        Write-Output 'LINUX_ENGINE_READY'
        exit 0
    }
    Start-Sleep -Seconds 3
}
throw 'Existing Docker Linux engine did not become ready within three minutes'
