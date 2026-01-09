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
   12/30/2025 - TBD test install from binary
i. enable autostart emulationstation

steps:
1. run ./cp_roms.sh (~1 hours)
2. run ./cp_opt.sh (sudo)
3. create empty files: breakout.zip and pong.zip in ~/RetroPie/roms/arcade
4. add paths for mame and (optional) retroarch, frontends to /etc/profile (user long path)
  :/opt/retropie/emulators/mame:/opt/retropie/emulators/retroarch/bin
5. run sudo ./analyze_games.sh to install tinyxml2 and python3-hid packages
6. mkdir /opt/retropie/configs/all/retroarch/config/MAME (a.mkdir ...config, b.MAME)
7. clone, build and install IvarArcade project:
> cd ~
> git clone https://github.com/dcaputi1/IvarArcade.git
> cd IvarArcade
> make all
> make install # deploys binaries, scripts, plugins, etc...
8. reboot (for path to take effect)
9. run ~/marquees/bin/analyze_games (not sudo!)
10. clone, build, install ultrastikcmd tool for per-game joystick mapping:
> cd ~/IvarArcade/tools/linux
> git clone https://github.com/dcaputi1/UltrastikCmd.git
> cd ~/IvarArcade/tools/linux/UltrastikCmd
> cd libusb-1.0.19 && ./configure --prefix=/usr/local && make && sudo make install && cd ..
> cd libusb-compat-0.1.5 && ./configure --prefix=/usr/local && make && sudo make install && cd ..
> cd libhid-0.2.16 && ./configure --prefix=/usr/local && make && sudo make install && cd ..
> cd ultrastikcmd-0.2 && ./configure --prefix=/usr/local && make && sudo make install && cd ..
> sudo ldconfig
   (verify: sudo ldconfig -v | grep libhid - should show libhid.so.0 -> libhid.so.0.0.0)

optional:
A. sudo apt install meld
B. sudo apt install joystick
C. sudo apt install jstest-gtk
D. sudo apt install code
required:
E. sudo apt install fuse-zip (mounts zip file w/ PNGs)
   sudo nano /etc/fuse.conf and uncomment #user_allow_other
