#!/bin/bash

# Copyright 2014 Nikolay Konovalow
# Licensed under the Apache License, Version 2.0 <LICENSE-APACHE or
# http://www.apache.org/licenses/LICENSE-2.0>

# Make 'classes' available by simple "require <classname>"

current=$( dirname "$0" )
stead="$HOME/.instead/stead"

if ! [ -e "$stead" ]
then
	mkdir "$stead"
fi

for file in "$current"/*
do
	if [ "$file" != "$0" ]
	then
		ln -s "$file" --target-directory="$stead"
	fi
done

notify-send "--expire-time=3000" "INSTEAD-tools' 'classes' module" "Модуль готов к применению"
