-- Copyright 2014 Nikolay Konovalow
-- Licensed under the Apache License, Version 2.0 <LICENSE-APACHE or
-- http://www.apache.org/licenses/LICENSE-2.0>

--$Name: Game name$
--$Version: 0.1
--$Author: major kolz$

instead_version "2.0.3";

require 'xact'
require 'format'
format.para 	= true;			-- Отступы в начале абзаца;
format.dash 	= true;			-- Замена двойного минуса на длинное тире;
format.quotes 	= true;			-- Замена " " на типографские << >>;

require 'useful'

main = room {
	nam = '...',
	dsc = nil;
	obj = {
		"paint", "block",
	},
};

paint = obj{
	nam = "Краска",
	dsc = "Вы видите {банку краски}, поверх лежит кисточка}";
	tak = [[Можно раскрашивать!]],
	var {
		amount = 14;
	},
	inv = _say "В банке осталось %amount краски",
	use = function(s, w)
		if w == "block" then
			if w.colored then
				p [[Уже окрашен. Не вижу смысла покрывать в два слоя]]; 
			else
				if s.amount >= w.area then	
					w:paint();
					s.amount = s.amount - w.area
				else
					p "Краски не хватит"
				end
			end
		end 
	end,
}

block = obj{
	nam = "_",
	dsc = "Небольшой {кубик}",
	var {
		area = 6;
		colored = false;
	},
	act = _if( "colored",
		"Покрашен синей краской",
		"Деревянный кубик, хорошо умещаться в ладони" );
}
