# MAME screen1 PNG proof of concept: session handoff

Date: 2026-10-20

## Resume here

Pi5 follow-up: the original mocked tests passed (35 checks), but the installed
MAME 0.288 rejected `emu.register_before_startup_screens`, which it does not
expose. The plugin now uses `emu.register_before_load_settings` to mark a new
session and prepares the image on its first presentation frame. The local
0.288 source confirms these hooks and the required rendering APIs. Updated
mocked tests pass (54 checks). A real-MAME smoke test using SDL's dummy video
driver reached the selection GUI and loaded the banner without Lua errors;
it was time-limited and forcibly stopped, not a clean-exit test. The fix is
deployed to `/opt/retropie/emulators/mame/plugins/screen1png`.
Physical display acceptance testing is still required.

Continue the opt-in `screen1png` proof of concept described below with a manual
display test outside the desktop session. Do not expand this into the full
dmarquees migration yet. Validation notes below describe the original Windows
handoff unless superseded by this Pi5 follow-up.

**Important user-provided environment constraint:** the Pi5 has the correct
toolchain, but actual display testing cannot be done inside VS Code while the
desktop is running because the desktop owns the screens. Editing, source
inspection, compilation, and mocked tests can happen there. Physical dual-screen
testing must be performed separately, with the desktop relinquishing display
ownership, for example from a suitable console/SSH workflow. Coordinate that
transition with the user; do not terminate the desktop or its processes without
permission.

## Current requirement

The requested proof of concept is:

- MAME owns both Pi5 display outputs.
- Output 0 (`screen0`) shows gameplay or MAME's game-selection GUI.
- Output 1 (`screen1`) shows a PNG during a single-screen game.
- When the game-selection GUI is shown on output 0, output 1 shows the existing
  standalone-MAME banner, `images/MAMELogoR.png`.
- Exercise GUI -> game -> GUI -> another game, not just direct ROM startup.
- Do not interfere with Punch-Out's native dual-screen arrangement.

The user corrected an earlier reference to using screen0 for labeled panels:
they meant **screen1**. Screen1 may eventually display generated control-panel
artwork with button labels, but the immediate task is only the PNG proof of
concept plus GUI banner behavior.

## Longer-term discussion, not settled implementation scope

Original motivation: the local dmarquees DRM daemon appears to race with MAME
when controlling the Pi5's second display. Move local rendering into MAME's
normal renderer instead of competing DRM framebuffer/modeset calls.

Current hardware is a dual-display Pi5 plus a slave Pi3. One proposed topology
was Pi5 output 0 = game, Pi5 output 1 = marquee, Pi3 = labeled control panel.
The user subsequently said they may want labeled panel images on Pi5 screen1.
Do not treat the earlier topology as final or implement remote role changes now.
The existing marquee/control-panel archive swap feature may be retained later.
Archive control-panel images and generated panel diagrams with substituted
button labels are different content types.

## Files added in the Windows session

All paths here are relative to the repository root:

- [Plugin implementation](../McAtariPi5/opt/retropie/emulators/mame/plugins/screen1png/init.lua)
- [Opt-in plugin metadata](../McAtariPi5/opt/retropie/emulators/mame/plugins/screen1png/plugin.json)
- [Installation and acceptance-test README](../McAtariPi5/opt/retropie/emulators/mame/plugins/screen1png/README.md)
- [Mocked Lua regression tests](../tools/tests/screen1png_test.lua)
- This handoff document.

**Transfer warning:** at handoff, the plugin directory and test file are
untracked, and this document is newly created. No commit, push, or deployment
has been performed. Ensure ALL these files reach the Pi5; a normal pull will
not transfer uncommitted/untracked Windows files.

No existing daemon, plugin, startup script, MAME configuration, or MAME source
was modified. No live Pi5/Pi3 processes were changed.

## How the proof of concept works

The new `screen1png` plugin is disabled by default (`start: "false"`).
Explicitly enable it using `-plugin screen1png`.

- Uses `emu.register_before_load_settings` to mark each machine session, then
  prepares artwork on the first `emu.register_frame_done` callback, including
  the internal `___empty` machine used by game selection.
- Enumerates `manager.machine.render.targets`, ignores hidden targets, and
  selects the second visible target. Does not blindly index Lua target 2,
  since hidden snapshot targets can appear in the list.
- Refuses to use the GUI's current target.
- Counts emulated screens; systems with more than one are skipped entirely.
- GUI (`___empty` or empty ROM name): loads the MAME banner.
- Single-screen game: loads the configured fixed test PNG.
- Uses `emu.bitmap_argb32.load` and `render:texture_alloc`.
- Uses `emu.register_frame_done` to draw an opaque black rectangle followed by
  the image into the target's `ui_container` every presentation frame.
- Centers the image, fitting within the output while preserving aspect ratio
  and accounting for target pixel aspect.
- Reuses the bitmap/texture between frames; adapts drawing bounds to resize.
- Frees textures with a retained machine-stop notifier and clears target
  references, then reacquires them in the next machine session.
- Logs missing output and image open/read/close/decode errors explicitly.
  On these errors, it does not draw: the ordinary second-output view remains.
- Does not draw if the UI target is subsequently moved onto output 1.

Default paths:

```text
Game:   /home/danc/IvarArcade/images/RetroPieMarquee.png
GUI:    /home/danc/IvarArcade/images/MAMELogoR.png
```

Overrides:

```text
MAME_SCREEN1_GAME_PNG
MAME_SCREEN1_BANNER_PNG
```

This is an overlay prototype. The normal game view may still render underneath
the opaque background. It does not implement an artwork-only render target,
ROM-based lookup, labeled-panel generation, swapping, exact legacy bottom
alignment, rotation compensation, or non-MAME display-ownership handoff.

## Validation status

Completed:

- Inspected the supplied MAME source for the relevant exposed Lua APIs,
  output creation, GUI lifecycle, and draw order.
- Confirmed plugin JSON is parseable and disabled by default.
- Confirmed both default PNG assets exist.
- Checked added files for trailing whitespace.

NOT completed:

- Lua syntax/runtime regression execution.
- Running the plugin inside an actual MAME binary.
- Physical screen mapping, GUI/game transitions, Punch-Out behavior, image
  orientation, performance, or contention testing on Pi5.

Windows had no runnable Lua/MAME installed. A Lua 5.4.8 interpreter was compiled
from MAME's bundled Lua source using the installed Visual Studio compiler.
Compilation succeeded, but Windows group policy blocked execution. No bypass
was attempted. The temporary build directory was removed.

The mocked tests were manually reviewed but must not be reported as passing.
Run them using the Pi5's available Lua 5.4 executable:

```bash
cd /home/danc/IvarArcade
lua tools/tests/screen1png_test.lua
# If the executable is versioned, use lua5.4 instead.
```

The tests cover hidden-target filtering, GUI/game path selection, repeat frames,
aspect-fit bounds, resize/pixel aspect, texture release/reacquisition, GUI target
protection, multi-screen exclusions, missing output, missing/corrupt/read/close
image failures, path overrides, and zero-sized targets. They use mocked MAME
objects, not the real renderer.

## Manual Pi5 display test

Only after the desktop has relinquished display ownership:

1. Deploy only the `screen1png` directory to
   `/opt/retropie/emulators/mame/plugins/screen1png`.
   Avoid a broad install that unnecessarily changes other system files.
2. Stop only the LOCAL Pi5 dmarquees instance and prevent automatic restart.
   Leave the slave Pi3 alone. The current daemon recognizes `EXIT` via its FIFO.
   Send this only when the FIFO reader is confirmed running, since opening an
   unattended FIFO for writing can block:

   ```bash
   printf 'EXIT\n' > /tmp/dmarquees_cmd
   ```

3. Verify the local daemon has exited before starting MAME.
4. Launch MAME directly, not via RetroPie runcommand hooks. Existing hooks and
   the existing `marquee` plugin write to the local FIFO and could block after
   the daemon stops. Explicitly disable that plugin for the test.
5. Start without a ROM argument:

   ```bash
   cd /opt/retropie/emulators/mame
   export MAME_SCREEN1_GAME_PNG=/home/danc/IvarArcade/images/RetroPieMarquee.png
   ./mame -inipath ini -plugins -plugin screen1png -noplugin marquee \
       -numscreens 2 -screen0 screen0 -screen1 screen1 -verbose
   ```

6. Check verbose monitor enumeration. With MAME's SDL monitor provider, physical
   monitor names are `screen0`, `screen1`, etc.; reverse mappings if needed.
   Two output windows do not prove two distinct physical monitors are in use.
7. Verify selection GUI on output 0 and MAME banner on output 1.
8. Select a single-screen game; output 1 should show the test PNG.
9. Test pause, Tab menus, soft reset, and GUI/game transitions. A direct ROM
   launch normally exits MAME instead of returning to game selection.
10. Verify Punch-Out's two native screens remain intact.
11. Verify explicit diagnostics for bad image paths/data and clean exit/relaunch.
12. Restore the user's normal display/daemon setup after testing.

The active backend and installed MAME version have not been verified on the
Pi5. Compare actual API support and startup logs with the supplied source before
assuming compatibility. Do not assume the Windows checkout revision matches
the deployed binary.

## Source findings supporting the design

The Windows session had sibling checkouts of `IvarArcade`, `mame`, and
`RetroPie-Setup`. MAME HEAD inspected was `ab2d1ca215c`, dated 2026-10-20.
Paths below are relative to the MAME source root:

- `src/osd/sdl/video.cpp`: `video_init` creates `numscreens` host windows,
  independently of the number of emulated game screens.
- `src/osd/modules/osdwindow.cpp`: `create_target` and `set_starting_view`
  create a render target and choose a view for each output.
- `src/osd/modules/monitor/monitor_sdl.cpp`: enumerates SDL monitors with
  `screen0`, `screen1`, etc. names.
- `src/emu/render.cpp`: artwork lookup, configured view selection, target list.
  `fallback_artwork` is conditional, not an always-added layout;
  `override_artwork` bypasses normal external/default layout loading paths.
  Therefore a global artwork override is not a safe universal integration.
- `src/frontend/mame/luaengine_render.cpp`: exposes per-target `ui_container`,
  bitmap decoding, texture allocation/freeing, and textured quad drawing.
- `docs/source/luascript/ref-render.rst`: documentation for these APIs.
- `src/emu/video.cpp`: UI drawing -> plugin frame hook -> OSD window updates.
- `src/frontend/mame/ui/ui.cpp`: UI containers are cleared each update, so
  plugin drawing must happen every presentation frame, not just on game start.
- `src/frontend/mame/mame.cpp`: game-selection lifecycle uses `___empty`;
  `ui_initialize` invokes the before-startup-screens callback after UI setup.
- `src/mame/nintendo/punchout.cpp`: native screen tags are `top` and `bottom`,
  with a built-in dual-screen layout. `screen1` is a host-output monitor
  selection option, not the name of Punch-Out's emulated second screen.

RetroPie-Setup's `scriptmodules/supplementary/sdl2.sh` referenced SDL 2.32.10.
Public source examined:
<https://github.com/RetroPie/SDL/blob/retropie-2.32.10/src/video/kmsdrm/SDL_kmsdrmvideo.c>
Its KMSDRM implementation enumerates connectors on one selected DRM device and
supports per-display window handling. That is evidence of infrastructure, not
proof that the installed backend can drive the user's monitors correctly.

## Existing project surfaces for later migration

- [DRM daemon](../dmarquees/dmarquees.c): `try_reset_crtc` acquires master,
  modesets, and drops master. Panel/refresh failures can schedule retries.
  The presumed race is plausible from this ownership model, but was not
  confirmed by runtime logs.
- [Helpers](../dmarquees/helpers.c): scaling and multi-screen detection.
  Current multi-screen detection reads per-game `numscreens`; do not reuse that
  as the new plugin's exclusion test, since normal games now request two outputs.
- [Existing marquee plugin](../McAtariPi5/opt/retropie/emulators/mame/plugins/marquee/init.lua):
  ROM lifecycle, remote and local sends, panel menu, controller warnings.
- [Network sender](../McAtariPi5/home/danc/scripts/dmarquees-send.sh)
- [Pi3 bridge](../McAtariPi5/home/danc/scripts/dmarquees-netbridge.py)
- [Archive swap helper](../McAtariPi5/home/danc/scripts/swap_banner_art.sh):
  currently directs SWAPART to Pi3 when Pi3 is present.
- [MAME launcher](../McAtariPi5/home/danc/scripts/run_mame.sh)
- [RetroPie launch hook](../McAtariPi5/opt/retropie/configs/all/runcommand-onlaunch.sh)
- [Autostart](../McAtariPi5/opt/retropie/configs/all/autostart.sh)
- [Console autostart](../McAtariPi5/opt/retropie/configs/all/autostart-nogui.sh)

The current daemon selects labeled-panel rendering through Pi5-specific
`_splash_mode` logic. Repurposing the Pi3 for that role would require explicit
role selection, transmitting the chosen panel mode, and deploying templates,
label maps, and conversion tools there. None of that is part of this POC.
