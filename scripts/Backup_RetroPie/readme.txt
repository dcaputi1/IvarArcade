lssteps to create an SD image baseline

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
h. install experimental lr-mame (~2 hours from source)
i. enable autostart emulationstation

steps:
1. run ./cp_roms.sh (~1 hours)
2. run ./cp_opt.sh (sudo)
3. create empty files: breakout.zip and pong.zip in ~/RetroPie/roms/arcade
4. add paths for mame and (optional) retroarch, frontends to /etc/profile (user long path)
  :/opt/retropie/emulators/mame:/opt/retropie/emulators/retroarch/bin
5. run sudo ./analyze_games.sh to install tinyxml2 (so python can parse mame metadata)
6. mkdir /opt/retropie/configs/all/retroarch/config/MAME (a.mkdir ...config, b.MAME)
7. g++ analyze_games.cpp -ltinyxml2 -std=c++17 -o analyze_games (rebuild w/ latest so.x)
8. reboot (for path to take effect)
9. run ./analyze_games (not sudo!)

optional:
A. sudo apt install meld
B. sudo apt install joystick
C. sudo apt install jstest-gtk
D. sudo apt install code
E. sudo apt install fuse-zip (not optional: mounts zip file w/ PNGs)
   sudo nano /etc/fuse.conf and uncomment #user_allow_other
