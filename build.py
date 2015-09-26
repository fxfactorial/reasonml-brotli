#!/usr/bin/env python3

import subprocess
import os
import sys

def build_dependencies_and_install():
    brotli_result = subprocess.call(["git", "clone",
                                     "https://github.com/google/brotli/"])
    libbrotli_result = subprocess.call(["git", "clone",
                                        "https://github.com/bagder/libbrotli"])
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

def clean_up():
    rm_result = subprocess.call(["rm", "-rf", "libbrotli"])

if __name__ == "__main__":
    if sys.argv[1] == "--prepare":
        build_dependencies_and_install()
    elif sys.argv[1] == "--cleanup":
        clean_up()
