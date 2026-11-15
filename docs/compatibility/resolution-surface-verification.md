# Resolution surface verification

Original logical-size contract is pinned by the eight-row graphics resize
fixture: clamp each dimension to 1..640 / 1..480, and snapshot size equals
Graphics.width/height. The existing logical comparison passed earlier.

Fresh Windows physical captures on 2026-11-13 initially showed only the desktop.
Setting the owned test window always-on-top, allowing capture and moving it to
foreground made all four states visible. Independent review st_01a1d3ae passed
native, double, fullscreen and restored framing; it did not establish filtering.

Automated exact-color border measurements from 3840x2160 screen captures:
- native/restored field spans x100..739, y100..579: 640x480.
- double spans x100..1379, y100..1059: 1280x960.
- fullscreen spans x640..3199, y120..2039: 2560x1920 (4x).
  Black bars are 640 pixels left/right and 120 pixels top/bottom.

The checkerboard run completed RESIZE_SURFACE_PASS, exit 0, including every
replicated pixel at scales 1/2/4/1. Original physical measurement is now an
independent track; the port measurements are settled.
Original physical behavior is now measured in
`original-physical-resize-verification.md`: fullscreen switches the display
mode to 640x480 and centers the logical surface without scaling. The current
port's desktop-resolution enlarged presentation diverges; C12 remains open
until the fullscreen implementation and actual physical check match.

Godot 4.6 DisplayServer documentation explicitly says exclusive fullscreen
does not change the display video mode. Its Windows window_set_mode source
also only changes styles and moves the window to the current screen size.
Switching the enum alone therefore cannot close the original display-mode gap.
The Windows host needs a native display-mode lifecycle, restoring the prior
mode on toggle, focus changes and exit; that implementation remains pending.
Documentation: https://docs.godotengine.org/en/4.6/classes/class_displayserver.html
Source: https://github.com/godotengine/godot/blob/4.6-stable/platform/windows/display_server_windows.cpp

Run: `godot --path . -s tests/test_resize_surface.gd -- --physical-capture`.
