#!/bin/bash

current=$( dirname "$0" )
gameDir="$HOME/.instead/games"

cd "$gameDir"

for file in "$current"/* 
do
	filename=$(basename "$file")
	fnam=${filename%.*}
	if [ "$fnam" != "unfold_all" ]
	then
		mkdir "$fnam"
		ln -s "$file" "$gameDir/$fnam"
		mv "$gameDir/$fnam/$fnam.lua" "$gameDir/$fnam/main.lua"
		ln -s "$gameDir/instead-tools/useful.lua" "$gameDir/$fnam"
	fi
done

notify-send "--expire-time=3000" "INSTEAD-tools' examples" "Все примеры распакованы в $gameDir"
