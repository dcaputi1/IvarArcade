MicroCenter Atari Pi Retro Console Arcade - "McAtariPi"
This readme documents baseline proceedures and troubleshooting notes
for the RetroPie devices used in my Ivar Arcade Game Setup.

Abreviations used:
DC = Me (i.e. DC-Panel1 = UltraStick/dual spinner control panel)
Mc = MicroCenter
RP = RetroPie
RA = RetroArch / LibRetro front end for RP
ES = EmulationStation front end for RA
SA = StanAlone MAME font end (runs from shell or RA RunCommand customized emu)
NA = Not Applicable / Non-Assigned front end (i.e show RP marquee)
FS = Fight Stick (as in Atari FS panel)

====================================
  Creating an SD image baseline Pi5
====================================

preliminary:
a. use pi imager tool to create an SD pi5 64-bit full OS image with:
   enabled wifi credentials, wifi country US, user danc, host McAtariPi5
b. boot to desktop GUI
c. enable raspberry pi connect
   (email: dcaputi@optonline.net, pass: E....D....123!)
d. install updates
e. preferences, pi config, localization US UTF-8 for all
f. reboot and run:
> locale (confirm all US UTF-8)
> git clone https://github.com/dcaputi1/IvarArcade.git
  then reload this readme.txt from ~/IvarArcade/McAtariPi5, make sure nothing above changed
> cd ~/IvarArcade; git switch feature/pi5-setup-scripts
  10/3/2026: use above to switch to this feature branch
> git clone --depth=1 https://github.com/dcaputi1/RetroPie-Setup.git
  2/28/2026: use dcaputi1/Retropie-Setup.git for *Trixie* (*using 5/27...)
  5/27/2026: attempt to fix mapdevice feature for duplicate device IDs
> cd RetroPie-Setup
> sudo env IVAR_MAME_PROFILE=full ./retropie_setup.sh
  use IVAR_MAME_PROFILE=full right now to build full MAME with upstream arcade.flt and the mame binary
  9/26/2026: Could not successfully _update_hook... [frotz, joy2code, kodi, lincity-ng, openttd, supertux, uqm]
g. install all core packs - notes:
   5/27/2026: install emulationstation-dev
   9/26/2026: skip joy2code (bad _update_hook above and N/N)
h. install experimental mame package (~2 hours from source)
   NOTE: for arcade-only build use sudo env IVAR_MAME_PROFILE=arcade ./retropie_setup.sh
   5/27/2026 - 5/31/2026: several revs needed to fix full mame build, may've broke bookworm
   9/26/2026 - needed to Hit ENTER *after* invoking the menu to start building!
i. 5/27/2026: SKIP [install experimental lr-mame]
j. enable autostart emulationstation
k. [optional] install Skyscraper
l. install Atari consoles: lr-atari800, lr-stella2014 and lr-prosystem

Automated post-RetroPie setup (run these scripts as user danc, not with sudo):
Each phase appends its terminal output and errors to ~/setup_pi5.log.
1. Connect and mount ExtremeSSD at /media/danc/ExtremeSSD, then run:
   bash ~/IvarArcade/McAtariPi5/setup_pi5_phase1.sh
   This takes ownership of /opt/retropie, copies ROMs, installs the game-analyzer
   dependencies and USB rule, sets the PATH, and runs make install-force.
2. Reboot (the PATH change must take effect). HOLD SHIFT during reboot to skip
   pic_frontend, if needed. Then run:
   bash ~/IvarArcade/McAtariPi5/setup_pi5_phase2.sh --with-pi3
   This builds UltrastikCmd, installs its sudoers rules, restores the MAME and
   frontend assets, generates game-analysis files, installs marquee dependencies,
   and disables HDMI audio. Omit --with-pi3 to skip wired LAN connection to marquee server
3. Reboot to apply the HDMI audio change, then run:
   bash ~/IvarArcade/McAtariPi5/setup_pi5_phase3.sh
   This configures ALSA to use the connected USB audio device. Connect the USB
   audio device before running this phase.

If using a Pi3 as a remote marquee node, configure the Pi3 connection as 10.77.77.3/24 and verify from the Pi5 with:
   ping -c2 10.77.77.3
Run ssh-copy-id danc@10.77.77.3 if this is a fresh Pi3 baseline.

The Pi Imager, desktop localization, RetroPie core-pack selection, experimental
MAME build, autostart selection, and Atari emulator installation remain manual
prerequisites. The full MAME source build still takes hours.

note: VS code's AI and GitHub credentials will need initialization - good luck with that!
(open browser first and log in github user dcaputi1)
...ask AI to set git user to 'Dan Caputi' and email 'dcaputi1@users.noreply.github.com'

===========================================
  Pi3 baseline setup
===========================================

preliminary:
a. use pi imager tool to create an SD pi3 32-bit OS image with:
   enabled wifi credentials, wifi country US, user danc, host McAtariPi3
   4/4/2026 - Trixie OK but ReroPie installs from source takes time
b. boot to desktop GUI
c. enable raspberry pi connect
   (email: dcaputi@optonline.net, pass: E....D....123!)
d. install updates
e. preferences, pi config, localization US UTF-8 for all
f. reboot, open command prompt and run:
> locale (confirm all US UTF-8)
> git clone https://github.com/dcaputi1/IvarArcade.git
  then reload this readme.txt from ~/IvarArcade/McAtariPi5, make sure nothing above changed
> git clone https://github.com/dcaputi1/RetroPie-Setup.git
  4/4/2026 - any diffs with https://github.com/RetroPie/RetroPie-Setup.git ?
> cd RetroPie-Setup
> sudo env IVAR_MAME_PROFILE=full ./retropie_setup.sh
        use IVAR_MAME_PROFILE=arcade later if you want the stripped-down mamearcade build from the same repo
g. install all core packs, enable boot to ES
h. do NOT reboot, from command prompt:

 > mkdir -p ~/MAME_0.256_EXTRAs
 > cp -v /media/danc/ExtremeSSD/Mame/MAME_0.256_EXTRAs/marquees.zip ~/MAME_0.256_EXTRAs/
 > cp -v /media/danc/ExtremeSSD/Mame/MAME_0.256_EXTRAs/cpanel.zip ~/MAME_0.256_EXTRAs/
 > sudo apt update   
 > cd IvarArcade
 > sudo apt install -y libtinyxml2-dev fuse-zip librsvg2-bin
 > sudo chown -R danc /opt/retropie
 > make install

4/4/2026 NA - sudo dpkg-reconfigure locales (change GB to US)
4/4/2026 NA - sudo mkdir -p /media/danc/ExtremeSSD
4/4/2026 NA - sudo mount /dev/sda1 /media/danc/ExtremeSSD

i. Configure direct wired link static IPs (NetworkManager):

   # Pi3 side
   sudo nmcli con add type ethernet ifname eth0 con-name eth0-static ip4 10.77.77.3/24
   sudo nmcli con up eth0-static

   # Pi5 side
   sudo nmcli con add type ethernet ifname eth0 con-name eth0-static ip4 10.77.77.5/24
   sudo nmcli con up eth0-static

   # Verify from Pi5
   ping -c2 10.77.77.3

   # If this is a fresh Pi3 baseline, run once on the Pi5:
   ssh-copy-id danc@10.77.77.3
   04/4/2026 - may not need this

===========================================
  Problem / troubleshooting log:
===========================================

1/11/26 [x] ES launch in-game tab menu, return/backspace swapped
        [ ] file missed: /opt/retropie/configs/all/retroarch/retroarch.cfg (NA?)
        [x] file diffs: /opt/retropie/configs/arcade/retroarch.cfg
            input_playerN_joypad_index (2,3,4,0,1)
            cfg_ra/sa coins
        [x] qbert.ini joymap NFG
        [x] git and AI got stupid: I wound up logged into GIT as dcaputi1-dev
        from then on, using the GUI or AI for source control was impossible.
        No clue how it happened or how to avoid it in the future.
        Re-baseline the SD card and pay more attention when launching VS Code!
1/14/26 [x] Missing ES controler setup (goes straight to Gamepad setup)
        added install-force target
1/15/26 can't run ES game
        [ ] missing /opt/retropie/reroarch/retroarch.cfg
        [x] link to mame in /opt/retropie/configs/mame/mame (maybe should be parent)
        [ ] mame installed in /opt/retropie/retroarch/mame (does it work SA?)
        [ ] missing /opt/retropie/emulators/retroarch/bin/retroarch
1/16/26 [x] redo SD baseline because too many diffs yesterday (BTW, other comments lost to bad CM)
1/17/26 [x] tracking link to mame in mame/mame from 1/15 - weird...
        apparently retroarch mame package install creates a ~/.mame symlink to /opt/retropie/configs/mame so that when my cp_opt.sh does this:
        ln -s /opt/retropie/emulators/mame/ /home/danc/.mame
        we create a link 'mame' in /opt/retropie/configs/mame to /opt/retropie/emulators/mame
        [x] cp_opt.sh - no scripts in ~/scripts (get rid of step for now) where are all my scripts?
        [x] move cp_opt.sh to last step (make install-final must run first)
        [x] xinmo swap failed (never updated after moved from joycode 4-5 to 2-3)
        [x] moved default.cfg R/O to EOF (but no can do - see next comment)
        [x] xinmo swap unable to write default.cfg (keep it 666)
1/20/26 [x] redo again - games don't load (make install-force wasn't run?)
1/24/26 [X] leds don't work unless start buttons are defined (some games use player buttons)
1/31/26 [X] running sa mame vector game in ra breaks tab menu return key
        [x] fix pics, vids, marquees - skyscraper needed 
2/13/26 Re-baseline -
        [x] cp_roms.sh not executable
        [x] make install-force failed (missing chown -R danc /opt/retropie)
        [x] ra_final.sh log shows twice (once with '+' once without)
        [x] analyze_games failed: couldn't write ini files (re: install-force fail)
        [x] ra asteriods fail (missings +x on run_mame.sh)
        [x] sa asteriods inputs NFG
        [ ] sa popeye performance/sound bad
2/26/26 Trixie baseline
        [x] build all packages from source and keep code in tmp/build
        [x] UltrastikCmd build fail - AI fixed (I hope!)
        [ ] iCode Atari paddles integration - always using js0-js4 NFG!
            For now, I'll just plug iCode in after startup.
        [ ] enhance xinmo-swap to deal with ALL random jsN device order?
        [ ] trouble with USB power - need to add another 5v supply?
2/28/26 [x] need custom 2-way joystick map for 4-way far left/right (Defender)
        [x] autostart on Trixie: ES doesn't start but Command Prompt runs ES
            also, exit to desktop prompts for password (note prelim.j above)
3/3/26  [x] defender 2-way Ultrastik map NFG using L/R as "reverse"
3/6/26  [x] defender L/R reverse NFG either, using defenderlr plugin
4/10/26 [ ] moved SA punch-out/popeye fix to mame.ini and created promblems (?)
        [ ] pong on RA looks bad
        [ ] indytemp on RA does not run
4/11/26 [ ] lightgun idea: House of the Dead (hotd) fail - try skipframes 1
4/12/26 [ ] Atari 2600 paddles will NOT work with DC-Panel1 hub
        [ ] pong is still garbage even with Atari paddles
5/3/26  [X] Mario Kart Wheel doesn't work in RA/ES. Can't map analog.
        [X] use 'mame' with runcommand for all games? (no more lr-mame at all!)
5/6/26  [X] XinMo swap screw up again! Does it work when mame is run from within ES?
            Also feals like the self-correction feature is foo-bar
            default.cfg got restored (unswaped) but many (all?) cfgs in cfg_sa were left backwards!
5/7/26  [X] AI broke it (5/6/26) and AI fixed it
5/8/26  [X] effect scanlines woefully insufficient - simply can't get it working for spyhunt
            to do: revisit shaders in MAME SA - got to be a way!
        [X] turning off scanlines in spyhunt - AI can't figure it out
5/9/26  [x] xinmo still crap: (and logging is inconsistent)
        [X] stupid squares between ...Controller' -- 1n buttons (n=5|3) AND state -- manual
        [X] "[HW] Normal:" (whats with the brackets?) "[ERROR] Cfg directories disagree..."
5/10/26 [X] try Claude in Co-Pilot for scanlines shader help
5/12/26 [ ] how to easily switch between effects scanlines and scanlines glsl?
5/13/26 [X] need a shutdown option from the frontend menu
5/15/26 [X] xinmo swap still NFG - change unswap to force copy from ~/McAtariPi5/...
        [X] pi3 way out of date and NO WIFI! ... WTF!?
5/27/26 [ ] Attempt new Trixie baseline
5/28/26 [X] Trixie continued - Pi Connect screen share failed after RetroPie setup
        root cause: no active Wayland desktop session for user danc
        fix: RetroPie autostart / raspi-config boot to desktop auto-login restored
              lightdm/Wayland; keep IvarArcade autostart.sh launching pic_frontend.py
              and use 'sudo systemctl start lightdm' for Exit to X/Wayland Desktop
6/19/26 [X] need sudoers for ultrastikcmd (called in runcommand scripts)
            added to /etc/sudoers.d/autostart-nopass (verify path with 'which ultrastikcmd')
7/13/26 [X] now using ctrlr/*.cfg files rather than mame generated ad-hoc maps in ./cfg/
        [ ] test PEDAL1 and PEDAL2 in allctrlrs.cfg system default
        [ ] update ES collections for Atari and DC-Panel
7/25/26 [X] after Trixie update, autostart menu exit to desktop wanted password
            Edit /etc/lightdm/lightdm.conf uncomment/edit autologin-user... 2x lines
        [X] run retropie-setup.sh add Atari console emus
8/03/26 [X] update IvarArcade with Atari console config
        [X] update ExtremeSSD with Atari console assets
        [ ] test rebase with new Atari console emus
9/08/26 [X] Caverns of Mars NFG - bad OS-B rom had no PIA
9/11/26 [X] started organized testing: A for asteriods, FS was ok but switching the marquee to DC then test, NFG.
            discovered the MAME .ctrlr file can be out of sync with the marquee .panel file, so...
9/12/26 [X] leds on dcpanel should stay off if .ctrlr = FS
        [X] refactor? selecting dcpanel in marquee plugin should prompt
            "Controller map currently AtariFS. Switch to DCpanel1? Y/N (MAME restart required)"
            Also, selecting AtariFS in pic frontend menu should update .panel = FS
9/27/26 [ ] rebaseline w/ full Trixie after backing up bookworm 256 Gb to ExtremeSSD/Atari/MicroCenter
            emulationstation autostart is premature
            (hangs on reboot 7. and rebooting to command prompt mounts ExtremeSSD as root - NFG)
        [X] no favorites in EmulationStation - delete arcade folder from newly added console bin copy
            (the bin copy put a higher priority gamelist.xml from old Atari FS roms folder)
