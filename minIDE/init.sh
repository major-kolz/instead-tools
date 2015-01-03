#!/bin/bash

# Copyright 2014 Nikolay Konovalow
# Licensed under the Apache License, Version 2.0 <LICENSE-APACHE or
# http://www.apache.org/licenses/LICENSE-2.0>

	# Create and prepare new directory for INSTEAD game 

# Path to instead-tools directory 
source="$HOME/.instead/games/instead-tools"
# This file (init.sh) should be at ~/.instead/games
current=$( dirname "$0" )

mkdir "$current/newOne"
touch "$current/newOne/main.lua"

# Codeword for lua's snippet, help with headline
echo "insteadbegin" >> "$current/newOne/main.lua"
# Script, that pack your game for distribution
ln -s "$source/minIDE/assist.sh" "$current/newOne"
# Additional files
cp -n -s "$source/minIDE/readme-unix.txt" "$current/newOne"
cp -n -s "$source/minIDE/readme-windows.txt" "$current/newOne"
# TODO Licensing
