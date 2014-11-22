-- Copyright 2014 Nikolay Konovalow
-- Licensed under the Apache License, Version 2.0 <LICENSE-APACHE or
-- http://www.apache.org/licenses/LICENSE-2.0>

--$Name: Пример 3.1 Конечный автомат$
--$Version: 0.1$
--$Author: Николай Коновалов$

instead_version "1.9.1";

require 'xact'
require 'format'
format.para 	= true;			-- Отступы в начале абзаца;
format.dash 	= true;			-- Замена двойного минуса на длинное тире;
format.quotes 	= true;			-- Замена " " на типографские << >>;

require "useful"
require "state_machine"

main = room {
	nam =  '...',
	dsc =  "Тестовая комната";
	obj = {
		"assault_rifle", "aim";
	},
};

assault_rifle = stm {
	nam = "Пистоль";
	var { 
		may 		= true,			-- типо стрельбище, нужно получить разрешение инструктора
		charge 	= 4;
	},
	states = {
		init = { 
			dsc = "На столе лежит кобура с {пистолетом}.", 
			touch = _if( "may", "\"Оружие в руки! К занятию - приступить!\"",
				"Брать оружие без команды инструктора запрещено.");
		},
		
		def = {},
		["На столе"] = { "Пистолет", dsc = "На столе лежит {пистолет}.", touch = "Макаров...", takable = true },
		["В руках"] = { iam = true, use = "Peow" },
		["Пустой"] = { nam = "Разряженный пистолет", touch ="Я прямо по весу чувствую, что пуст" }; 
	},
	branches = { 		-- Обработчики переходов состояния. Если возвращена строка - это название нового состояния. Переход может быть безусловным (тогда прямо присваиваем строку обработчику)
		init = { touch = function(s) if s.may then take(s); return "В руках" end end },

		["На столе"] = { taked = stmPrev "В руках"; },
		["В руках"] = {
			use = function(s, w)
				if w == aim then
					magazine.charge = magazine.charge - 1;
					if magazine.charge == 0 then return "Пустой" end
				end
			end,
		},
		["Без магазина"] = {
			used = function(s, w)
				if w == magazine then
					return s.stm_prevState
				end
			end;
		}
	},
}

magazine = stm {
	nam = "Магазин",
	var {
		charge = 4
	states = {
		empthy = {},
		def = {"Пистолетный магазин", touch = _say("В магазин: %d патронов", "charge"),  }
		full = {},
	}
}

aim = obj{
	nam = "Мишень",
	_firstSign = true;
	dsc = _if( "_firstSign", 
		"Впереди, метрах в сорока, находятся пустые остовы {мишеней}.",
		"Впереди маячит {мишень}." );
	act = _trig( "_firstSign",
		"Какой-то солдат прошел и развесил, начиная с левого краю, свежие бумажки и мишенями",
		"Ни черта не видно" ); 
};
