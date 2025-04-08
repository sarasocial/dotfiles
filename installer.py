#!/usr/bin/env python
# install.py

import os
import sys

def main():
    print("running installer.py :3")
    # example: create a symlink for a sample dotfile
    home = os.path.expanduser("~")
    source_file = os.path.join(os.getcwd(), "sample_dotfile")
    dest_file = os.path.join(home, ".sample_dotfile")
    try:
        os.symlink(source_file, dest_file)
        print(f"dotfile linked: {dest_file} -> {source_file}")
    except FileExistsError:
        print("dotfile already linked!")
    except Exception as e:
        print("error linking dotfile:", e)
    
    print("installer finished?")

if __name__ == "__main__":
    main()
