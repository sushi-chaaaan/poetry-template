#!/bin/bash

if [ "$HOME" = "$(pwd)" ]; then
    echo "You are in your home directory."
    echo "making a new directory..."

    if [ -n "$ZSH_VERSION" ]; then
        read -r "new_dir_name?Please enter the name of the directory:":
    else
        read -r -p "Please enter the name of the directory:" new_dir_name
    fi
    mkdir -p "$new_dir_name"
    cd "$new_dir_name" || exit
fi
