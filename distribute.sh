#!/bin/bash

# Copyright 2014 Nikolay Konovalow
# Licensed under the Apache License, Version 2.0 <LICENSE-APACHE or
# http://www.apache.org/licenses/LICENSE-2.0>

# Make 'useful.lua', 'cutscene.lua' and 'classes' available by simple "require <classname>"

current=$( dirname "$0" )
stead="$HOME/.instead/stead"

if ! [ -e "$stead" ]
then
	mkdir "$stead"
fi

ln -s "$current/useful.lua" --target-directory="$stead"
ln -s "$current/cutscene.lua" --target-directory="$stead"
for file in "$current/classes"/*
do
	if [ "$file" != "$current/classes/README.md" ]
	then
		ln -s "$file" --target-directory="$stead"
	fi
done

notify-send "--expire-time=3000" "INSTEAD-tools' modules" "Модули готов к применению"
