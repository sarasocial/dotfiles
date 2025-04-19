#!/bin/bash

DEPENDENCIES=(
    git
    gum
)

h_margin=6 # left/right margins of text interface
v_margin=4 # top/bottom margins of text interface

# define a function that filters an array in-place
filter_installed() {
  local -n arr=$1         # nameref to the array you pass in
  local filtered=()       # temp array for missing pkgs

  for pkg in "${arr[@]}"; do
    if ! pacman -Q "$pkg" &>/dev/null; then
      filtered+=("$pkg")  # pkg isn’t installed, keep it
    fi
  done

  arr=("${filtered[@]}")  # overwrite original arr with only missing
}

filter_installed DEPENDENCIES

echo ""
echo "The following packages will be installed: ${DEPENDENCIES[*]}"

update_terminal_dimensions() {
    cols=$(tput cols)
    lines=$(tput lines)
    width=$(( cols - h_margin ))
    height=$(( lines - v_margin ))
}
update_terminal_dimensions

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

display_type="justified"
process_line_tag () {
    local tag="$1"
    case $tag in
        "c"|"C")
            display_type="centered"
            ;;
        *)
            display_type="justified"
            ;;
    esac
}

process_text_tag () {
    local tag="$1"
    echo "${FORMAT_CODES[$tag]}"
}

center_print() {
    local text="$1"
    local length="$2"

    # center the composed text
    local padding=$(( (cols - length) / 2 ))
    printf "%*s%s\n" "$padding" "" "$text"
}

margin_print() {
    local text="$1"
    local length="$2"

    # center the composed text
    printf "%*s%s\n" "$h_margin" "" "$text"
}

# function: parse_tags
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
        text="$clean_text"
    fi
    
    if [[ "$display_type" == "centered" ]]; then
        output="$(center_print "$text" ${#clean_text})"
    else
        output="$(margin_print "$text" ${#clean_text})"
    fi

    echo "$output"
}

display_main_menu () {
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
    print "                  [ github.com/sarasocial/dotfiles ]    │    [ Installer Bootstrap ]    │"
    print "                                                        └───────────────────────────────┘"
    print ""
    print ""
    print ""
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
    print "No other changes will be made."
    print ""
    read -r -p "$(print "Do you want to proceed? <m>[y/N]<w>: <@>")" yn
}

display_main_menu
while true; do
    case "$yn" in
        [yY][eE][sS]|[yY]) break;;
        [nN][oO]|[nN]) clear; exit;;
        *) display_main_menu;;
    esac
done


sudo pacman -S "${DEPENDENCIES[*]}"

# Ask: continue?

# Install missing packages