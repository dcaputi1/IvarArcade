# MAME panel output plugin

The `screen1png` plugin displays the selected control-panel image on MAME output
1 for single-screen games when the Pi5 has both the Pi3 marquee and dual-display
mode enabled. Panel selection remains in `~/.panel`; the local dmarquees daemon
continues applying the game's `.dcp`, `.mcp`, or `.mkw` labels and publishing
the rendered PNG. MAME reads that PNG and owns the output while the game runs.

MAME's game-selection UI displays `images/MAMELogoR.png`. If panel mode is `NA`,
the same banner is displayed during a game. `OFF` state leaves the output
untouched. Native multi-screen systems are never covered, preserving both
Punch-Out and Super Punch-Out gameplay screens. The existing remote marquee
commands are unchanged, so the Pi3 continues to display game marquees.

The daemon and plugin exchange state through `/tmp/dmarquees_panel_state`.
The daemon atomically publishes `PANEL|rom|code|generation`, `DEFAULT|rom|generation`,
`GUI|generation`, or `OFF|generation`. The generation changes on each update,
including repeat launches of the same game, and panel state is published only
after rendering finishes. The plugin checks for changes every 30 MAME frames
and loads the corresponding image from
`/tmp/dmarquees_dcpanel.png`, `/tmp/dmarquees_mcpanel.png`, or
`/tmp/dmarquees_mkwheel.png`. Override the state and banner paths with
`MAME_PANEL_STATE_FILE` and `MAME_PANEL_BANNER_PNG`.

The `run_mame.sh` launcher enables two outputs and sets `MAME_PANEL_OUTPUT=1`
only when both `~/.pi3_present` and `~/.pi5_dual_display` are true. In all
other launches the variable is `0`, so the plugin cannot overlay a stale panel
state on another display mode. The plugin is enabled by default through its
`plugin.json`.

## Validation and rollout

Run the mocked regression tests from the repository root with Lua 5.4:

```bash
lua tools/tests/screen1png_test.lua
```

The tests cover dynamic panel changes, default/disabled states, native
multi-screen games, output targeting, aspect-preserving placement, texture
limits, and image/state I/O failures. Physical Pi5 testing is still required to
confirm the SDL output mapping and display ownership handoff before removing
the older per-game second-output layouts.

On the Pi5, verify:

1. With Pi3 present and dual-display enabled, a single-screen MAME game displays
   the currently selected panel and its game-specific labels on output 1.
2. Changing panels in the MAME menu updates the image without restarting.
3. `NA` displays the MAME banner; the Pi3 continues showing the game marquee.
4. Punch-Out and Super Punch-Out retain both game screens, with no panel drawn.
5. With either mode flag disabled, the plugin does not draw over the daemon's
   existing output.
6. Exiting MAME returns output ownership to dmarquees.
