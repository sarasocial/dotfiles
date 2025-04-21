#!/bin/bash

is_integer() {
    local re='^-?[0-9]+$'
    [[ $1 =~ $re ]]
}

adjust_margins () {
    for arg in $@; do
        echo $arg
    done
}

h_margin=0
v_margin=0

adjust_margin() {
    for arg in "$@"; do
        case $arg in
            h=*) h_margin="${arg#h=}" ;;
            v=*) v_margin="${arg#v=}" ;;
            *)   echo "warning: unknown arg '$arg'" ;;
        esac
    done
    update_terminal_dimensions
}

adjust_margin h=3
adjust_margin v=1
adjust_margin h=12 h=4 v=9 v=6 v=4 h=6