$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'test_paths.ps1')
$root = Split-Path $PSScriptRoot -Parent
$scripts = Get-ChildItem $PSScriptRoot -Filter '*.ps1' -Recurse |
    Where-Object FullName -NotMatch '[\\/](bin|obj)[\\/]'
foreach ($script in $scripts) {
    $tokens = $null
    $errors = $null
    $null = [System.Management.Automation.Language.Parser]::ParseFile($script.FullName, [ref]$tokens, [ref]$errors)
    if ($errors.Count -gt 0) { throw "$($script.FullName): $($errors | Out-String)" }
}
Write-Output "POWERSHELL_SYNTAX_PASS:$($scripts.Count)"
$bash = Get-TestPath 'git_bash'
$shells = Get-ChildItem $PSScriptRoot -Filter '*.sh' -Recurse
foreach ($script in $shells) {
    & $bash -n $script.FullName.Replace('\', '/')
    if ($LASTEXITCODE -ne 0) { throw "Bash syntax failed: $($script.FullName)" }
}
Write-Output "BASH_SYNTAX_PASS:$($shells.Count)"
