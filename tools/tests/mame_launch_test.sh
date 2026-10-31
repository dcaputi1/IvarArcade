#!/bin/bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/../.." && pwd)
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
export HOME="$WORK/home"
export CAPTURE="$WORK/mame-launch"
mkdir -p "$HOME/scripts" "$WORK/mame"

# Only the fake MAME binary runs; no display, daemon, or user settings are touched.
cat > "$WORK/mame/mame" <<'STUB'
#!/bin/bash
printf '%s\n' "${MAME_PANEL_OUTPUT:-unset}" "$@" > "$CAPTURE"
STUB
chmod +x "$WORK/mame/mame"
sed -e "s|^MAME_ROOT=.*|MAME_ROOT=\"$WORK/mame\"|" \
    -e "s|^ROM_CTRLR_MAP=.*|ROM_CTRLR_MAP=\"$WORK/ctrlr_map\"|" \
    "$ROOT/McAtariPi5/home/danc/scripts/run_mame.sh" > "$HOME/scripts/run_mame.sh"
chmod +x "$HOME/scripts/run_mame.sh"
printf 'dcpanel1.cfg\n' > "$HOME/.ctrlr"
printf 'DC\n' > "$HOME/.panel"
printf 'ROL_FLAG="-norol"\n' > "$HOME/.rol_flag"
printf 'spyhunt=mkwheel\n-rol=atarifs\n-norol=atarifs\n' > "$WORK/ctrlr_map"

passed=0
check_line()
{
    if ! grep -Fxq -- "$1" "$CAPTURE"; then
        echo "FAIL: missing '$1' in MAME launch" >&2
        cat "$CAPTURE" >&2
        exit 1
    fi
    passed=$((passed + 1))
}

check_option()
{
    local actual
    actual=$(awk -v option="$1" '$0 == option { getline; value=$0 } END { print value }' "$CAPTURE")
    [[ "$actual" == "$2" ]] || {
        echo "FAIL: effective $1 should be '$2', got '$actual'" >&2
        exit 1
    }
    passed=$((passed + 1))
}

check_mode()
{
    local expected="$1"
    [[ $(head -n 1 "$CAPTURE") == "$expected" ]] || {
        echo "FAIL: panel output should be $expected" >&2
        cat "$CAPTURE" >&2
        exit 1
    }
    if [[ "$expected" == 1 ]]; then
        check_option -numscreens 2
        check_option -screen0 screen0
        check_option -screen1 screen1
    elif grep -Fxq -- -numscreens "$CAPTURE"; then
        echo "FAIL: disabled panel mode must not force a second output" >&2
        exit 1
    fi
    passed=$((passed + 1))
}

run_gui()
{
    local script="$1"
    local horizontal="$2"
    # Load definitions only, never the boot-time daemon/desktop orchestration.
    source <(sed '/^# AUTOSTART.SH MAIN PROCESS/,$d' "$script")
    BASE_PATH="$WORK/mame"
    CFG_PATH="$BASE_PATH/cfg"
    SCREEN_HORIZONTAL="$horizontal"
    CTRLR_CFG="dcpanel1.cfg"
    send_dmarquees_cmd() { :; }
    debug_wait() { :; }
    persist_frontend_choice() { :; }
    # Execute the real M case without entering either interactive menu.
    source <(sed -n '/^            M)/,/^                ;;/p' "$script" |
        sed '1d;$d;/^                continue$/d')
}

for pi3 in true false; do
    for dual in true false; do
        printf '%s\n' "$pi3" > "$HOME/.pi3_present"
        printf '%s\n' "$dual" > "$HOME/.pi5_dual_display"
        expected=0
        if [[ "$pi3" == true && "$dual" == true ]]; then expected=1; fi

        # A stale inherited value must not override either enabled or disabled mode.
        export MAME_PANEL_OUTPUT=$((1 - expected))
        for menu in autostart.sh autostart-nogui.sh; do
            for horizontal in true false; do
                run_gui "$ROOT/McAtariPi5/opt/retropie/configs/all/$menu" "$horizontal"
                check_mode "$expected"
                check_option -ctrlr dcpanel1
                check_option -joystickprovider sdljoy
                check_option -cfg_directory "$WORK/mame/cfg"
                if [[ "$horizontal" == true ]]; then
                    rotation=-norol
                    check_option -inipath "$WORK/mame/ini"
                else
                    rotation=-rol
                    check_option -inipath "$WORK/mame/ini;$WORK/mame/ini_horz_ror"
                fi
                [[ $(grep -Ex -- '-(no)?rol' "$CAPTURE" | tail -n 1) == "$rotation" ]] || {
                    echo "FAIL: GUI rotation must override a stale ES rotation flag" >&2
                    exit 1
                }
                [[ $(cat "$HOME/.panel") == DC && $(cat "$HOME/.ctrlr") == dcpanel1.cfg ]] || {
                    echo "FAIL: GUI flags must not trigger per-ROM profile lookup" >&2
                    exit 1
                }
            done
        done

        for rom in spyhunt asteroid indytemp defender; do
            "$HOME/scripts/run_mame.sh" "$rom"
            check_mode "$expected"
            check_line "$rom"
            check_option -ctrlr mkwheel
            [[ $(cat "$HOME/.panel") == MK ]] || {
                echo "FAIL: ES per-ROM profile selection must remain enabled" >&2
                exit 1
            }
        done
        printf 'dcpanel1.cfg\n' > "$HOME/.ctrlr"
        printf 'DC\n' > "$HOME/.panel"
    done
done

printf 'mame_launch: %d checks passed\n' "$passed"
