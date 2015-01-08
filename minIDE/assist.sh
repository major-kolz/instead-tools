#!/bin/bash

# Copyright 2014 Nikolay Konovalow
# Licensed under the Apache License, Version 2.0 <LICENSE-APACHE or
# http://www.apache.org/licenses/LICENSE-2.0>

	# Pack current directory for distribution  

# Create symlinks for modules from instead-tools
current=$( dirname "$0" )
stead="$HOME/.instead/stead"
reqs=$( grep -o "require[ ]*['\"]\(.*\)['\"]" "$current/main.lua" )
modules=$( sed -n "s/['\"]//gp" <<< $(sed -n "s/require[ ]*//gp" <<< "$reqs") )
for modname in $modules 
do
	if ! [ -e "$current/$modname.lua" ]
	then
		if [ -e "$stead/$modname.lua" ]
		then
			cp -n -s "$stead/$modname.lua" "$current"
		fi
	fi
done 
# zip current directory, except files TODO, jourtal.txt and <dirname>.zip 
