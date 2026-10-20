# screen1png proof of concept

An opt-in MAME plugin that draws a centered, aspect-preserving PNG over output 1.
It makes no DRM calls and does not change output 0, game drivers, artwork views,
the existing marquee plugin, or the Pi3 protocol.

- Game-selection GUI (`___empty`): displays `images/MAMELogoR.png`, the existing
  standalone-MAME default banner.
- Single-screen game: displays `images/RetroPieMarquee.png` as a fixed test image.
- Multi-screen game (including Punch-Out): does not draw or change either output.

Paths default to `/home/danc/IvarArcade/images`. Override them with
`MAME_SCREEN1_GAME_PNG` and `MAME_SCREEN1_BANNER_PNG`. Images are loaded once per
machine session, not every frame. Resources are released when the session stops,
including GUI/game transitions. Paused frames and menus continue to show the PNG.
An unreadable or invalid image is logged; the normal second-output view remains
visible instead of silently substituting another image.

## Isolated Pi5 test

Copy this directory to `/opt/retropie/emulators/mame/plugins/screen1png`. The
plugin is disabled by default; no global configuration changes are required.
Use the deployed MAME executable with the Lua rendering APIs present in the
supplied MAME source.

Before testing, stop **only the local Pi5** dmarquees daemon and prevent its
supervisor from restarting it. For example, with its FIFO reader running:

```bash
printf 'EXIT\n' > /tmp/dmarquees_cmd
```

Verify that the local process has exited before starting MAME. Leave the Pi3
alone. Do not run launch hooks that write to the now-unattended local FIFO.
For this test, launch MAME directly, not through the existing runcommand hooks.
Disable the existing `marquee` plugin so it cannot write to that FIFO either.

From the MAME installation directory:

```bash
cd /opt/retropie/emulators/mame
./mame -inipath ini -plugins -plugin screen1png -noplugin marquee \
    -numscreens 2 -screen0 screen0 -screen1 screen1 -verbose
```

Start **without a ROM argument** to test the selection GUI first. Select a
single-screen game, return to the selection GUI, and select another game. A
direct ROM launch normally exits MAME when the game ends rather than returning
to the selection GUI.

To choose a different game PNG:

```bash
export MAME_SCREEN1_GAME_PNG=/home/danc/mnt/marquees/sf.png
```

The `screen0`/`screen1` monitor names above match MAME's SDL monitor provider.
Check verbose monitor enumeration and reverse the mappings if necessary.
Output numbers are zero-based; Lua's target list is one-based and includes
hidden targets, so this plugin selects the second **visible** target.
Two distinct monitors must be exposed by the active SDL backend. Creating two
outputs alone does not prove that they are on different physical monitors.

## Acceptance checklist

On the Pi5, verify:

1. Selection GUI stays on output 0; output 1 shows the MAME banner.
2. A single-screen game shows the test PNG on output 1 without covering gameplay.
3. Pause, Tab menus, resize/mode changes, and game reset preserve the image.
4. Returning to the GUI restores the MAME banner; another game restores the test PNG.
5. Punch-Out retains both native screens, with no plugin drawing.
6. Missing/corrupt PNGs produce diagnostics without crashing MAME.
7. Exit/relaunch works without DRM contention or stale textures.

This is an overlay proof of concept: MAME may still render the game's normal
view beneath the opaque background. It intentionally does not implement ROM
artwork lookup, labeled-panel generation, image swapping, exact legacy
bottom-alignment, rotation compensation, or ownership handoff outside MAME.
Hardware/backend behavior and performance require Pi5 testing.

## Local regression tests

From the repository root, using Lua 5.4:

```bash
lua tools/tests/screen1png_test.lua
```

The tests execute the real plugin with mocked MAME objects. They cover output
selection, lifecycle, aspect-preserving bounds, and failure paths, but do not
replace the hardware acceptance checklist.
