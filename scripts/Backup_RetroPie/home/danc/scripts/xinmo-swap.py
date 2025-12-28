#!/usr/bin/env python3
import os
import sys
import glob
import xml.etree.ElementTree as ET

def check_default_cfg(cfg_path):
    """
    Check if default.cfg has JOYCODE_5_* for P2_BUTTON1.
    Returns True if config is in normal order (P2_BUTTON1 is JOYCODE_5_*), False if swapped.
    """
    try:
        tree = ET.parse(cfg_path)
        root = tree.getroot()

        # Look for P2_BUTTON1 port
        for port in root.findall(".//port[@type='P2_BUTTON1']"):
            for newseq in port.findall("newseq[@type='standard']"):
                if "JOYCODE_5_" in (newseq.text or ""):
                    return True  # Normal order
        return False  # Swapped order
    except ET.ParseError as e:
        print(f"ERROR: Failed to parse {cfg_path}: {e}")
        return False
    except FileNotFoundError:
        print(f"ERROR: {cfg_path} not found.")
        return False


def swap_joysticks_in_file(file_path):
    """
    Swap all JOYCODE_4_* with JOYCODE_5_* in a single file safely,
    returning the number of swaps made.
    """
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            content = f.read()

        # Count how many total JOYCODE_4_ and JOYCODE_5_ occurrences exist
        count_4 = content.count("JOYCODE_4_")
        count_5 = content.count("JOYCODE_5_")
        total_swaps = count_4 + count_5

        if total_swaps == 0:
            print(f"Swapped 0 joystick codes in: {file_path}")
            return 0

        # Use a temporary placeholder to avoid conflict during replacement
        content = content.replace("JOYCODE_4_", "TEMPJOY4_")
        content = content.replace("JOYCODE_5_", "JOYCODE_4_")
        content = content.replace("TEMPJOY4_", "JOYCODE_5_")

        with open(file_path, "w", encoding="utf-8") as f:
            f.write(content)

        print(f"Swapped {total_swaps} joystick codes in: {file_path}")
        return total_swaps

    except Exception as e:
        print(f"ERROR processing {file_path}: {e}")
        return 0


def process_directory(directory):
    """
    Swap joysticks for all *.cfg files in the given directory.
    Returns the total count of swaps made across all files.
    """
    cfg_files = glob.glob(os.path.join(directory, "*.cfg"))
    if not cfg_files:
        print("No .cfg files found in directory.")
        return 0

    total_swaps = 0
    for cfg_file in cfg_files:
        total_swaps += swap_joysticks_in_file(cfg_file)

    return total_swaps


def main():
    if len(sys.argv) != 3:
        print("Usage: swap_joysticks.py <cfg_directory> <swapped_flag>")
        print("  <cfg_directory> - Path to directory containing cfg files (including default.cfg)")
        print("  <swapped_flag>  - '0' if joysticks are normal, '1' if js4 and js5 are swapped")
        sys.exit(1)

    cfg_directory = sys.argv[1]
    swapped_flag = sys.argv[2]

    default_cfg_path = os.path.join(cfg_directory, "default.cfg")

    print(f"Checking default.cfg at: {default_cfg_path}")
    default_is_normal = check_default_cfg(default_cfg_path)

    print(f"Default.cfg joystick order is {'normal' if default_is_normal else 'swapped'}")
    print(f"Detected swapped_flag = {swapped_flag}")

    # Convert swapped_flag to boolean for clarity
    hardware_swapped = (swapped_flag == "1")

    # Determine if a swap is needed:
    # Swap if hardware swapped XOR config swapped
    config_swapped = not default_is_normal
    need_swap = hardware_swapped ^ config_swapped  # XOR logic

    if not need_swap:
        print("No swap needed. Configuration matches hardware state.")
        sys.exit(0)

    print("Performing joystick swap on all .cfg files...")
    total_swaps = process_directory(cfg_directory)

    print(f"\nTotal joystick codes swapped across all files: {total_swaps}")


if __name__ == "__main__":
    main()
