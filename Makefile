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

# Define installation lists
SCRIPTS_TO_INSTALL = \
	swap_banner_art.sh \
	xinmo-swap.py \
	xinmo-swapcheck.py \
	leds_off.py \
	set_leds.py

BACKUP_FILES = \
	readme.txt \
	analyze_games.sh \
	cp_opt.sh \
	cp_roms.sh \
	rm_cfg.sh

ALL_CONFIGS = \
	autostart.sh \
	emulators.cfg \
	retroarch-core-options.cfg \
	retroarch.cfg \
	runcommand-onend.sh \
	runcommand-onlaunch.sh

# Install both executables and resources
install: all
	@echo "Installing IvarArcade components..."
	@mkdir -p $(INSTALL_DIR)/bin
	
	@# Install executables
	@if [ ! -f $(INSTALL_DIR)/bin/dmarquees ] || [ dmarquees/dmarquees -nt $(INSTALL_DIR)/bin/dmarquees ]; then \
		cp -p dmarquees/dmarquees $(INSTALL_DIR)/bin/ && echo "Updated: $(INSTALL_DIR)/bin/dmarquees"; \
	else \
		echo "Skipped: $(INSTALL_DIR)/bin/dmarquees (up to date)"; \
	fi
	
	@if [ ! -f $(INSTALL_DIR)/bin/analyze_games ] || [ analyze_games/analyze_games -nt $(INSTALL_DIR)/bin/analyze_games ]; then \
		cp -p analyze_games/analyze_games $(INSTALL_DIR)/bin/ && echo "Updated: $(INSTALL_DIR)/bin/analyze_games"; \
	else \
		echo "Skipped: $(INSTALL_DIR)/bin/analyze_games (up to date)"; \
	fi
	
	@# Install runtime resources (images directory)
	@if [ -d images ]; then \
		if [ ! -d $(INSTALL_DIR)/images ]; then \
			cp -a images $(INSTALL_DIR)/ && echo "Updated: $(INSTALL_DIR)/images"; \
		else \
			echo "Skipped: $(INSTALL_DIR)/images (already exists)"; \
		fi; \
	fi
	
	@# Install plugins to local directory
	@if [ -d plugins ]; then \
		if [ ! -d $(INSTALL_DIR)/plugins ]; then \
			cp -a plugins $(INSTALL_DIR)/ && echo "Updated: $(INSTALL_DIR)/plugins"; \
		else \
			echo "Skipped: $(INSTALL_DIR)/plugins (already exists)"; \
		fi; \
	fi
	
	@# Install plugins to MAME
	@if [ -f plugins/leds/init.lua ]; then \
		mkdir -p /opt/retropie/emulators/mame/plugins/leds; \
		if [ ! -f /opt/retropie/emulators/mame/plugins/leds/init.lua ] || [ plugins/leds/init.lua -nt /opt/retropie/emulators/mame/plugins/leds/init.lua ]; then \
			cp plugins/leds/init.lua /opt/retropie/emulators/mame/plugins/leds/ && echo "Updated: /opt/retropie/emulators/mame/plugins/leds/init.lua"; \
		else \
			echo "Skipped: /opt/retropie/emulators/mame/plugins/leds/init.lua (up to date)"; \
		fi; \
		if [ ! -f /opt/retropie/emulators/mame/plugins/leds/plugin.json ] || [ plugins/leds/plugin.json -nt /opt/retropie/emulators/mame/plugins/leds/plugin.json ]; then \
			cp plugins/leds/plugin.json /opt/retropie/emulators/mame/plugins/leds/ && echo "Updated: /opt/retropie/emulators/mame/plugins/leds/plugin.json"; \
		else \
			echo "Skipped: /opt/retropie/emulators/mame/plugins/leds/plugin.json (up to date)"; \
		fi; \
	fi
	
	@if [ -f plugins/marquee/init.lua ]; then \
		mkdir -p /opt/retropie/emulators/mame/plugins/marquee; \
		if [ ! -f /opt/retropie/emulators/mame/plugins/marquee/init.lua ] || [ plugins/marquee/init.lua -nt /opt/retropie/emulators/mame/plugins/marquee/init.lua ]; then \
			cp plugins/marquee/init.lua /opt/retropie/emulators/mame/plugins/marquee/ && echo "Updated: /opt/retropie/emulators/mame/plugins/marquee/init.lua"; \
		else \
			echo "Skipped: /opt/retropie/emulators/mame/plugins/marquee/init.lua (up to date)"; \
		fi; \
		if [ ! -f /opt/retropie/emulators/mame/plugins/marquee/plugin.json ] || [ plugins/marquee/plugin.json -nt /opt/retropie/emulators/mame/plugins/marquee/plugin.json ]; then \
			cp plugins/marquee/plugin.json /opt/retropie/emulators/mame/plugins/marquee/ && echo "Updated: /opt/retropie/emulators/mame/plugins/marquee/plugin.json"; \
		else \
			echo "Skipped: /opt/retropie/emulators/mame/plugins/marquee/plugin.json (up to date)"; \
		fi; \
	fi
	
	@# Install scripts using list
	@mkdir -p /home/danc/scripts
	@for script in $(SCRIPTS_TO_INSTALL); do \
		src="Backup_RetroPie/home/danc/scripts/$$script"; \
		dest="/home/danc/scripts/$$script"; \
		if [ -f "$$src" ]; then \
			if [ ! -f "$$dest" ] || [ "$$src" -nt "$$dest" ]; then \
				cp "$$src" "$$dest" && echo "Updated: $$dest"; \
			else \
				echo "Skipped: $$dest (up to date)"; \
			fi; \
		fi; \
	done
	
	@# Install all config files using list
	@mkdir -p /opt/retropie/configs/all
	@for config in $(ALL_CONFIGS); do \
		src="Backup_RetroPie/opt/retropie/configs/all/$$config"; \
		dest="/opt/retropie/configs/all/$$config"; \
		if [ -f "$$src" ]; then \
			if [ ! -f "$$dest" ] || [ "$$src" -nt "$$dest" ]; then \
				cp "$$src" "$$dest" && echo "Updated: $$dest"; \
			else \
				echo "Skipped: $$dest (up to date)"; \
			fi; \
		fi; \
	done
	
	@# Install backup files to backup location
	@if [ -d /media/danc/ExtremeSSD/Backup_RetroPie ]; then \
		for file in $(BACKUP_FILES); do \
			src="Backup_RetroPie/$$file"; \
			dest="/media/danc/ExtremeSSD/Backup_RetroPie/$$file"; \
			if [ -f "$$src" ]; then \
				if [ ! -f "$$dest" ] || [ "$$src" -nt "$$dest" ]; then \
					cp "$$src" "$$dest" && echo "Updated: $$dest"; \
				else \
					echo "Skipped: $$dest (up to date)"; \
				fi; \
			fi; \
		done; \
	else \
		echo "Error: /media/danc/ExtremeSSD/Backup_RetroPie does not exist (SSD not mounted?)"; \
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
