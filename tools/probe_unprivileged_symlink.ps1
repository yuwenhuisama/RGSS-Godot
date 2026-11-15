$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$work = Join-Path $root '.omo/evidence/f08-unprivileged-symlink'
if (Test-Path $work) { throw 'Symlink probe evidence already exists' }
New-Item -ItemType Directory -Path $work | Out-Null
$target = Join-Path $work 'target.txt'
[System.IO.File]::WriteAllText($target, 'symlink fixture')
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class OwnedSymlinkProbe {
    [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
    [return: MarshalAs(UnmanagedType.U1)]
    public static extern bool CreateSymbolicLink(string link, string target, uint flags);
}
'@
$ok = [OwnedSymlinkProbe]::CreateSymbolicLink((Join-Path $work 'link.txt'), $target, 2)
$errorCode = [Runtime.InteropServices.Marshal]::GetLastWin32Error()
$result = 'SYMLINK_UNPRIVILEGED_RESULT:created={0}:error={1}' -f $ok, $errorCode
[System.IO.File]::WriteAllText((Join-Path $work 'result.txt'), $result)
Write-Output $result
if (-not $ok) { exit 1 }
