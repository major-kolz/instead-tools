#!/bin/bash

# Copyright 2014 Nikolay Konovalow
# Licensed under the Apache License, Version 2.0 <LICENSE-APACHE or
# http://www.apache.org/licenses/LICENSE-2.0>

# Path to instead-tools' minIDE directory 
source="$HOME/.instead/games/instead-tools"
current=$( dirname "$0" )

mkdir "$current/newOne"
touch "$current/newOne/main.lua"

# codeword for lua's snippet, help with headline
echo "insteadbegin" >> "$current/newOne/main.lua"

ln -s "$source/minIDE/assist.sh" "$current/newOne"
ln -s "$source/useful.lua" "$current/newOne"
