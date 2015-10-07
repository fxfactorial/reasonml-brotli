#!/usr/bin/env python

import subprocess
import os
import sys

def build_dependencies_and_install():
    libbrotli_result = subprocess.call(["git", "clone",
                                        "https://github.com/bagder/libbrotli"])
    os.chdir("libbrotli")
    subprocess.call(["bash", "autogen.sh"])
    subprocess.call(["bash", "configure"])
    subprocess.call(["make"])

def clean_up():
    rm_result = subprocess.call(["rm", "-rf", "libbrotli"])

if __name__ == "__main__":
    if sys.argv[1] == "--prepare":
        build_dependencies_and_install()
    elif sys.argv[1] == "--cleanup":
        clean_up()
