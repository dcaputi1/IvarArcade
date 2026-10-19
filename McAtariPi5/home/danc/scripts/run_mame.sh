#!/bin/bash

# --- CONFIG PATHS ---
MAME_ROOT="/opt/retropie/emulators/mame"
CFG_DIR="$MAME_ROOT/cfg"
CTRLR_FILE="$HOME/.ctrlr"
PANEL_FILE="$HOME/.panel"
CTRLR_CFG_DEFAULT="allctrlrs.cfg"
ROM_CTRLR_MAP="/opt/retropie/configs/all/mame_ctrlr_map.txt"

PREPARE_ONLY=false
if [[ "${1:-}" == "--prepare" ]]; then
    PREPARE_ONLY=true
    shift
fi

resolve_ctrlr_name()
{
    local cfg_name="$1"
    cfg_name="${cfg_name##*/}"
    cfg_name="${cfg_name%.cfg}"
    echo "$cfg_name"
}

lookup_game_ctrlr()
{
    local rom_name="$1"
    local line key value

    [[ -e "$ROM_CTRLR_MAP" ]] || return 0
    [[ -r "$ROM_CTRLR_MAP" ]] || {
        echo "Cannot read per-game controller map: $ROM_CTRLR_MAP" >&2
        return 1
    }

    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line%%#*}"
        [[ "$line" == *"="* ]] || continue

        key="${line%%=*}"
        value="${line#*=}"
        key="${key#"${key%%[![:space:]]*}"}"
        key="${key%"${key##*[![:space:]]}"}"
        value="${value#"${value%%[![:space:]]*}"}"
        value="${value%"${value##*[![:space:]]}"}"

        if [[ "${key,,}" == "${rom_name,,}" && -n "$value" ]]; then
            printf '%s\n' "$value"
            return 0
        fi
    done < "$ROM_CTRLR_MAP"
}

persist_game_profile()
{
    local ctrlr_cfg="$1"
    local ctrlr_name panel_code

    ctrlr_name=$(resolve_ctrlr_name "$ctrlr_cfg")
    case "$ctrlr_name" in
        dcpanel1) panel_code="DC" ;;
        atarifs) panel_code="MC" ;;
        *) panel_code="" ;;
    esac

    if ! printf '%s\n' "$ctrlr_cfg" > "$CTRLR_FILE"; then
        echo "Cannot save controller profile to $CTRLR_FILE" >&2
        return 1
    fi

    if [[ -n "$panel_code" ]] && ! printf '%s\n' "$panel_code" > "$PANEL_FILE"; then
        echo "Cannot save panel mode '$panel_code' to $PANEL_FILE" >&2
        return 1
    fi
}

# --- LOAD ROL (screen rotation) FLAG ---
source ~/.rol_flag 2>/dev/null

# --- CONDITIONAL INI PATH ---
INI_PATH="$MAME_ROOT/ini"

if [ "$ROL_FLAG" = "-rol" ]; then
    INI_PATH="$INI_PATH;$MAME_ROOT/ini_horz_ror"
fi

if [ -f "$CTRLR_FILE" ]; then
    CTRLR_CFG=$(<"$CTRLR_FILE")
else
    CTRLR_CFG="$CTRLR_CFG_DEFAULT"
    echo "$CTRLR_CFG" > "$CTRLR_FILE"
fi

if [[ -n "${1:-}" ]]; then
    ROM_NAME="${1##*/}"
    ROM_NAME="${ROM_NAME%.*}"
    if GAME_CTRLR_CFG=$(lookup_game_ctrlr "$ROM_NAME"); then
        if [[ -n "$GAME_CTRLR_CFG" ]]; then
            CTRLR_CFG="$GAME_CTRLR_CFG"
            if ! persist_game_profile "$CTRLR_CFG"; then
                exit 1
            fi
            echo "Using per-game controller config for $ROM_NAME: $CTRLR_CFG" >&2
        fi
    else
        exit 1
    fi
fi

CTRLR_NAME=$(resolve_ctrlr_name "$CTRLR_CFG")

if [[ "$PREPARE_ONLY" == true ]]; then
    exit 0
fi

# --- RUN MAME ---
IVAR_RUN_MAME_WRAPPER=1 "$MAME_ROOT/mame" \
    -joystickprovider sdljoy \
    -inipath "$INI_PATH" \
    -cfg_directory "$CFG_DIR" \
    -ctrlr "$CTRLR_NAME" \
    $ROL_FLAG \
    -verbose \
    "$@" > "$HOME/mame.log" 2>&1
