# EmulationStation Preview Aspect Ratio

## Issue

In EmulationStation's game-list preview, screenshots and videos appear stretched
to fill the preview area. Portrait games make the horizontal stretching most
obvious. The active theme files were not available in the repository when this
was investigated, so the rendering fix has not yet been made.

## Findings

- The checked-in settings file is
  `McAtariPi5/opt/retropie/configs/all/emulationstation/es_settings.cfg`.
- It selects `carbon-2021` with `GamelistViewStyle` set to `automatic`.
- Theme assets are restored from the Pi's `ExtremeSSD` backup by
  `McAtariPi5/ra_final.sh`; they are not checked into this repository.
- The public Carbon 2021 `theme.xml` inspected during investigation defines
  separate detailed-image and video previews with `<maxSize>920 400</maxSize>`.
  That layout alone does not explain the reported stretching; the installed
  theme version or a local override still needs to be checked.
- `StretchVideoOnScreenSaver` and `SlideshowScreenSaverStretch` are unrelated
  to the game-list preview and should not be changed as a workaround.

## Next steps on the Pi 5

1. Locate the active `carbon-2021/theme.xml` (including any local override) and
   inspect the `detailed` and `video` view definitions for `md_image` and
   `md_video`.
2. Check whether either preview component uses a forced `<size>` or another
   setting that stretches content. Prefer a bounded `<maxSize>` that fits
   within the preview area and preserves the source aspect ratio.
3. Make the smallest theme change, then verify both a portrait screenshot and
   a portrait video, as well as a landscape preview.
4. If the active theme is modified outside the repo, bring the corresponding
   source/configuration change into this repository so it survives restoring
   assets from the backup.

No theme or settings changes have been made yet.
