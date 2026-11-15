# Windows test guest automatic sign-in

The user explicitly authorized automatic sign-in and disabling guest idle/resume
authentication on 2026-11-14. Only RGSS-Windows is in scope; its existing account
password remains unchanged. No host authentication setting is modified.

Microsoft Sysinternals Autologon64.exe was downloaded from the official site.
Its signature is Valid with Microsoft Corporation as signer, verified inside
the guest before execution. The tool configured rgss with domain RGSS-WINDOWS.
Original inspected login values and policy entries are preserved in
`C:/ProgramData/RGSS-Test-Setup/login-values-before.xml` and
`login-policy-before.xml`. These initial backups came from a session-0 VIX
process; user-profile settings must not be assumed to describe the interactive
profile, which was unloaded at that time.

Initial reboot exceeded the harness deadline during Windows startup. A later
actual interactive-desktop check passed: user RGSS-WINDOWS/rgss, session 1,
unlocked Default input desktop with a foreground window, boot timestamp
2026-11-14T14:11:08.5000000Z. This alone does not establish that no person signed
in during the interval. A second controlled reboot is running for that verdict.

Screen saver activation/security/timeout were set to zero in the subsequently
available real user session. DelayLockInterval was set to DWORD ffffffff for
the user resume sign-in preference. Writing machine Policies/System and the
user Policies/System subkey returned access denied; those denied operations
were not retried through another interface. No claim is made that every policy
was changed. Actual reboot and suspend/resume results determine usability.

Setup/verification scripts reside in D:/VMs. No password is printed in receipts.
The guest temporary plaintext input is removed in the tool invocation's finally
block. Autologon stores its credential as an LSA secret; guest administrators
can retrieve it. Retiring this setup requires Autologon's Disable action plus
restoring only the applicable backed-up preferences.

Official reference: https://learn.microsoft.com/en-us/sysinternals/downloads/autologon
Resume preference reference:
https://learn.microsoft.com/en-us/answers/questions/4094497/if-youve-been-away-when-should-windows-require-you

Second controlled reboot now passes automatic sign-in without input:
AUTOLOGON_DESKTOP_PASS:reboot, user RGSS-WINDOWS/rgss in session1,
Locked=false, actual Default desktop with foreground window; boot timestamp
2026-11-14T14:17:27.5000000Z. Receipt D:/VMs/autologon-reboot-receipt.json.
Actual VMware suspend/resume verification is running. The preceding session-0
profile writes were corrected by applying the Desktop preferences in the
real logged-in user session; its Policies/System subkey also rejected writes
and remains an explicit unmodified boundary. The machine/user denied paths
were not bypassed. Password remains unchanged.

Suspend/resume also completes at exit0 with AUTOLOGON_DESKTOP_PASS:resume:
same boot timestamp (actual resume, no reboot), session1 rgss, Locked=false,
and the Default input desktop with a foreground window. Receipt:
D:/VMs/autologon-resume-receipt.json. Both requested operational checks pass.
Both no-credential JSON receipts are also archived in
`.omo/evidence/guest-autologon` for repository-local review.
Guest automatic sign-in and the tested recovery path are usable; this does
not promise automatic unlocking after a deliberate future manual lock.
