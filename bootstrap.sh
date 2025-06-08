#!/bin/bash

DEBUG=1;
[ "$#" > 0 ] && [ "$1" = "debug" ] && DEBUG=0

lib.print () {
    print () {
        local debug_print=1;
        local color="$(tput setaf 7)"
        for input in "$@"; do
            case "$input" in
                -r|--red) color="$(tput setaf 1)"; ;;
                -g|--green) color="$(tput setaf 2)"; ;;
                -y|--yellow) color="$(tput setaf 3)"; ;;
                -b|--blue) color="$(tput setaf 4)"; ;;
                -p|--purple) color="$(tput setaf 5)"; ;;
                -c|--cyan) color="$(tput setaf 6)"; ;;
                -w|--white) color="$(tput setaf 7)"; ;;
                -d|--debug) debug_print=0; ;;
                *)
                    if [ $debug_print = 1 ] || [ $DEBUG = 0 ]; then
                        printf "$color$input$(tput setaf 7)"
                    fi
                    ;;
            esac
        done
        if [ $debug_print = 1 ] || [ $DEBUG = 0 ]; then
            printf "\n"
        fi
    }
    warn () {
        print -y -d "$@"
    }
    error () {
        printf "%s\n" "$(tput setaf 1)Error: $1"
        if [ $DEBUG = 1 ]; then
            print -r "\nTo rerun this script in debug mode, use the following command:"
            print -r " $ $(tput smul)curl -L sarasoci.al/dots.sh | bash -s -- debug$(tput sgr0)"
        fi
        exit 1
    }
    check () {
        print -d "    [X] " "$@"
    }
    uncheck () {
        if [ "$#" = 1 ]; then
            warn "    [ ] $1"
        elif [ "$#" = 2 ]; then
            warn "    [ ] $1: $2"
        fi
    }
}
lib.print

lib.check () {
    check_OS () {
        OSNAME=$(hostnamectl 2>/dev/null | grep "Operating System" | awk -F': ' '{print $2}' || "")
        [ ! "$OSNAME" = "Arch Linux" ] && error "You're not using Arch, btw"
        check "Determined OS"
        print -d "      > " -p "$OSNAME"
    }
    # Ensure that pacman is working
    # idfk why it wouldn't be but this seems like a good thing to double-check??
    # grabs package list with -Q; if there's no output, we assume pacman isn't
    # working for whatever fucking reason
    check_pacman () {
        {
            pkg_list="$(pacman -Q 2>/dev/null)"
        } || {
            pkg_list=""
        }
        if [ ! "$pkg_list" = "" ]; then
            check "Verified pacman"
        else
            uncheck "Could not verify pacman"
            error "Unable to verify pacman"
        fi
        check_package () {
            pacman -Q | awk '{print $1}' | grep -Fxq "$1"
        }
        PKGMGR="pacman"
        {
            pacman -Su 1>/dev/null 2>/dev/null
        } || {
            if check_package "sudo"; then
                print -d "      > " -p "sudo"
                PKGMGR="sudo pacman"
            else
                error "Sudo not installed"
            fi
        }
        return 0
    }
    check_library() {
        libname="$1"
        grep -q "^\[$libname\]" /etc/pacman.conf
    }
}
lib.check


print -p "\n┌────   ──────────────   ────┐"
print -p "│                            │"
[ $DEBUG = 1 ] && print -p "│        [ saradots ]        │" || \
print -p "│   [ saradots ] " -y "[ debug ]" -p "   │"
print -p "│      " -w "$(tput smul)sarasoci.al/dots$(tput sgr0)" -p "      │"
print -p "│                            │"
print -p "└─────────   ────   ─────────┘\n"

warn "Running in debug mode\n"
print -d "Performing base system checks..."
check_OS
check_pacman

checkPKGMGR () {
    PKGMGRs=()
}

check_package "yay" && PKGMGR="yay" && yay_installed=0;
check_package "paru" && PKGMGR="paru" && paru_installed=0;
check_package "gum" && gum_installed=0

if [ ! "$PKGMGR" = "" ]; then
     check "Determined PKGMGR"
     print -d "      > " -p "$PKGMGR"
else
    error "Unable to determine PKGMGR"
fi


libraries=(
    core
    extra
    multilib
    multilib-testing
)
print -d "Checking libraries..."
for LIB in "${libraries[@]}"; do
    if check_library "$LIB"; then
        check "Library '" -p "$LIB" -w "' included"
    else
        uncheck "Library '$LIB' not included"
    fi
done

print -d "Checking packages..."
dependencies=(
    git
    firefox
    gum
    base-devel
)
for PKG in "${dependencies[@]}"; do
    if check_package "$PKG"; then
        check "Package '" -p "$PKG" -w "' installed"
    else
        uncheck "Package '$PKG' not installed"
    fi
done
print -d "Checks complete!"




# check OS: Arch Linux
# check pacman
# check libraries: core, extra, multilib, multilib-testing
# check aur helpers