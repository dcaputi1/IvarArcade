"""Headless tests of the frontend's controller/panel selection and persistence."""

import ast
import os
from pathlib import Path
import sys
import unittest
from unittest.mock import Mock, patch


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "McAtariPi5" / "home" / "danc" / "scripts" / "pic_frontend.py"


def load_selection_logic():
    # Importing the complete frontend initializes SDL and writes real user state.
    tree = ast.parse(SOURCE.read_text(encoding="utf-8"))
    names = {
        "CTRLR_PROFILES", "PANEL_TO_CTRLR", "DEFAULT_CTRLR_CFG", "panel_menu",
        "_resolve_panel_ctrlr_mismatch", "ctrlr_menu", "select_ctrlr_cfg_menu",
        "_sync_menu_marquee", "toggle_dual_display", "toggle_pi3_present", "main_menu",
    }
    tree.body = [
        node for node in tree.body
        if (isinstance(node, ast.FunctionDef) and node.name in names)
        or (isinstance(node, ast.Assign)
            and any(isinstance(target, ast.Name) and target.id in names for target in node.targets))
    ]
    namespace = {
        "os": os, "sys": sys, "panel": "DC", "ctrlr_cfg": "dcpanel1.cfg",
        "PANEL_FILE": "panel", "CTRLR_FILE": "ctrlr",
        "PI5_DUAL_DISPLAY_FILE": "dual", "PI3_PRESENT_FILE": "pi3",
        "DMARQUEES_FIFO": "/tmp/dmarquees_cmd",
        "dual_display": True, "pi3_present": True,
        "_menu_daemon_available": True,
        "save_state": Mock(), "_choice_menu": Mock(),
    }
    exec(compile(tree, str(SOURCE), "exec"), namespace)
    return namespace


class ProfileSelectionTests(unittest.TestCase):
    def setUp(self):
        self.logic = load_selection_logic()
        self.logic["_sync_menu_marquee"] = Mock()

    def test_exact_five_choices_and_selection_effects(self):
        labels = [
            "All Controllers (allctrlrs.cfg)",
            "Atari Fightstick / Trackball (atarifs.cfg)",
            "Dual Spinners / UltraStick (dcpanel1.cfg)",
            "MarioKart / Wheel (mkwheel.cfg)",
            "Atari iCode / 8-bit (atarifs.cfg)",
        ]
        files = ["allctrlrs.cfg", "atarifs.cfg", "dcpanel1.cfg", "mkwheel.cfg", "atarifs.cfg"]
        panels = ["DC", "MC", "DC", "MK", "AC"]
        for index in range(5):
            with self.subTest(index=index):
                self.setUp()
                self.logic["_choice_menu"].return_value = index
                with patch.object(os, "listdir", side_effect=AssertionError("must not scan ctrlr folder")):
                    self.logic["ctrlr_menu"]()
                self.assertEqual(self.logic["_choice_menu"].call_args.args[1], labels)
                self.assertEqual(self.logic["ctrlr_cfg"], files[index])
                self.assertEqual(self.logic["panel"], panels[index])
                self.logic["save_state"].assert_any_call("ctrlr", files[index])
                if index:
                    self.logic["save_state"].assert_any_call("panel", panels[index])
                else:
                    self.logic["save_state"].assert_called_once()
                self.logic["_sync_menu_marquee"].assert_called_once()

    def test_duplicate_atari_file_uses_panel_to_highlight(self):
        self.logic.update(ctrlr_cfg="/profiles/ATARIFS.cfg", panel="AC")
        self.logic["_choice_menu"].return_value = None
        self.logic["ctrlr_menu"]()
        self.assertEqual(self.logic["_choice_menu"].call_args.args[2], 4)
        self.logic["save_state"].assert_not_called()

    def test_panel_mismatch_explicit_all_ignore_and_cancel(self):
        for choice, expected in [(0, "atarifs.cfg"), (1, "allctrlrs.cfg"),
                                 (2, "dcpanel1.cfg"), (None, "dcpanel1.cfg")]:
            with self.subTest(choice=choice):
                self.setUp()
                self.logic["_choice_menu"].side_effect = [4, choice]
                self.logic["panel_menu"]()
                self.assertEqual(self.logic["panel"], "AC")
                self.assertEqual(self.logic["ctrlr_cfg"], expected)
                self.assertEqual(len(self.logic["_choice_menu"].call_args.args[1]), 3)
                self.logic["_sync_menu_marquee"].assert_called_once()

    def test_matching_profile_or_blank_panel_does_not_prompt(self):
        for panel_index in (0, 4):
            with self.subTest(panel_index=panel_index):
                self.setUp()
                self.logic["ctrlr_cfg"] = "/profiles/ATARIFS.cfg"
                self.logic["_choice_menu"].return_value = panel_index
                self.logic["panel_menu"]()
                self.logic["_choice_menu"].assert_called_once()

    def test_merge_choices_are_unique_allowlisted_files(self):
        self.logic["_choice_menu"].return_value = 1
        selected = self.logic["select_ctrlr_cfg_menu"]("Merge", "atarifs.cfg")
        self.assertEqual(selected, "atarifs.cfg")
        self.assertEqual(self.logic["_choice_menu"].call_args.args[1], [
            "allctrlrs.cfg", "atarifs.cfg", "dcpanel1.cfg", "mkwheel.cfg",
        ])


class MenuMarqueeTests(unittest.TestCase):
    def setUp(self):
        self.logic = load_selection_logic()

    def assert_command(self, command):
        with patch.object(os, "open", return_value=42) as open_fifo, \
             patch.object(os, "write", return_value=len(command)) as write_fifo, \
             patch.object(os, "close") as close_fifo:
            self.logic["_sync_menu_marquee"]()
        open_fifo.assert_called_once_with("/tmp/dmarquees_cmd", os.O_WRONLY | os.O_NONBLOCK)
        write_fifo.assert_called_once_with(42, command)
        close_fifo.assert_called_once_with(42)

    def test_sync_sends_menu_mode_only_to_local_daemon(self):
        self.assert_command(b"NA\n")

    def test_no_local_daemon_at_startup_does_not_send(self):
        self.logic["_menu_daemon_available"] = False
        with patch.object(os, "open") as open_fifo:
            self.logic["_sync_menu_marquee"]()
        open_fifo.assert_not_called()

    def test_fifo_failure_is_reported_without_blocking_menu(self):
        with patch.object(os, "open", side_effect=OSError("no reader")), \
             patch("sys.stderr") as stderr:
            self.logic["_sync_menu_marquee"]()
        self.assertIn("no reader", "".join(call.args[0] for call in stderr.write.call_args_list))

    def test_short_write_is_reported_and_fd_closed(self):
        with patch.object(os, "open", return_value=42), \
             patch.object(os, "write", return_value=1), \
             patch.object(os, "close") as close_fifo, patch("sys.stderr") as stderr:
            self.logic["_sync_menu_marquee"]()
        close_fifo.assert_called_once_with(42)
        self.assertIn("incomplete", "".join(call.args[0] for call in stderr.write.call_args_list))

    def test_menu_syncs_on_entry_and_display_toggles(self):
        sync = Mock(side_effect=RuntimeError("entered"))
        self.logic["_sync_menu_marquee"] = sync
        with self.assertRaisesRegex(RuntimeError, "entered"):
            self.logic["main_menu"]()
        sync.assert_called_once()

        sync.side_effect = None
        for name in ("toggle_dual_display", "toggle_pi3_present"):
            with self.subTest(name=name):
                sync.reset_mock()
                self.logic[name]()
                sync.assert_called_once()


if __name__ == "__main__":
    unittest.main()
