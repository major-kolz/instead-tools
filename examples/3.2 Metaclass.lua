-- Copyright 2014 Nikolay Konovalow
-- Licensed under the Apache License, Version 2.0 <LICENSE-APACHE or
-- http://www.apache.org/licenses/LICENSE-2.0>

--$Version: 0.1
--$Author: major kolz$

instead_version "2.0.3";

require 'xact'
require 'format'
format.para 	= true;			-- Отступы в начале абзаца;
format.dash 	= true;			-- Замена двойного минуса на длинное тире;
format.quotes 	= true;			-- Замена " " на типографские << >>;

require 'useful'
require 'metaclass'
require "dbg"

main = room {
	nam = '...',
	dsc = nil;
	obj = {
		"paint", "block", "blockT";
	},
};

paint = obj{
	nam = "Краска",
	dsc = "Вы видите {банку краски}, поверх лежит кисточка.";
	tak = [[Можно раскрашивать!]],
	var {
		amount = 14;
	},
	inv = _say "С внутренне стороны банке есть шкала. Сейчас уровень краски на отметке @amount",
	use = function(s, w)
		if isEq( block, w ) then
			if w.colored then
				p [[Уже окрашен. Не вижу смысла покрывать в два слоя]]; 
			else
				if s.amount >= w.area then	
					s.amount = s.amount - w.area
					w.colored = true
					p "Покрашено"
				else
					p "Краски не хватит"
				end
			end
		end 
	end,
}

block = metaclass {
	nam = "block",
	dsc = "Небольшой {кубик}",
	var {
		area = 6;
		colored = false;
	},
	act = _if( "colored",
		"Покрашен синей краской",
		"Деревянный кубик, хорошо умещаться в ладони" );
}

blockT = extends(block) {
	nam = [[_]],
	dsc = "Большой {кубик}",
}
