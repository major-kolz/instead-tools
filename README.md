instead-tools
=============
My groundwork for game writing for [INSTEAD](http://instead.syscall.ru/index.html)-platform. Some of files (e.g. *lua.snippets*) should be at specific directories, but I suggest you substitute it with symbolic links (symlinks). That allow you refresh instead-tools only by "git pull", without annoying file-copying in every project folder.

Project contains:

* ##### useful.lua
Code wrappers for high-usage constructions (selections from list by index, error checking, random phrase selection, etc)

* ##### cutscene.lua
Modified [cutscene module](http://instead.syscall.ru/wiki/ru/gamedev/modules/cutscene)(ru). See changes-list at head of file.

* ##### vim/
Make my favorite [text editor](http://www.vim.org/) more suitable for INSTEAD's gamewritting

* ##### classes/
Quick constructor for some patterns of *obj*. Pattern covered: finite state machine.

* ##### minIDE/
Scripts, that simplify non-writting gamedeveloping.

* ##### examples/
Simple games, that help you familiarize yourself with *instead-tools*. Script *unfold_all.sh* create folders in instead-projects directory (i.e "~/.instead/games") with this examples (change the names to *main.lua*) and add symlink for *useful.lua*

## License

*Instead-tool's* is primarily distributed under the terms of the [Apache License](http://www.apache.org/licenses/LICENSE-2.0.html) (Version 2.0). See LICENCE for details.
