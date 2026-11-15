$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$source = Join-Path $root '.omo/evidence/rmva-compatibility/godot/dense-map/soak/resource-profile'
$target = Join-Path $root '.omo/evidence/f11-resource-profile-before-current-host'
if (Test-Path $target) { throw 'Prior profile archive already exists' }
Copy-Item $source $target -Recurse
Write-Output 'PRIOR_RESOURCE_PROFILE_PRESERVED'
