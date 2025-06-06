#!/bin/bash

printf "\n$(tput setaf 5)Sara's Dotfiles\n"

print () {
    printf "\n$(tput setaf 7)"
    for fragment in "$@"; do
        printf "%s" "$fragment"
    done
}
warn () {
    printf "%s" "\n$(tput setaf 3)Warning: $1"
}
error () {
    printf "%s" "\n$(tput setaf 1)Error: $1"
    exit 1
}

is_installed() {
    pacman -Q | awk '{print $1}' | grep -Fxq "$1"
}

OSNAME=$(hostnamectl 2>/dev/null | grep "Operating System" | awk -F': ' '{print $2}' || "")
[ ! "$OSNAME" = "Arch Linux" ] && error "You're not using Arch, btw"

PKGMGR="pacman"
pacman --quiet -Sy 2>/dev/null || PKGMGR="sudo pacman"
[ "$PKGMGR" = "sudo pacman" ] && ! is_installed "sudo" && PKGMGR=""

is_installed "yay" && PKGMGR="yay" && yay_installed=0;
is_installed "paru" && PKGMGR="paru" && paru_installed=0;
is_installed "gum" && gum_installed=0