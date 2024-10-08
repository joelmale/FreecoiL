#!/usr/bin/env python3
import getpass
import os
import pathlib
import subprocess
import sys

cwd = pathlib.Path.cwd()

if getpass.getuser() == "wolfrage":
    app_path = pathlib.Path("~/Apps/Godot/Godot_v3.2.2-beta3_x11.64").expanduser()
    proj_path = cwd.joinpath("..")
else:
    app_path = cwd.joinpath("godot_editor/Godot_v3.2.2-beta3_x11.64")
    proj_path = cwd.joinpath("godot")

returncode = subprocess.call([app_path, "-s", "--path", proj_path, "tests/gut_runner_custom.gd"])
if returncode == 0:
    print("Returning 0 exit code from Python. Success!")
    sys.exit(0)
else:
    print("Returning 1 exit code from Python. Failure!")
    sys.exit(1)