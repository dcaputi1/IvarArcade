# Makefile Configuration Installation Reference
# This file shows the Makefile additions needed for the cleanup pass
# Integrate these into the main Makefile after reviewing

# ============================================================================
# CONFIGURATION FILE INSTALLATION LISTS (Add to top of Makefile)
# ============================================================================

# Scripts to install from scripts/ directory
SCRIPTS_TO_INSTALL = \
	leds_off.py \
	set_leds.py \
	swap_banner_art.sh \
	xinmo-swap.py \
	xinmo-swapcheck.py \
	mnt-marquees.sh \
	unmnt-marquees.sh \
	run_mame.sh

# RetroEmulationStation global configs
RETROPIE_CONFIGS = \
	autostart.sh \
	emulators.cfg \
	retroarch.cfg \
	retroarch-core-options.cfg \
	runcommand-onlaunch.sh \
	runcommand-onend.sh

# MAME device mapping configuration
MAME_CTRLR_CONFIGS = \
	allctrlrs.cfg

# MAME game category lists
MAME_CATEGORY_FILES = \
	Atari_FS.ini \
	B_list.ini \
	favorite_DC.ini \
	FGT_wheel.ini \
	Panel1.ini

# MAME display rotation config
MAME_DISPLAY_CONFIGS = \
	horizont.ini

# Custom MAME INI overrides (adjust based on what you keep)
MAME_INI_CONFIGS = \
	mame.ini \
	ui.ini

# ============================================================================
# INSTALLATION TARGETS (Add to Makefile before/after existing 'install' target)
# ============================================================================

.PHONY: install install-scripts install-retropie-configs install-mame-configs install-mame-categories install-mame-display install-mame-ini

# Main install target - updated to include configuration installation
install: all install-scripts install-retropie-configs install-mame-configs install-plugins
	@echo "Installation complete!"

# ============================================================================
# SCRIPT INSTALLATION TARGET
# ============================================================================

install-scripts:
	@echo "Installing custom scripts..."
	@mkdir -p /home/danc/scripts
	@for script in $(SCRIPTS_TO_INSTALL); do \
		src="scripts/$$script"; \
		dest="/home/danc/scripts/$$script"; \
		if [ -f "$$src" ]; then \
			if [ ! -f "$$dest" ] || [ "$$src" -nt "$$dest" ]; then \
				cp -p "$$src" "$$dest" && chmod +x "$$dest" && echo "Updated: $$dest"; \
			else \
				echo "Skipped: $$dest (up to date)"; \
			fi; \
		else \
			echo "Warning: Source $$src not found"; \
		fi; \
	done

# ============================================================================
# RETROPIE CONFIGURATION INSTALLATION
# ============================================================================

install-retropie-configs:
	@echo "Installing RetroEmulationStation global configurations..."
	@mkdir -p /opt/retropie/configs/all/emulationstation
	
	@# Install main config files
	@for config in $(RETROPIE_CONFIGS); do \
		src="config/retropie/all/$$config"; \
		dest="/opt/retropie/configs/all/$$config"; \
		if [ -f "$$src" ]; then \
			if [ ! -f "$$dest" ] || [ "$$src" -nt "$$dest" ]; then \
				cp -p "$$src" "$$dest" && echo "Updated: $$dest"; \
			else \
				echo "Skipped: $$dest (up to date)"; \
			fi; \
		else \
			echo "Warning: Source $$src not found"; \
		fi; \
	done
	
	@# Install emulationstation input config
	@src="config/retropie/all/emulationstation/es_input.cfg"; \
	dest="/opt/retropie/configs/all/emulationstation/es_input.cfg"; \
	if [ -f "$$src" ]; then \
		if [ ! -f "$$dest" ] || [ "$$src" -nt "$$dest" ]; then \
			cp -p "$$src" "$$dest" && echo "Updated: $$dest"; \
		else \
			echo "Skipped: $$dest (up to date)"; \
		fi; \
	else \
		echo "Warning: Source $$src not found"; \
	fi

# ============================================================================
# MAME CONFIGURATION INSTALLATION
# ============================================================================

install-mame-configs: install-mame-ctrlr install-mame-categories install-mame-display install-mame-ini

# MAME device controller mapping
install-mame-ctrlr:
	@echo "Installing MAME device controller mapping..."
	@mkdir -p /opt/retropie/emulators/mame/ctrlr
	@for config in $(MAME_CTRLR_CONFIGS); do \
		src="config/mame/ctrlr/$$config"; \
		dest="/opt/retropie/emulators/mame/ctrlr/$$config"; \
		if [ -f "$$src" ]; then \
			if [ ! -f "$$dest" ] || [ "$$src" -nt "$$dest" ]; then \
				cp -p "$$src" "$$dest" && echo "Updated: $$dest"; \
			else \
				echo "Skipped: $$dest (up to date)"; \
			fi; \
		else \
			echo "Warning: Source $$src not found"; \
		fi; \
	done

# MAME game category lists
install-mame-categories:
	@echo "Installing MAME game categories..."
	@mkdir -p /opt/retropie/emulators/mame/categories
	@for category in $(MAME_CATEGORY_FILES); do \
		src="config/mame/categories/$$category"; \
		dest="/opt/retropie/emulators/mame/categories/$$category"; \
		if [ -f "$$src" ]; then \
			if [ ! -f "$$dest" ] || [ "$$src" -nt "$$dest" ]; then \
				cp -p "$$src" "$$dest" && echo "Updated: $$dest"; \
			else \
				echo "Skipped: $$dest (up to date)"; \
			fi; \
		else \
			echo "Warning: Source $$src not found"; \
		fi; \
	done

# MAME display rotation configuration
install-mame-display:
	@echo "Installing MAME display rotation configuration..."
	@mkdir -p /opt/retropie/emulators/mame/ini_horz_ror
	@for display in $(MAME_DISPLAY_CONFIGS); do \
		src="config/mame/ini_horz_ror/$$display"; \
		dest="/opt/retropie/emulators/mame/ini_horz_ror/$$display"; \
		if [ -f "$$src" ]; then \
			if [ ! -f "$$dest" ] || [ "$$src" -nt "$$dest" ]; then \
				cp -p "$$src" "$$dest" && echo "Updated: $$dest"; \
			else \
				echo "Skipped: $$dest (up to date)"; \
			fi; \
		else \
			echo "Warning: Source $$src not found"; \
		fi; \
	done

# MAME custom INI file overrides
install-mame-ini:
	@echo "Installing MAME custom INI configuration overrides..."
	@mkdir -p /opt/retropie/emulators/mame/ini
	@for ini in $(MAME_INI_CONFIGS); do \
		src="config/mame/ini/$$ini"; \
		dest="/opt/retropie/emulators/mame/ini/$$ini"; \
		if [ -f "$$src" ]; then \
			if [ ! -f "$$dest" ] || [ "$$src" -nt "$$dest" ]; then \
				cp -p "$$src" "$$dest" && chmod 666 "$$dest" && echo "Updated: $$dest"; \
			else \
				echo "Skipped: $$dest (up to date)"; \
			fi; \
		else \
			echo "Warning: Source $$src not found"; \
		fi; \
	done

# ============================================================================
# INTEGRATION NOTES
# ============================================================================

# LOCATION IN MAKEFILE:
# - Add configuration lists near the top (around line 20-30)
# - Add .PHONY declarations after existing ones
# - Add targets before the main 'install' target
# - Update main 'install' target to call new targets
# - Update 'help' target to document new targets

# TESTING:
# make clean           # Clean build artifacts
# make all             # Rebuild binaries
# make install-scripts # Test script installation
# make install         # Full installation including configs

# BACKWARDS COMPATIBILITY:
# - The existing rsync commands from cp_opt.sh can remain
# - New explicit targets supplement and document the process
# - Old Backup_RetroPie paths still work but are marked deprecated

# CONDITIONAL COMPILATION:
# Note the timestamp checking:
#   [ "$$src" -nt "$$dest" ]  = source newer than dest (copy it)
#   This preserves user modifications unless source is explicitly updated
#   Use: touch config/mame/ctrlr/allctrlrs.cfg  to force update if needed
