#!/bin/bash

current=$( dirname "$0" )
stead="$HOME/.instead/stead"

if ! [ -e "$i" ]
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
