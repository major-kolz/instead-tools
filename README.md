instead-tools
=============
My groundwork for game writing for [INSTEAD](http://instead.syscall.ru/index.html)-platform. Some of files (e.g. *lua.snippets*) should be at specific directories, but I suggest you substitute it with symbolic links (symlinks). That allow you refresh instead-tools only by "git pull", without annoying file-copying in every project folder.

Project contains:

* ##### useful.lua
Code wrappers for high-usage constructions (selections from list by index, error checking, random phrase selection, etc)

* ##### cutscene.lua
Modified [cutscene module](http://instead.syscall.ru/wiki/ru/gamedev/modules/cutscene)(ru). Changes:
  - set default {cut} view by field _cutDefTxt
  - {cut} follow after blank line ("^^"). For change it, specify field _cutPrefix
  - {cls} is abandoned, use {upd} instead {cut}{cls}
  - {upd} call method 'update' of this room
  - you may use method 'left'

* ##### vim/lua.snippets
My snippets for [Vim](www.vim.org/). I use [vim-snipmate](https://github.com/garbas/vim-snipmate) plugin for play it. First part of the file contain pure Lua construction, second - INSTEAD-specify snippets. At the end you can see snippets for my useful.lua.

* #### classes/
I am writing new module, that should help with interactivity in game. My aim: define classes of INTEAD's *obj* with specific functionality and simplify the way of it creating. I think, an author wish not spend his time for coding features (*obj* interaction, in this context), that appear in game once or twice. So, I catch some of this patterns of interacting and code it for your. 
**NOTICE** You should add symlinks for every of *classes*' file into ~/.instead/games for use *require "<class-name>"* syntax. To copy all of them use *distribute.sh* from *classes* folder

* #### minIDE/
Scripts, that simplify non-writting gamedeveloping.
	- **init.sh** (I suggest create symlink in instead-projects folder, i.e "~/.instead/games") preper new directory for game. Will create new main.lua (with "insteadbegin" word, that unfold in game headline; require *lua.snippets*) and symlinks for *useful.lua* and *assist.sh*
	- **assist.sh** - [under construction] will pack game for you (with [repo](http://instead-games.ru/)-correct name and substitut symlinks by real modules)

* #### examples/
Simple games, that help you familiarize yourself *with instead-tools*. Script *unfold_all.sh* create folders in instead-projects directory (i.e "~/.instead/games") with this examples (change the names to *main.lua*) and add symlink for *useful.lua*
