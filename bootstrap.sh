#   bootstrap.sh | @sarasocial
#   updated 04.19.2025
# 
#   this script functions as a bootstrap for my dotfiles
#   installer. it can be called with:
#
#           $ curl -L sarasoci.al/dots.sh | bash
# 
#   it performs the following actions, as approved
#   by the user:
#
#       1. [ Update System ]
#              if no updates pending, this step is skipped.
#
#       2. [ Install Dependencies ]
#              if no packages are needed, this step is skipped.
#
#       3. [ Download Repo]
#              if the dotfiles repo has already been downloaded,
#              the script will ask the user if they wish to
#              redownload it.
#              [source]: https://github.com/sarasocial/dotfiles
#
#       4. [ Run Installer ]
#              this happens automatically at the end of the
#              script; the user is not prompted.
#!/bin/bash

# [ DEPENDENCIES ]
# contains a list of packages to be installed with pacman.
# updating this list changes which packages are installed.
DEPENDENCIES=(
    git
    gum
)

h_margin=6 # left/right margins of text interface
v_margin=4 # top/bottom margins of text interface

# filter_installed ()
    # removes already-installed packages from dependency list
filter_installed() {
  local -n arr=$1         # array is pass as $1
  local filtered=()       # temp array for missing pkgs

  for pkg in "${arr[@]}"; do
    if ! pacman -Q "$pkg" &>/dev/null; then
      filtered+=("$pkg")  # pkg isn’t installed; keep in array
    fi
  done

  arr=("${filtered[@]}")  # overwrite original array with only missing
}

# run filter_installed () on dependencies
filter_installed DEPENDENCIES

# update_terminal_dimensions ()
    # literally just updates the terminal dimensions lol
update_terminal_dimensions() {
    cols=$(tput cols)
    lines=$(tput lines)
    width=$(( cols - h_margin ))
    height=$(( lines - v_margin ))
}

    # formatting codes; full names aren't really necessary but
    # oh well !
declare -A FORMAT_CODES=(
    [b]="$(tput bold)"
    [bold]="$(tput bold)"
    [u]="$(tput smul)"
    [underline]="$(tput smul)"
    [r]="$(tput setaf 1)"   # red
    [red]="$(tput setaf 1)"   # red
    [g]="$(tput setaf 2)"   # green
    [green]="$(tput setaf 2)"   # green
    [y]="$(tput setaf 3)"   # yellow
    [yellow]="$(tput setaf 3)"   # yellow
    [bl]="$(tput setaf 4)"  # blue
    [blue]="$(tput setaf 4)"  # blue
    [m]="$(tput setaf 5)"   # magenta
    [magenta]="$(tput setaf 5)"   # magenta
    [c]="$(tput setaf 6)"   # cyan
    [cyan]="$(tput setaf 6)"   # cyan
    [w]="$(tput setaf 7)"   # white
    [white]="$(tput setaf 7)"   # white
    [/]="$(tput sgr0)"  # full reset
    [reset]="$(tput sgr0)"  # full reset
)

# process_line_tag ()
    # function that processes line tags and can switch the display
    # type from centered to justified, and vice versa
display_type="justified"
process_line_tag () {
    local tag="$1"  # line tag as $1
    case $tag in
        [cC]*)    # if tag is centered, swap to centered
            display_type="centered"
            ;;
        *)        # else, swap to justified
            display_type="justified"
            ;;
    esac
}

# process_text_tag ()
    # simply takes a text tag as an input and converts it into
    # a format code, ie. $(tput bold)
process_text_tag () {
    local tag="$1"
    echo "${FORMAT_CODES[$tag]}"
}

# center_print ()
    # if display mode is centered, this will print text centered
    # in the terminal
center_print() {
    local text="$1"
    local length="$2"

    # center the composed text
    local padding=$(( (cols - length) / 2 ))
    printf "%*s%s\n" "$padding" "" "$text"
}

# justify_print ()
    # if display mode is justified, this will print text justified*
    # in the terminal
justify_print() {
    local text="$1"
    local length="$2"

    # center the composed text
    printf "%*s%s\n" "$h_margin" "" "$text" # *not actually justified lmao
}

# function: print ()
    # does a bunch of goofy ass inefficient formatting shit using the
    # above functions and the below logic. meant to parse a single
    # line of text. supports the following:
        # text tags: <b>, </>, <w>, <r>, ... etc
        # line tags: <\c>, <\j>
        # read input tag: <@>
print () {
    reading=false
    formatted_text=""
    clean_text=""
    local raw_text="$*"
    local -a substrings=()
    # this regex splits by <...> and keeps the delimiters
    while IFS= read -r line; do
        substrings+=("$line")
    done < <(perl -ne 'print "$_\n" for split(/(<[^>]+>)/)' <<< "$raw_text")

    for sub in "${substrings[@]}"; do
        if [[ "$sub" == \<* ]]; then
            if [[ "$sub" == *\> ]]; then
                sub="${sub#<}"   # remove leading <
                sub="${sub%>}"   # remove trailing >
                if [[ "$sub" == \\* ]]; then
                    sub="${sub#\\}"   # remove leading \
                    process_line_tag "$sub"
                elif [[ "$sub" == "@" ]]; then
                    reading=true
                else
                    formatted_text+="$(process_text_tag $sub)"
                fi
            else
                formatted_text+="$sub"
                clean_text+="$sub"
            fi
        else
            formatted_text+="$sub"
            clean_text+="$sub"
        fi
    done

    if [[ $reading == false ]]; then
        text="$formatted_text"
    else
        text="$formatted_text"
    fi
    
    if [[ "$display_type" == "centered" ]]; then
        output="$(center_print "$text" ${#clean_text})"
    else
        output="$(justify_print "$text" ${#clean_text})"
    fi

    echo "$output"
}

announce_action () {
    action=$1
    if [[ $h_margin -ge 2 ]]; then
        h_margin=$(( h_margin - 2 ))
        update_terminal_dimensions
        print "<j><reset><c>"
        print "> [ <u>$action<reset><c> ]"
        print "<w><reset>"
        h_margin=$(( h_margin + 2 ))
        update_terminal_dimensions
    else
        print "<j><reset><c><b>"
        print "> [ <u>$action<reset><c><b> ]"
        print "<w><reset>"
    fi
}

# display_main_menu ()
    # pretty self-explanatory!
    # really just a bunch of print statements, takes a y/n
    # input at the end.
display_main_menu () {
    update_terminal_dimensions
    clear
    print "<\c><m>"
    print "<w>     ███████╗ █████╗ ██████╗  █████╗ ███████╗     <m>██████╗  ██████╗ ████████╗███████╗     "
    print "<w>     ██╔════╝██╔══██╗██╔══██╗██╔══██╗██╔════╝     <m>██╔══██╗██╔═══██╗╚══██╔══╝██╔════╝     "
    print "<m>│<w>    ███████╗███████║██████╔╝███████║███████╗     <m>██║  ██║██║   ██║   ██║   ███████╗    │"
    print "<m>│<w>    ╚════██║██╔══██║██╔══██╗██╔══██║╚════██║     <m>██║  ██║██║   ██║   ██║   ╚════██║    │"
    print "<m>│<w>    ███████║██║  ██║██║  ██║██║  ██║███████║     <m>██████╔╝╚██████╔╝   ██║   ███████║    │"
    print "<m>│<w>    ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝     <m>╚═════╝  ╚═════╝    ╚═╝   ╚══════╝    │"
    print "│                                                                                       │"
    print "└───────────────────────────────────────────────────────┐                               │"
    print "                     [ made w/ love by @sarasocial ]    │    [ Installer Bootstrap ]    │"
    print "                                                        └───────────────────────────────┘"
    print "<\j>"
    announce_action "Starting Bootstrap"
    print "<m><b>[ dotfiles repo ]"
    print "<reset><c>   <u>https://github.com/sarasocial/dotfiles<reset>"
    print "<m><b>[ this script ]"
    print "<reset><c>   <u>https://sarasoci.al/dots.sh<reset>"
    print "<m><b>[ more sara ♡ ]"
    print "<reset><c>   <u>https://sarasoci.al<reset>"
    print "</>"
    print "<\j><w>Continuing will perform the following actions:"
    print ""

    if [[ ${#DEPENDENCIES} > 0 ]]; then
        print "    <m>1.<w> Install packages required by the dotfiles installer:"
        for i in "${DEPENDENCIES[@]}"; do
            print "            <m>$i"
        done
        print "    <m>2.<w> Clone the dotfiles repository"
        print "    <m>3.<w> Run the dotfiles installer"
    else
        print "    <m>1.<w> Clone the dotfiles repository"
        print "    <m>2.<w> Run the dotfiles installer"
    fi

    print ""
    print "No other changes will be made at this time."
    print ""
    read -r -p "$(print "Do you want to proceed? <m>[y/N]<w>: <@>")" yn < /dev/tty
}

display_main_menu
while true; do
    case "$yn" in
        [yY][eE][sS]|[yY]) break;;
        [nN][oO]|[nN]) clear; exit;;
        *) display_main_menu;;
    esac
done

announce_action "Installing Packages"

sleep 0.25

if command -v sudo &>/dev/null; then
    PRIV_CMD="sudo"
elif command -v su &>/dev/null; then
    PRIV_CMD="su -c"
elif [[ $EUID -eq 0 ]]; then
    PRIV_CMD=""
else
    echo "This script requires root privileges. Please run as root or install sudo/su."
    exit 1
fi

sudo pacman -S "${DEPENDENCIES[*]}"

# Ask: continue?

# Install missing packages