# EmulationStation Preview Aspect Ratio

## Issue

In EmulationStation's game-list preview, screenshots and videos were reported
to appear stretched to fill the preview area. Portrait games make the horizontal
stretching most obvious.

## Findings

- The checked-in settings file is
  `McAtariPi5/opt/retropie/configs/all/emulationstation/es_settings.cfg`.
- It selects `carbon-2021` with `GamelistViewStyle` set to `automatic`.
- Theme assets are restored from the Pi's `ExtremeSSD` backup by
  `McAtariPi5/ra_final.sh`; they are not checked into this repository.
- The active theme is installed at
  `/etc/emulationstation/themes/carbon-2021/theme.xml`. Its detailed screenshot
  (`md_image`) and video (`md_video`) previews each use
  `<maxSize>920 400</maxSize>`, not a forced `<size>`.
- EmulationStation's `maxSize` scaling constrains the media to the preview box
  while preserving its source aspect ratio. No separate `theme.xml` override
  was found under the EmulationStation configuration or the user's home folder.
- The installed Carbon 2021 theme is a clean Git checkout. The `ExtremeSSD`
  backup is not mounted in this environment, so its corresponding source copy
  could not be checked.
- `StretchVideoOnScreenSaver` and `SlideshowScreenSaverStretch` are unrelated
  to the game-list preview and should not be changed as a workaround.

## Arcade Burger Time check

The arcade gamelist at
`/opt/retropie/configs/all/emulationstation/gamelists/arcade/gamelist.xml`
maps `btime.zip` (Burger Time) to `./media/screenshots/btime.png`. The original
file was 640 x 480 and had PNG metadata identifying MAME 0.153 and the Data East
Burger Time set. This indicates MAME provenance, but does not establish whether
MAME made the screenshot directly or it was downloaded by a scraper.

## Replaced arcade screenshots

### Scraping and verification

Used Skyscraper 3.21.0 with the `mame` platform and `noresize` flag, scraping
the candidate ROM ZIPs into a temporary cache so existing media and cache
entries would not be overwritten. ScreenScraper provided 19 images; it did not
find `breakout`, so that image was fetched from ArcadeDB. Each returned image
was checked as a valid PNG and compared with MAME's display orientation. The
640 x 480 originals were backed up before replacement.

`mpatrol.png` was excluded from the final replacements. MAME marks Moon Patrol
as `ROT0` and ScreenScraper identifies it as horizontal, so its original
640 x 480 landscape screenshot was restored.

### Breakout aspect correction

The ArcadeDB Breakout image arrived as a 230 x 688 raw-raster screenshot. At
the theme's 920 x 400 maximum, that ratio made the preview unusually narrow.
Breakout's MAME display is rotated; the target cabinet display aspect is 3:4
(4:3 rotated to portrait), not the raw screenshot's 0.334 ratio. The screenshot
was widened to 516 x 688 (3:4) using nearest-neighbor scaling, preserving pixel
art. The raw image also had a full-height red border on its left edge; that
two-pixel-wide border was removed from the corrected version. The untouched
ArcadeDB download is retained as
`breakout-skyscraper-arcadedb-raw.png` in the backup directory.

Originals are backed up in
`/home/danc/RetroPie/roms/arcade/media/screenshots-originals-20261106/`.
Replacements are in
`/home/danc/RetroPie/roms/arcade/media/screenshots/`.

| Screenshot | New dimensions | Skyscraper source |
|---|---:|---|
| `breakout.png` | 516 x 688 (3:4 corrected) | ArcadeDB |
| `btime.png` | 240 x 240 | ScreenScraper |
| `digdug.png` | 224 x 288 | ScreenScraper |
| `dkong.png` | 224 x 256 | ScreenScraper |
| `dkongjr.png` | 224 x 256 | ScreenScraper |
| `frogger.png` | 224 x 256 | ScreenScraper |
| `galaga.png` | 224 x 288 | ScreenScraper |
| `galaxian.png` | 224 x 256 | ScreenScraper |
| `invaders.png` | 224 x 256 | ScreenScraper |
| `milliped.png` | 240 x 256 | ScreenScraper |
| `mspacman.png` | 224 x 288 | ScreenScraper |
| `pacman.png` | 224 x 288 | ScreenScraper |
| `pengo.png` | 224 x 288 | ScreenScraper |
| `qbert.png` | 240 x 256 | ScreenScraper |
| `qix.png` | 240 x 256 | ScreenScraper |
| `sbrkout.png` | 224 x 256 | ScreenScraper |
| `superbug.png` | 240 x 320 | ScreenScraper |
| `tempest.png` | 360 x 480 | ScreenScraper |
| `tron.png` | 480 x 512 | ScreenScraper |
| `zaxxon.png` | 224 x 256 | ScreenScraper |

The theme's `<maxSize>` preserves the replacement images' source aspect ratios
when displaying them in the preview.

## Untouched horizontal composite screenshots

Some of the original horizontal-game screenshots use a different style from
the stretched portrait images fixed above. They place the gameplay screenshot
on a 4:3 landscape canvas, sometimes with transparent margins, and overlay a
fabricated retail cartridge/box image in the lower-left corner. The gameplay
image itself is not distorted in these examples; the objection is the invented
packaging artwork, which is anachronistic for arcade cabinets.

These horizontal composites were intentionally left unchanged. Do not treat
every 640 x 480 screenshot as stretched or replace this group as part of the
portrait-image fix. The user may want to replace the horizontal composites in
a future, separate cleanup, but has not asked for that change yet.

When revisiting:

1. Visually identify which screenshots actually have the 4:3 canvas and
   fabricated lower-left box overlay; dimensions alone are not sufficient.
2. Keep the existing gameplay capture and its aspect ratio intact. The desired
   change is to remove/replace the fabricated packaging overlay, not to
   stretch, squash, rotate, or otherwise alter the game image.
3. Review the current files in
   `/home/danc/RetroPie/roms/arcade/media/screenshots/`. Originals from the
   portrait replacement work are in
   `/home/danc/RetroPie/roms/arcade/media/screenshots-originals-20261106/`.
   Only change this horizontal group when explicitly requested.
