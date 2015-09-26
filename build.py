#!/usr/bin/env python3

import subprocess
import os
import sys

def build_dependencies_and_install():
    git_result = subprocess.call(["git", "submodule",
                                  "update", "--recursive"])
    mv_result = subprocess.call(["mv", "brotli", "libbrotli"])
    os.chdir("libbrotli")
    for command in ["libtoolize", "aclocal", "autoheader", "autoconf",
                    "automake", "./configure", "make"]:
        if command == "libtoolize" and sys.platform == "darwin":
            libtool_result = subprocess.call(["glibtoolize"])
        else:
            if command == "automake":
                process_result = subprocess.call([command,
                                                  "--add-missing"])
            if command == "make":
                process_result = subprocess.call([command, "install"])
            else:
                process_result = subprocess.call([command])

build_dependencies_and_install()
