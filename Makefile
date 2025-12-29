# IvarArcade Parent Makefile
# Builds both dmarquees and analyze_games executables

.PHONY: all dmarquees analyze_games install clean help

# Install directory
INSTALL_DIR ?= $(HOME)/marquees

all: dmarquees analyze_games

# Build dmarquees
dmarquees:
	@echo "Building dmarquees..."
	@$(MAKE) -C dmarquees

# Build analyze_games
analyze_games:
	@echo "Building analyze_games..."
	@$(MAKE) -C analyze_games

# Install both executables and resources
install: all
	@echo "Installing IvarArcade components..."
	@mkdir -p $(INSTALL_DIR)/bin
	
	# Install executables
	@echo "Installing executables to $(INSTALL_DIR)/bin..."
	@cp -p dmarquees/dmarquees $(INSTALL_DIR)/bin/
	@cp -p analyze_games/analyze_games $(INSTALL_DIR)/bin/
	@echo "Installed: $(INSTALL_DIR)/bin/dmarquees"
	@echo "Installed: $(INSTALL_DIR)/bin/analyze_games"
	
	# Install runtime resources (images directory)
	@if [ -d images ]; then \
		echo "Copying images/ to $(INSTALL_DIR)/images..."; \
		cp -a images $(INSTALL_DIR)/; \
		echo "Installed: $(INSTALL_DIR)/images"; \
	fi
	
	# Install plugins to local directory
	@if [ -d plugins ]; then \
		echo "Copying plugins/ to $(INSTALL_DIR)/plugins..."; \
		cp -a plugins $(INSTALL_DIR)/; \
		echo "Installed: $(INSTALL_DIR)/plugins"; \
	fi
	
	# Install plugins to MAME (only if newer)
	@if [ -f plugins/leds/init.lua ]; then \
		echo "Copying leds plugin to /opt/retropie/emulators/mame/plugins/leds/..."; \
		mkdir -p /opt/retropie/emulators/mame/plugins/leds; \
		cp -u plugins/leds/init.lua /opt/retropie/emulators/mame/plugins/leds/; \
		cp -u plugins/leds/plugin.json /opt/retropie/emulators/mame/plugins/leds/; \
		echo "Installed: /opt/retropie/emulators/mame/plugins/leds/"; \
	fi
	
	@if [ -f plugins/marquee/init.lua ]; then \
		echo "Copying marquee plugin to /opt/retropie/emulators/mame/plugins/marquee/..."; \
		mkdir -p /opt/retropie/emulators/mame/plugins/marquee; \
		cp -u plugins/marquee/init.lua /opt/retropie/emulators/mame/plugins/marquee/; \
		cp -u plugins/marquee/plugin.json /opt/retropie/emulators/mame/plugins/marquee/; \
		echo "Installed: /opt/retropie/emulators/mame/plugins/marquee/"; \
	fi
	
	# Install scripts
	@if [ -f scripts/Backup_RetroPie/home/danc/scripts/swap_banner_art.sh ]; then \
		echo "Copying swap_banner_art.sh to /home/danc/scripts/..."; \
		mkdir -p /home/danc/scripts; \
		cp -u scripts/Backup_RetroPie/home/danc/scripts/swap_banner_art.sh /home/danc/scripts/; \
		echo "Installed: /home/danc/scripts/swap_banner_art.sh"; \
	fi
	
	@if [ -f scripts/Backup_RetroPie/opt/retropie/configs/all/autostart.sh ]; then \
		if [ ! -f /opt/retropie/configs/all/autostart.sh ] || [ scripts/Backup_RetroPie/opt/retropie/configs/all/autostart.sh -nt /opt/retropie/configs/all/autostart.sh ]; then \
			echo "Copying autostart.sh to /opt/retropie/configs/all/..."; \
			cp -u scripts/Backup_RetroPie/opt/retropie/configs/all/autostart.sh /opt/retropie/configs/all/; \
			echo "Installed: /opt/retropie/configs/all/autostart.sh"; \
		fi; \
	fi
	
	@echo "Installation complete!"

# Clean all build artifacts
clean:
	@echo "Cleaning all build artifacts..."
	@$(MAKE) -C dmarquees clean
	@$(MAKE) -C analyze_games clean
	@rm -f build.log
	@echo "Clean complete."

# Uninstall
uninstall:
	@echo "Removing installed files..."
	@rm -f $(INSTALL_DIR)/bin/dmarquees
	@rm -f $(INSTALL_DIR)/bin/analyze_games
	@rm -rf $(INSTALL_DIR)/images
	@rm -rf $(INSTALL_DIR)/plugins
	@rmdir --ignore-fail-on-non-empty $(INSTALL_DIR)/bin || true
	@rmdir --ignore-fail-on-non-empty $(INSTALL_DIR) || true
	@echo "Uninstall complete."

# Help
help:
	@echo "IvarArcade Build System"
	@echo ""
	@echo "Available targets:"
	@echo "  all           - Build both dmarquees and analyze_games (default)"
	@echo "  dmarquees     - Build only dmarquees executable"
	@echo "  analyze_games - Build only analyze_games executable"
	@echo "  install       - Build and install all components to $(INSTALL_DIR)"
	@echo "  clean         - Remove all build artifacts"
	@echo "  uninstall     - Remove installed files"
	@echo "  help          - Show this help message"
	@echo ""
	@echo "Variables:"
	@echo "  INSTALL_DIR   - Installation directory (default: $(HOME)/marquees)"
	@echo ""
	@echo "Examples:"
	@echo "  make"
	@echo "  make install"
	@echo "  make install INSTALL_DIR=/usr/local/ivararcade"
	@echo "  make clean"
