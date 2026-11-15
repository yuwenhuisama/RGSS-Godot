$ErrorActionPreference = 'Stop'
$deadline = [DateTime]::UtcNow.AddMinutes(3)
while ([DateTime]::UtcNow -lt $deadline) {
    $type = & 'C:/Program Files/Docker/Docker/resources/bin/docker.exe' info --format '{{.OSType}}' 2>$null
    if ($LASTEXITCODE -eq 0 -and $type -eq 'linux') {
        Write-Output 'LINUX_ENGINE_READY'
        exit 0
    }
    Start-Sleep -Seconds 3
}
throw 'Existing Docker Linux engine did not become ready within three minutes'
