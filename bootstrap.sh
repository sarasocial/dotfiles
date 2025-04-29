#!/bin/bash
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



# =============================================================================
#                                [ VARIABLES ]
# =============================================================================
# TARGET_REPO: url to the repo to be downloaded
TARGET_REPO="https://github.com/sarasocial/dotfiles"
# TARGET_DIR_NAME: directory name for downloaded repo
TARGET_REPO_NAME="sarasocial-dotfiles"

# DEPENDENCIES: contains a list of packages to be installed with pacman.
# updating this list changes which packages are installed.
DEPENDENCIES=(
    git
    gum # yum
)

h_margin=6
v_margin=2
indent_level=0
indent_strength=4
indent_actual=0
min_indent=-1

# FORMAT_CODES: tputs for text interface formatting
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


display_type="justify"
dependencies_required=true
updates_required=true



# =============================================================================
#                             [ PRINT FUNCTIONS ]
# =============================================================================
# FUNC: update_terminal_dimensions (<int h_margin?>, <int v_margin?>):
# DESC: updates terminal dimensions; can be fed new values for h_margin &
#       v_margin
update_terminal_dimensions() {
    cols=$(tput cols)               # total columns of terminal
    lines=$(tput lines)             # total lines of terminal
    width=$(( cols - l_margin - r_margin ))    # usable columns of terminal, per h_margin
    height=$(( lines - t_margin - b_margin ))  # usable lines of terminal, per v_marign
    l_space=
}; update_terminal_dimensions


# FUNC: update_terminal_dimensions (<h=int>?, <v=int>?):
# DESC: updates terminal dimensions; can be fed new values for h_margin &
#       v_margin
# USE:  
h_margin_default=$h_margin
v_margin_default=$v_margin
h_margin_cached=$h_margin
v_margin_cached=$v_margin
margin () {
    local op=$1
    local temp_h_margin_cached=$h_margin
    local temp_h_margin_cached=$v_margin
    case "$op" in
        [rR]*) # reset
            h_margin=$h_margin_default
            v_margin=$v_margin_default
            h_margin_cached=$temp_h_margin_cached
            v_margin_cached=$temp_v_margin_cached
            ;;
        [sS][wW][aA][pP]|[rR][eE][sS][tT][oO][rR][eE]) # swap / restore
            h_margin=$h_margin_cached
            v_margin=$v_margin_cached
            h_margin_cached=$temp_h_margin_cached
            v_margin_cached=$temp_v_margin_cached
            ;;
        [sS][eE][tT])   # swap to cached margins
            shift
            h_margin_cached=$temp_h_margin_cached
            v_margin_cached=$temp_v_margin_cached
            for arg in "$@"; do
                case $arg in
                    h=*)    # sets horizontal margin & caches
                        h_margin="${arg#h=}"
                        ;;
                    v=*)    # sets vertical margin & caches
                        v_margin="${arg#v=}"
                        ;;
                    h+=*)    # sets horizontal margin & caches
                        local new_margin=$(( h_margin - "${arg#h+=}" ))
                        if [[ $new_margin < 0 ]]; then new_margin=0; fi
                        h_margin=$new_margin
                        ;;
                    v+=*)    # sets vertical margin & caches
                        local new_margin=$(( v_margin + "${arg#v+=}" ))
                        if [[ $new_margin < 0 ]]; then new_margin=0; fi
                        v_margin=$new_margin
                        ;;
                    h-=*)    # sets horizontal margin & caches
                        local new_margin=$(( h_margin - "${arg#h-=}" ))
                        if [[ $new_margin < 0 ]]; then new_margin=0; fi
                        h_margin=$new_margin
                        ;;
                    v-=*)    # sets vertical margin & caches
                        local new_margin=$(( v_margin - "${arg#v-=}" ))
                        if [[ $new_margin < 0 ]]; then new_margin=0; fi
                        v_margin=$new_margin
                        ;;
                    *)   echo "warning: unknown arg '$arg'" ;;
                esac
            done

            v_margin_cached=$temp_v_margin_cached
            h_margin_cached=$temp_h_margin_cached
            ;;
        *)
            operated=false
            ;;
    esac
    update_terminal_dimensions
}


indent_default=$indent_level
indent_cached=$indent_level
indent () {
    local op=$1
    local temp_indent_cached=$indent_level
    case "$op" in
        [rR]*) # reset
            indent_level=$indent_default
            indent_cached=$temp_indent_cached
            ;;
        [sS][wW][aA][pP]|[rR][eE][sS][tT][oO][rR][eE]) # swap / restore
            indent_level=$indent_cached
            indent_cached=$temp_indent_cached
            ;;
        [sS][eE][tT])   # swap to cached margins
            shift
            indent_cached=$temp_indent_cached
            for arg in "$@"; do
                case $arg in
                    [0-9]*|-[0-9]*)    # sets horizontal margin & caches
                        indent_level="${arg#}"
                        ;;
                    +*)    # sets horizontal margin & caches
                        local new_indent=$(( indent_level + "${arg#+}" ))
                        if [[ $indent_level < $min_indent ]]; then new_indent=$min_indent; fi
                        indent_level=$new_indent
                        ;;
                    -*)    # sets vertical margin & caches
                        local new_indent=$(( indent_level - "${arg#-}" ))
                        if [[ $indent_level < $min_indent ]]; then new_indent=$min_indent; fi
                        indent_level=$new_indent
                        ;;
                    *)   echo "warning: unknown arg '$arg'" ;;
                esac
            done
            indent_cached=$temp_indent_cached
            ;;
        *)
            operated=false
            ;;
    esac
    indent_actual=$(( indent_level * indent_strength ))
    update_terminal_dimensions
}

# FUNC: process_line_tag (<str tag>):
# DESC: processes line tags; these switch display type from centered to
#       justified, and vice versa.
process_line_tag () {
    local tag="$1"  # line tag as $1
    case $tag in
        [cC]*)    # if tag is centered, swap to centered
            display_type="center"
            ;;
        *)        # else, swap to justified
            display_type="justify"
            ;;
    esac
}


# FUNC: process_text_tag (<str tag>):
# DESC: takes an inputted text tag & converts it into a format code
#       ie. $(tput bold)
process_text_tag () {
    local tag="$1"
    echo "${FORMAT_CODES[$tag]}"
}


# center_print ()
    # if display mode is centered, this will print text centered
    # in the terminal
print_center () {
    local text="$1"
    local length="$2"

    # center the composed text
    local padding=$(( (cols - length) / 2 ))
    printf "%*s%s\n" "$padding" "" "$text"
}


# justify_print (<str text>, <str raw_text>)
# prints $text justified to $width, using $raw_text lengths,
# with $h_margin spaces to the left and hyphens when needed
# justify_print (<str text>, <str raw_text>)
# prints $text justified to $width, using $raw_text for length calcs;
# prefixes each line with $h_margin spaces, wraps and hyphenates as needed
print_justify () {
    local text="$1"
    local raw="$2"
    local max=$width
    local total_whitespace=$(( indent_actual + h_margin ))

    # split into parallel arrays on spaces
    local -a words raws
    IFS=' ' read -r -a words <<< "$text"
    IFS=' ' read -r -a raws  <<< "$raw"

    local line=""      # accumulates words for this line
    local len=0        # raw-text length of $line

    for i in "${!words[@]}"; do
        local w=${words[i]}
        local r=${raws[i]}
        local rlen=${#r}

        # will it fit (plus a space if not first word)?
        if (( len + (len>0 ? 1 : 0) + rlen <= max )); then
        if (( len > 0 )); then
            line+=" $w"
            (( len += 1 + rlen ))
        else
            line="$w"
            len=$rlen
        fi

        else
        # word itself too long → hyphenate
        if (( rlen > max )); then
            # flush existing line
            [[ -n $line ]] && printf "%*s%s\n" "$total_whitespace" "" "$line"
            line=""; len=0
            # break off as much as fits minus 1 for the hyphen
            local avail=$(( max - 1 ))
            local head=${w:0:avail}
            local tail=${w:avail}
            printf "%*s%s-\n" "$total_whitespace" "" "$head"
            line="$tail"
            len=${#tail}

        else
            # normal wrap
            printf "%*s%s\n" "$total_whitespace" "" "$line"
            line="$w"
            len=$rlen
        fi
        fi
    done

    # print any leftover
    [[ -n $line ]] && printf "%*s%s\n" "$total_whitespace" "" "$line"
}


# FUNC: filter_installed () <array>
# removes already-installed packages from dependency list
filter_installed () {
    dependencies_required=true
    local -n arr=$1         # array is passed as $1
    local filtered=()       # temp array for missing pkgs

    for pkg in "${arr[@]}"; do
        if ! pacman -Q "$pkg" &>/dev/null; then
        filtered+=("$pkg")  # pkg isn’t installed; keep in array
        fi
    done

    arr=("${filtered[@]}")  # overwrite original array with only missing

    if [[ ${#DEPENDENCIES[@]} -eq 0 ]]; then
        dependencies_required=false # update bool
    fi
}

check_for_updates () {
    updates_required=true
    if command -v checkupdates &>/dev/null; then
        UPDATES=$(checkupdates)
    else
        pacman -Sy --quiet &>/dev/null
        UPDATES=$(pacman -Qu)
    fi
    if [[ ! -n "$UPDATES" ]]; then
        updates_required=false # update bool
    fi
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
    
    if [[ "$display_type" == "center" ]]; then
        output="$(print_center "$text" ${#clean_text})"
    else
        output="$(print_justify "$text" "$clean_text")"
    fi

    echo "$output"
}

print_action () {
    action=$1
    if [[ $h_margin -ge 2 ]]; then
        margin set h=0
        print "<j><reset><c>"
        print "> [ <u>$action<reset><c> ]"
        print "<w><reset>"
        margin swap
        indent swap
    else
        print "<j><reset><c><b>"
        print "> [ <u>$action<reset><c><b> ]"
        print "<w><reset>"
    fi
}

print_error () {
    changed_margin=false
    error_message=$1

    if [[ $h_margin -ge 2 ]]; then
        changed_margin=true
        margin set "h-=2"
    fi

    print "<j><reset><b>"
    print "<r>! [ ERROR ]<reset>"
    for line in "$@"; do
        print "<r>     | $line"
    done
    print "<w><reset>"

    if [[ $changed_margin == true ]]; then
        margin swap
    fi
}


prompt () {
    changed_margin=false
    if [[ $h_margin -ge 2 ]]; then
        changed_margin=true
        margin set "h-=2"
    fi

    read -r -p "$(print "<reset><w>> $@")" input < /dev/tty

    if [[ $changed_margin == true ]]; then
        margin swap
    fi
}

throw_error () {
    print_error "$@"
    if [[ $h_margin -ge 2 ]]; then
        margin set "h-=2"
    fi
    read -n 1 -s -r -p "$(print "<w>> Press any key to exit ")"
    exit 1
}

assert_root () {
    if command -v sudo &>/dev/null; then
        PRIV_CMD="sudo"
    elif command -v su &>/dev/null; then
        PRIV_CMD="su -c"
    elif [[ $EUID -eq 0 ]]; then
        PRIV_CMD=""
    else
        throw_error "This script requires root privileges" "Please try again as root, or install sudo/su"
    fi
}

# run_checks () {}
    # run a series of checks; update variables accordingly
run_step_checks () {
    # set base variables
    PRIV_CMD=""
    updates_required=true
    dependencies_required=true
    repo_exists=false

    # assert that user is root or has sudo/su installed
    assert_root

    # check which dependencies have already been installed
    filter_installed DEPENDENCIES

    # check if repo already exists
    if test -d "~/$TARGET_REPO_NAME"; then
        repo_exists=true # update bool
    fi
}
run_step_checks

# display_main_menu ()
    # pretty self-explanatory!
    # really just a bunch of print statements, takes a y/n
    # input at the end.
display_main_menu () {
    step=1
    margin set h=6
    clear
    print ""
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
    print_action "Starting Bootstrap"
    print "<m><b>[ dotfiles repo ]"
    print "<reset><c>   <u>https://github.com/sarasocial/dotfiles<reset>"
    print "<m><b>[ this script ]"
    print "<reset><c>   <u>https://sarasoci.al/dots.sh<reset>"
    print "<m><b>[ more sara ♡ ]"
    print "<reset><c>   <u>https://sarasoci.al<reset>"
    print "</>"
    print "<\j><w>Continuing will perform the following actions:"
    print ""
    indent set 1

    # first step: update system
    if [[ $updates_required == true ]]; then
        print "    <m>$step.<w> Update system & packages"
        step=2;
    fi
    # second step: install dependencies
    if [[ $dependencies_required == true ]]; then
        print "    <m>$step.<w> Install packages required by the dotfiles installer:"
        for i in "${DEPENDENCIES[@]}"; do
            print "            <m>$i"
        done
        step=$(( step + 1));
    fi

    # third step: clone repo
    if [[ repo_exists == true ]]; then
        print "    <m>$step.<w> Clone the dotfiles repository"
    else
        print "    <m>$step.<w> Overwrite existing dotfiles repository installation (optional)"
    fi
    step=$(( step + 1));
    
    # final step: run installer
    print "    <m>$step.<w> Run the dotfiles installer"
    indent set 0
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

sleep 0.1

if [[ $updates_required == true ]]; then
    print_action "Updating System..."
    $PRIV_CMD pacman -Syu < /dev/tty
fi
check_for_updates
if [[ $updates_required == true ]]; then
    print_error "Unable to fully update system and packages"
    prompt "<w>Continue without fully updating? <m>[y/N]:<w> "
    case "$input" in
        [yY][eE][sS]|[yY])
        *)
            prompt "<w>Rerun the bootstrap script? <m>[y/N]:<w> "
            case "$input" in
                [yY][eE][sS]|[yY]) curl -L sarasoci.al/dots.sh | bash; exit;;
                *) clear; exit;;
            esac
    esac
fi

sleep 0.1

if [[ $dependencies_required == true ]]; then
    print_action "Installing dependencies..."
    $PRIV_CMD pacman -S "${DEPENDENCIES[@]}" < /dev/tty
fi
filter_installed DEPENDENCIES
if [[ $dependencies_required == true ]]; then
    print_error "Unable to install dependencies"
    prompt "<w>Rerun the bootstrap script? <m>[y/N]:<w> "
    case "$input" in
        [yY][eE][sS]|[yY])
            curl -L sarasoci.al/dots.sh | bash;
            exit
            ;;
        *)
            clear
            exit
            ;;
    esac
fi

sleep 0.1

if [[ $repo_exists == false ]]; then
    sleep 0.1
    git clone $TARGET_REPO "~/$TARGET_REPO_NAME"
else
    print "<reset>" '~/' "$TARGET_REPO_NAME already exists"
    print ""
    prompt "Do you want to overwrite it? <m>[y/N]:<w> "
    case "$input" in
        [yY][eE][sS]|[yY])
            sleep 0.1
            $PRIV_CMD rm -rf "~/$TARGET_REPO_NAME"
            sleep 0.1
            git clone $TARGET_REPO "~/$TARGET_REPO_NAME"
            sleep 0.1
            ;;
        *)
            ;;
    esac
fi

repo_exists=false
if test -d "~/$TARGET_REPO_NAME"; then
    repo_exists=true # update bool
fi

sleep 0.1

if [[ $repo_exists == false ]]; then
    print_error "Unable to clone repository"
    prompt "<w>Rerun the bootstrap script? <m>[y/N]:<w> "
    case "$input" in
        [yY][eE][sS]|[yY])
            curl -L sarasoci.al/dots.sh | bash
            exit
            ;;
        *)
            clear;
            exit
            ;;
    esac
fi

sleep 0.1
print_action "Starting Installer..."
sleep 0.1

bash "~/$TARGET_REPO_NAME/install.sh"

# Ask: continue?

# Install missing packages