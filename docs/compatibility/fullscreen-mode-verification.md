# Fullscreen Mode Verification (C12)

## C12 accepted with explicitly authorized host evidence (2026-11-15)

The user authorized this dedicated host display test after the VMware120Hz
experiment failed. Four actual640x480 desktop captures pass exact pixel checks
and independent visual inspection: full640x480, centered544x416 at48,32,
centered320x240 at160,120, and F1-enabled544x416. No watermark, lock screen or
desktop overlay is present. F1 on/off, focus out/in, toggles and exit while
fullscreen complete and restore3840x2160@144Hz with registry144Hz unchanged.
Evidence: `.omo/evidence/c12-host-authorized-120hz`, including visual-inspection.md.
That invocation retains exit1 because the requested120Hz mode does not exist:
the host lists3840x2160 only at60/95/144Hz. It is not an overall PASS.

The user then explicitly authorized60Hz. Only the missing non-registry phase
was run, preserving the already-passed capture work. It temporarily sets
3840x2160@60Hz while registry remains144Hz, enters640x480@60Hz, restores60Hz
on focus-out and toggle-out, returns to640x480 on focus-in, and exits0 back to
the saved60Hz mode. Finally it restores3840x2160@144Hz exactly, registry still
144Hz. `ORIGINAL_FULLSCREEN_HARNESS_RESULT:PASS`, owner exit0, in
`.omo/evidence/c12-host-authorized-60hz/verification.log`.

Together these current-source measured phases close C12. No120Hz or general
driver compatibility claim follows. The historical guest watermark/60Hz-only
limits and failed host120Hz invocation remain recorded below. No production
behavior changed in this acceptance run; the existing harness gained explicit
alternate-refresh selection and a missing-phase-only execution option.

## Windows VMware guest physical result (2026-11-14)

The dedicated harness now runs entirely inside the logged-in Windows guest.
Baseline and registry modes are1288x840@60Hz. Actual640x480 desktop captures
pass all four pixel checks: logical640x480 fills the output;544x416 is centered
at48,32;320x240 at160,120; F1-enabled544x416 also at48,32. Foreground is true.
Every toggle restores1288x840@60Hz; focus-out restores that mode, focus-in
returns640x480, F1-off restores baseline, and exit while fullscreen returns
exit0 with both current and registry modes unchanged.

Overall harness exit1 is retained: VMware exposes no alternate refresh rate
at the same resolution, so PHASE_NONREG_SKIPPED causes FAIL. This is absent
driver coverage, not a passed non-registry-refresh test. Earlier host evidence
below covers the distinct144Hz/temporary60Hz restoration lifecycle; its locked
captures never count as picture evidence. Guest screenshots and logs are under
`.omo/evidence/c12-windows-guest`. Independent inspection of these four actual
guest captures is pending. No host display mode is changed by this guest run.

Independent inspection is now complete for all four guest desktop PNGs.
All sizes, origins, continuous border rings and checker positions match the
fixture; no lockscreen or rendering corruption is present. However, the guest's
Windows activation watermark overlays all four images at x480..613/y351..410,
including 51 border pixels in the544x416 captures. Thus the literal no-desktop-
overlay gate is not passed, and these files must not be called clean captures.
The F1 PNG is byte-identical to the ordinary544x416 PNG, as expected for the
same static scene; the separate F1 command/mode log establishes the state
transition, not differing PNG bytes. Stills do not establish animation.
No activation settings or OS licensing state were changed. C12 remains open
with this external overlay and the guest alternate-refresh limitation recorded.

The complementary refresh lifecycle is pinned in
`.omo/evidence/c12-commit-order-full-60hz/verification.log`: lines25..31
record non-registry3840x2160@60Hz while registry remains144Hz, focus-out
restoring60Hz, focus-in640x480@60Hz, toggle-out restoring60Hz, exit0 restoring
60Hz, and final exact144Hz baseline restoration. Its overall FAIL is retained
because its four desktop picture checks were invalid lockscreen captures.
These phase-specific receipts must not be relabeled as an overall harness PASS.

## Latest measured boundary (2026-11-14)

Post-repair headless base suite passes TEST_SUITE_PASS:22, exit0. The dedicated
physical harness now rejects same-session LogonUI before any window creation
or mode switch; locked-desktop control returns C12_DESKTOP_LOCKED, exit1 as
expected. This is a prerequisite rejection, not a C12 behavior failure.
Temporary tracing is removed; its journal has been retired into this record.

The60Hz full run completes all mode-lifecycle phases without timeout: F1 commit,
focus out/in at144Hz and non-registry60Hz, toggles, exit while fullscreen,
exact session-mode restoration and unchanged registry144Hz. Final workstation
mode is3840x2160@144Hz. Overall harness still exits1 because all four physical
picture checks failed; those screenshots were taken on the Windows lock screen,
as independently identified in the three desktop PNGs. A read-only process
probe confirms LogonUI PID420856 in the same session1. These captures cannot
establish rendering parity. A persistent same-session unlock monitor is active;
no further physical display tests run while locked.

The independent visual reader did not resolve the tiny checkerboard in the
viewport PNG, but a direct64-pixel comparison at(300,220) has zero mismatches.
Thus in-engine fixture rendering is present; its physical presentation remains
unverified under the locked desktop. No image tolerance or failed assertion is
relaxed. The minimal state-order repair is retained on the strength of the
completed lifecycle evidence; full C12 acceptance still awaits physical QA.

Current60Hz full replay passes F1 commit(true/false), physical focus-in640x480
after desktop restore, and exit restoring3840x2160@144Hz with registry144Hz.
It has reached the non-registry60Hz phase without the previous early runner
termination. Physical picture checks still fail and are being independently
inspected; no full C12 pass is claimed. Evidence: c12-commit-order-full-60hz.

Restored-baseline60Hz single F1 run now confirms saved=true/requested=true/
native=true and physical entry640x480, then reproduces focus-in stuck at
desktop. Thus F1 is not generally broken on baseline; the earlier full run's
F1 result is not enough to localize its cause. The minimal state-commit candidate
is reapplied for a complete60Hz replay, after the window lifetime control passed.
No additional notification guard or retry was introduced; build is pending.

Window-only runner lifetime check passes90 seconds and cooperative exit0
after adding Engine.max_fps=60. No fullscreen command ran in that check.
F1 helper now records saved fullscreen, requested and native states and fails
its command if confirmation does not persist/apply the requested value. A
single F1-entry run on restored production baseline is active at60Hz to
separate F1 submission from physical mode application. This is diagnostic,
not an accepted focus fix; the candidate remains withdrawn.

Full candidate replay ends in an AltEnter acknowledgment timeout. Candidate
state-order change was withdrawn pending diagnosis; production notification
ordering is restored. The runner stdout ends with INTERACTIVE_DONE, so this
does not establish a native deadlock. Its interactive loop has a36000-frame
budget but never sets Engine.max_fps; disabling VSync in F1 can exhaust that
budget within the long harness run. The dedicated runner now uses60Hz, matching
other frame-budget owners. Baseline rebuild is active; a bounded runner-lifetime
check must distinguish frame exhaustion before attributing the timeout to the
candidate. Earlier whole-frame capture/focus-precondition failures remain open.

The subsequent full replay has not passed: all three size mode switches and
desktop restores succeed, but physical image checks fail with fg=False. Root
viewport pixels contain the expected pattern; sampled desktop pixels do not.
The three desktop captures have distinct full-buffer hashes despite matching
sampled points, so they must not be described as byte-identical. F1 also remains
at desktop mode, invalidating that phase's later focus precondition. The bounded
AltEnter focus result stays valid; full C12 acceptance remains open pending
complete exit/alternate-refresh results and resolution of these separate gates.

The state-commit candidate now produces the required physical focus sequence
in c12-focus-commit-alt: enter640x480@144Hz, out3840x2160@144Hz,
in640x480@144Hz. The process exits 0 and the harness finishes PASS with exact
starting-mode restoration. The complete dedicated fullscreen suite is now
running in c12-commit-order-full to cover size/F1/alternate-refresh regressions.
The preceding F1-only trial never entered fullscreen and cannot judge focus
recovery; FocusOnly now uses Alt+Enter and rejects a failed entry precondition
or runner failure acknowledgment. No notification guard was added.

2026-11-14 single-focus trace localizes the nested focus-in inside
DestroyPhysicalPresenter, not RestorePreviousMode. Timestamp order in
c12-focus-order-once/focus-order.stdout.log is DESTROY_BEGIN, IN(active=true,
suspended=true), ENTER_RESULT Already in target mode, DESTROY_END, RESTORE_BEGIN,
RESTORE_END(active=false,suspended=false). Later injected IN sees both false.
Mode measurements are enter640x480, out3840x2160, in3840x2160 at144Hz; desktop
is restored at exit. The diagnostic harness's PASS meant command completion,
not focus parity; its new FocusOnly mode now asserts physical mode values.

Candidate minimal fix moves the suspension flag assignment after presenter
destruction, display restoration and topmost clearing. Nested focus-in therefore
cannot consume a suspension that has not completed. No guard/deferred callback
is added. Temporary prints are removed, C# diagnostics clean, build active.
Actual fix acceptance remains pending the same single-focus replay.

## Status: Shared Project Buildable (`0 Error(s)`), Non-Registry `savedMode` Restore Verified, Physical Mode & DPI Virtualization Root-Caused

Updated: 2026-11-13

Lead coordinated physical replay is active in the separate
`.omo/evidence/c12-host-fullscreen-safe/` directory, preserving the prior
failure artifacts. First results:640x480 checkerboard exact at(0,0),
544x416 exact at(48,32),320x240 exact at(160,120), all ok=True;
desktop3840x2160@144Hz restored after the first two toggles. Remaining focus,
F1 and non-registry mode/exit checks are pending final monitor completion.

Coordinated safe replay finished exit1. Four exact checkerboard/centering
checks passed, including F1. Toggle/exit restoration and non-registry60Hz
restoration passed. Focus-in failed at both144Hz and60Hz: mode stayed desktop
instead of640x480. Thus C12 remains open. The runner injects WM focus
notifications rather than activating a real peer window; diagnostic focus-state
logging is now being built to distinguish state loss from actual OS re-focus.

Diagnostic focus states confirm notification reentrancy: focus-out starts with
active=true, then focus-in occurs while active=true/suspended=true inside
display restoration. It immediately re-enters; outer restoration subsequently
sets active=false, and the next focus-in sees suspended=false. Resume is now
deferred until the current notification unwinds and checks the still-requested
suspended state. Temporary diagnostic prints were removed. C# diagnostics
reported none; build/green replay waits for the active diagnostic process to exit.

Diagnostic replay finished exit1 with the same focus-in failure at144Hz and
60Hz; both exits restored the exact session mode and registry remained144Hz.
The diagnostic process has exited; the deferred-resume build is now active.

Deferred-resume approach failed: third Alt+Enter command timed out without
ack after the first two pixel/toggle checks passed. The owned process was
terminated by harness cleanup and desktop mode restored. That approach was
withdrawn. Resume now ignores notifications generated synchronously while
RestorePreviousMode is running, preserving suspended state for the subsequent
focus-in. A restoringDisplayMode flag is cleared in finally; diagnostics clean,
replacement build active. No passing C12 lifecycle verdict is claimed.

D05 stored white-background Alpha matrix still differs at exactly3 rows,
all3x3 column2, each channel+1; black-background rows match. These stored
artifacts constrain alpha-cache quantization; no shader change was made.

Focus-in-only restore guard replay failed with timeout at F1 fullscreen1,
after all three ordinary-size pixel checks passed. The restoring-mode guard
now applies to all focus/size notifications during restoration, since size
synchronization and focus-out could still recursively enter mode operations.
Close handling remains before the guard. Diagnostics clean; build active.

All-notification restore guard completed without timeout, but focus-in still
left desktop mode at144Hz/60Hz; four pixel checks and exact exit restoration
passed. Focus-out destroys the physical presenter before RestorePreviousMode,
so that destruction can deliver focus-in before the guard is set. The guard
now covers presenter destruction, display restoration and topmost removal as
one synchronous transition; inner restoration preserves the outer guard state.
Diagnostics clean; replacement build is active after prior process exit.

Whole focus-out transition guard also timed out at F1 fullscreen1. All lead
guard/deferred variants were withdrawn; GameSettings notification behavior
is restored to the last runnable baseline, which completes all phases with
focus-in mode failure. No added guard is shipped as a fix. The original
notification reentrancy observation remains evidence, but successful causal
fix is unproven. Next diagnosis must inspect actual mode-call ordering.
Task unit: `st_01a1d3dc` (C12 Windows original fullscreen physical compatibility)

---

## 1. Decision Settled & Lifecycle Invariants

### Central Contract Decision
Godot 4.6 `DisplayServer.WindowMode.Fullscreen` and `DisplayServer.WindowMode.ExclusiveFullscreen` on Windows (`DisplayServerWindows::window_set_mode`) never change the OS video mode — they only restyle the `HWND` (`WS_POPUP`) and resize it to the current desktop dimensions (`3840x2160` on this workstation). Original RGSS300 (`Game.exe` + `RGSS300.dll`) performs an exclusive Win32 display-mode switch (`640x480`) and presents the logical surface 1:1 centered without scaling.

To match original RGSS300 fullscreen without touching lead-owned `Scripts/Graphics.cs`, `Scripts/GameRenderManager.cs`, `tests/test_resize_surface.gd`, or `tools/run_tests.gd`:

1. **Native Win32 `CDS_FULLSCREEN` display-mode lifecycle (`Scripts/WindowsDisplayMode.cs`)**:
   - Resolves the monitor device name (`MONITORINFOEXW.szDevice`) from the Godot window `HWND` (`DisplayServer.WindowGetNativeHandle(HandleType.WindowHandle)`).
   - Queries current display mode via `EnumDisplaySettingsW(deviceName, ENUM_CURRENT_SETTINGS)` and saves the exact baseline `DEVMODEW` (`savedMode`) before entering fullscreen.
   - Enumerates driver-supported modes matching the requested logical size (falling back to `640x480` when sub-`640x480` sizes such as `544x416` or `320x240` are not standalone video modes, matching original RGSS300).
   - Validates candidates with `ChangeDisplaySettingsExW(..., CDS_TEST)` preferring matching bit depth, refresh rate, and default fixed-output mode before applying `ChangeDisplaySettingsExW(..., CDS_FULLSCREEN)` (`0x00000004`, dynamic/non-persistent — `CDS_UPDATEREGISTRY` is never used, so the Windows registry display configuration is never polluted).
   - **Exact `savedMode` restore contract (no silent registry fallback)**: `RestorePreviousMode` restores `savedMode` directly via `ChangeDisplaySettingsExW(deviceName, ref explicitRestore, IntPtr.Zero, 0, IntPtr.Zero)` and never calls `ChangeDisplaySettingsExW(..., IntPtr.Zero, ...)` (which would reset to `ENUM_REGISTRY_SETTINGS` and clobber a session that started in a temporary/non-registry display mode).
   - Surfaces unsupported/failed mode switches or restore failures explicitly via `GD.PrintErr("FULLSCREEN_MODE_ERROR:...")` / `GD.PrintErr("FULLSCREEN_RESTORE_ERROR:...")` without silently falling back to fake scaled desktop fullscreen.
   - Restores `savedMode` on:
     - `Alt+Enter` toggle off,
     - F1 `Game Properties` confirmation with `fullscreen = false`,
     - Window/application focus loss (`NotificationWMWindowFocusOut` / `NotificationApplicationFocusOut`, excluding the in-process F1 modal `AcceptDialog` and transition grace window) with automatic re-entry on focus regain,
     - Node `_ExitTree` and `NotificationWMCloseRequest`,
     - `AppDomain.CurrentDomain.ProcessExit` and `UnhandledException` safety hooks.

2. **Unified F1 + `Alt+Enter` Entry Path (`Scripts/GameSettings.cs`)**:
   - Both `Apply()` (startup config + F1 `Confirmed`) and `_Input` (`Alt+Enter`) route through `public bool SetFullscreen(bool enabled)`.
   - Saves and restores windowed `Size` and Win32 `Position` across fullscreen transitions.

3. **1:1 Unscaled Centering Inside Physical `640x480` (`Scripts/GameSettings.cs` + `Scripts/WindowsDisplayMode.cs`)**:
   - Under `project.godot` (`window/stretch/mode="viewport"`, `window/stretch/scale_mode="integer"`), Godot's `Window::_update_viewport_size` centers `544x416` at `(48, 32)` (`scale = 1`), **but integer-upscales `320x240` by `2x` to `640x480` at `(0, 0)`** because `floor(640/320) = 2`.
   - When the swapchain matches `640x480` 1:1, `GameSettings.SyncFullscreenViewportCentering` pins the root viewport's screen blit rectangle via `RenderingServer.ViewportAttachToScreen(window.GetViewportRid(), new Rect2((physical.X - w) / 2, (physical.Y - h) / 2, w, h), 0)`:
     - `640x480` -> `Rect2(0, 0, 640, 480)`
     - `544x416` -> `Rect2(48, 32, 544, 416)`
     - `320x240` -> `Rect2(160, 120, 320, 240)`
   - **High-DPI Desktop Virtualization Compensation (`PresentPhysicalCenteredRgba`)**:
     - Root cause diagnosed from Godot 4.6 `platform/windows/display_server_windows.cpp:7134` and measured desktop captures on this `150%`-scaled (`144 DPI`) workstation: Godot initializes with `SetProcessDpiAwareness(PROCESS_SYSTEM_DPI_AWARE)` (`awareness = 1`). When `CDS_FULLSCREEN` switches the monitor from `3840x2160` (`144 DPI`) to `640x480`, Windows DWM keeps the main `HWND` in System-DPI virtualization (`960x720` logical swapchain) and bilinear-downscales `960x720 -> 640x480` (`2/3x`), keeping all 4-px borders, black bars, and centered origins `(0,0)`, `(48,32)`, `(160,120)` exact while blending single-pixel alternating `(255,255,255)/(0,0,0)` checker cells to `(217,221,224)/(96,101,104)`.
     - Attempting to bypass this via a Godot child `Window` (`ForceNative = true`) failed because `DisplayServerWindows` still sizes/clamps subwindows under System-DPI logical screen metrics (`960x720`).
     - Implemented safe (zero `unsafe` / zero csproj edits) Win32 Per-Monitor-V2 (`SetThreadDpiAwarenessContext(-4)`) popup presentation (`WindowsDisplayMode.PresentPhysicalCenteredRgba` via `CreateWindowExW` + `SetDIBitsToDevice`) whenever `swapchainSize != physicalTarget` (`960x720 != 640x480`) and F1 dialog is not open, tearing down cleanly via `DestroyPhysicalPresenter()` on dialog open, focus loss, fullscreen exit, and process exit.

---

## 2. Separate Windowed External-Resize Gap (Documented Accurately, Unchanged)

Per `docs/compatibility/original-physical-resize-verification.md` and `docs/compatibility/resolution-surface-verification.md`:
- **Original RGSS300 windowed external resize (`SetWindowPos`)**: Stretches the logical surface to fill arbitrary client dimensions (including non-4:3 ratios such as `1000x700` and `1616x616`) using nearest-neighbor source-edge rounding without letterboxing.
- **Godot port windowed resize**: Uses `content_scale_mode = viewport`, `content_scale_aspect = keep`, `content_scale_stretch = integer`, preserving integer scale with black letterbox bars (`1280x960` 2x measured).
- This windowed external-resize presentation difference is a separate contract gap from C12 fullscreen physical mode switching and is intentionally preserved unchanged in windowed mode.

---

## 3. Physical & Build Evidence Executed

1. **LSP & Build Verification (Current Tree)**:
   - `lsp_diagnostics` on `Scripts/WindowsDisplayMode.cs` -> `No diagnostics found`
   - `lsp_diagnostics` on `Scripts/GameSettings.cs` -> `No diagnostics found`
   - `dotnet build RGSS-Godot.csproj --no-restore` -> `Build succeeded. 0 Error(s)` (safe `byte[]` marshaling for `SetDIBitsToDevice`; `RGSS-Godot.csproj` untouched, `AllowUnsafeBlocks` not added).

2. **Measured Physical Mode, Non-Registry `savedMode` Restore, and Centering Evidence (`.omo/evidence/c12-host-fullscreen/`)**:
   - **Red Baseline Reproduced**:
     - `RED_FULLSCREEN_MODE:3840x2160@144Hz:32bpp` (`RED_REPRODUCED_DESKTOP_UNCHANGED:True`) — raw Godot fullscreen leaves the physical monitor at `3840x2160`.
   - **Green Physical Mode Switch & Exact Centering Origins**:
     - `GREEN_640x480_FULLSCREEN_MODE:640x480@144Hz:32bpp` (`client=640x480|origin=0,0|window=0,0,640,480`)
     - `GREEN_544x416_FULLSCREEN_MODE:640x480@144Hz:32bpp` (`origin=48,32`, `48px` left/right and `32px` top/bottom `(0,0,0)` black bars exact, 4-px RGBY frame bounds `48..591, 32..447` exact)
     - `GREEN_320x240_FULLSCREEN_MODE:640x480@144Hz:32bpp` (`origin=160,120`, `160px` left/right and `120px` top/bottom `(0,0,0)` black bars exact, 4-px RGBY frame bounds `160..479, 120..359` exact)
     - `GREEN_F1_FULLSCREEN_MODE:640x480@144Hz:32bpp` (`origin=48,32`, unified F1 `Apply()` path)
     - In-engine `green-viewport-640x480.png`, `green-viewport-544x416.png`, `green-viewport-320x240.png` verified exact `(255,255,255)` / `(0,0,0)` 1:1 logical pixels.
   - **Non-Registry `savedMode` Restore Verified**:
     - Starting from temporary non-registry display mode `3840x2160@60Hz:32bpp` while `ENUM_REGISTRY_SETTINGS` remained `3840x2160@144Hz:32bpp`:
       - Fullscreen entered `640x480@60Hz:32bpp`,
       - Focus-out restored `3840x2160@60Hz:32bpp` (not `144Hz` registry),
       - Focus-in re-entered `640x480@60Hz:32bpp`,
       - `Alt+Enter` toggle off restored `3840x2160@60Hz:32bpp`,
       - Process exit while fullscreen restored `3840x2160@60Hz:32bpp`,
       - `ENUM_REGISTRY_SETTINGS` remained `3840x2160@144Hz:32bpp` throughout.

3. **Remaining Physical Verification Step (Held While Lead Runs Audio/Events)**:
   - Safe Win32 Per-Monitor-V2 `PresentPhysicalCenteredRgba` (`SetDIBitsToDevice`) is compiled and ready for a coordinated run of `tools/test_original_fullscreen.ps1` once desktop/process exclusivity is available, to confirm the 1-px `(12,12)/(13,12)` desktop checkerboard assertion flips `ok=True` on the `150%`-scaled desktop without touching any other processes.

---

## 4. Owned Files

- `Scripts/WindowsDisplayMode.cs`
- `Scripts/GameSettings.cs`
- `tests/test_original_fullscreen.gd`
- `tools/test_original_fullscreen.ps1`
- `docs/compatibility/fullscreen-mode-verification.md`
- `.omo/evidence/c12-host-fullscreen/`
