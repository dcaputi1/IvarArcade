"""Headless tests of the frontend's controller/panel selection and persistence."""

import ast
import os
from pathlib import Path
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
    }
    tree.body = [
        node for node in tree.body
        if (isinstance(node, ast.FunctionDef) and node.name in names)
        or (isinstance(node, ast.Assign)
            and any(isinstance(target, ast.Name) and target.id in names for target in node.targets))
    ]
    namespace = {
        "os": os, "panel": "DC", "ctrlr_cfg": "dcpanel1.cfg",
        "PANEL_FILE": "panel", "CTRLR_FILE": "ctrlr",
        "save_state": Mock(), "_choice_menu": Mock(),
    }
    exec(compile(tree, str(SOURCE), "exec"), namespace)
    return namespace


class ProfileSelectionTests(unittest.TestCase):
    def setUp(self):
        self.logic = load_selection_logic()

    def test_exact_five_choices_and_selection_effects(self):
        labels = [
            "All Controllers (allctrlrs.cfg)",
            "Atari Fightstick/Trackball (atarifs.cfg)",
            "Dual Spinners/UltraStick (dcpanel1.cfg)",
            "Mario Kart/Wheel (mkwheel.cfg)",
            "Atari iCode USB/Console 8-bit (atarifs)",
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


if __name__ == "__main__":
    unittest.main()
