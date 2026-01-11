steps to create an SD image baseline

preliminary:
a. use pi imager tool to create an SD pi5 64-bit full OS image with:
   enabled wifi credentials, wifi country US, user danc, host McAtariPi5
b. boot to desktop GUI
c. enable raspberry pi connect
d. install updates
e. preferences, pi config, localization US UTF-8 for all
f. reboot and run:
> locale (confirm all US UTF-8)
> git clone --depth=1 https://github.com/RetroPie/RetroPie-Setup.git
> cd RetroPie-Setup
> sudo ./retropie_setup.sh
g. install all core packs
   12/30/2025 - RetroArch must be installed from source! (compatable with lr-mame)
h. install experimental lr-mame (~2 hours from source)
   1/11/2026 - installed from binary (TBD - test)
   1/11/2026 - install mame experimental package (TBD -reduce copy from Ex.SSD)
i. enable autostart emulationstation
j. edit autostart.sh and replace 'emulationstation' with 'wayfire-pi' (for remote gui)

steps:
1. clone IvarArcade project:
   git clone https://github.com/dcaputi1/IvarArcade.git ~/
   cd ~/IvarArcade/Backup_RetroPie
2. run ./cp_roms.sh (~1 hours)
3. run ./cp_opt.sh (sudo)
4. create empty roms breakout.zip and pong.zip:
   touch ~/RetroPie/roms/arcade/breakout.zip
   touch ~/RetroPie/roms/arcade/pong.zip
5. add paths for mame and (optional) retroarch, frontends to /etc/profile (user long path)
   :/opt/retropie/emulators/mame:/opt/retropie/emulators/retroarch/bin
6. run sudo ./analyze_games.sh to install tinyxml2 and python3-hid packages
7. mkdir -p /opt/retropie/configs/all/retroarch/config/MAME
8. build and install IvarArcade project components:
   cd ~/IvarArcade
   make all
   make install # deploys binaries, scripts, plugins, etc...
   NOTE: verify qbert.ini does not exist (before step 10 below - TBD omit)
   1/11/2026 - TBD: combine those 2 steps and fix rsync not telling me wtf it did!
9. reboot (for path to take effect)
10. run ~/marquees/bin/analyze_games (not sudo!)
   NOTE: make sure qbert.ini has correct map (TBD - omit)
11. clone, build, install ultrastikcmd tool for per-game joystick mapping:
  mkdir -p ~/IvarArcade/tools/linux
  cd ~/IvarArcade/tools/linux
  git clone https://github.com/dcaputi1/UltrastikCmd.git
  cd ~/IvarArcade/tools/linux/UltrastikCmd
  cd libusb-1.0.19 && ./configure --prefix=/usr/local && make && sudo make install && cd ..
  cd libusb-compat-0.1.5 && ./configure --prefix=/usr/local && make && sudo make install && cd ..
  cd libhid-0.2.16 && ./configure --prefix=/usr/local && make && sudo make install && cd ..
  cd ultrastikcmd-0.2 && ./configure --prefix=/usr/local && make && sudo make install && cd ..
  sudo ldconfig
  verify: sudo ldconfig -v | grep libhid - should show libhid.so.0 -> libhid.so.0.0.0

optional:
A. sudo apt install meld
B. sudo apt install joystick
C. sudo apt install jstest-gtk
D. sudo apt install code
required:
E. sudo apt install fuse-zip (mounts zip file w/ PNGs)
   sudo nano /etc/fuse.conf and uncomment #user_allow_other

problem log:
1/11/26 ES launch in-game tab menu, return/backspace swapped
        file missed: /opt/retropie/configs/all/retroarch/retroarch.cfg (NA?)
        file diffs: /opt/retropie/configs/arcade/retroarch.cfg
             input_playerN_joypad_index (2,3,4,0,1)
        cfg_ra/sa coins
        qbert.ini joymap NFG
