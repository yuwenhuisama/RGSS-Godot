$TestRepoRoot = Split-Path $PSScriptRoot -Parent
$env:RGSS_TEST_REPO_ROOT = $TestRepoRoot
$TestConfigFile = if ($env:RGSS_TEST_PATHS_FILE) { $env:RGSS_TEST_PATHS_FILE } else { Join-Path $TestRepoRoot '.test-paths.local.json' }
$TestConfigFile = [System.IO.Path]::GetFullPath($TestConfigFile)
$TestPathValues = if (Test-Path -LiteralPath $TestConfigFile) {
    Get-Content -LiteralPath $TestConfigFile -Raw | ConvertFrom-Json
} else { $null }
function Get-TestSetting([string]$Key) {
    $property = if ($null -ne $TestPathValues) { $TestPathValues.PSObject.Properties[$Key] } else { $null }
    if ($null -eq $property -or $property.Value -isnot [string] -or [string]::IsNullOrWhiteSpace($property.Value)) {
        throw "Missing test setting '$Key' in $TestConfigFile. Copy .test-paths.example.json and configure this input."
    }
    return $property.Value
}
function Get-TestPath([string]$Key) {
    $value = Get-TestSetting $Key
    if (![System.IO.Path]::IsPathRooted($value) -and !$value.StartsWith('/')) { $value = Join-Path (Split-Path $TestConfigFile -Parent) $value }
    return $value
}
function Get-TestRepoPath([string]$Relative = '') { return Join-Path $TestRepoRoot $Relative }
