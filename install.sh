#!/bin/bash
# install.sh

# check if python is installed
if ! command -v python &>/dev/null; then
    echo "python not found. installing..."
    sudo pacman -S --noconfirm python
fi

# create a virtualenv if it doesn't already exist
if [ ! -d ".venv" ]; then
    echo "creating virtualenv..."
    python -m venv .venv
    source .venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt
else
    source .venv/bin/activate
fi

# run the installer script
python installer.py "$@"