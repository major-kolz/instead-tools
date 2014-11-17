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
		{ "Пистолет", dsc = "На столе лежит {пистолет}.", touch = "Макаров...", takable = true },
		["В руках"] = { iam = true, touch = _say("Я проверил магазин: %d", "charge"), use = "Peow" },
		["Пустой"] = { nam = "Разряженный пистолет", touch ="Я прямо по весу чувствую, что пуст" }; 
	},
	branches = { 		-- Обработчики переходов состояния. Если возвращена строка - это название нового состояния. Переход может быть безусловным (тогда прямо присваиваем строку обработчику)
		{
			taked = function(s) if s.may then return "В руках" end end,
		},
		["В руках"] = {
			use = function(s) 
				s.charge = s.charge - 1;
				if s.charge == 0 then return "Пустой" end
			end,
		},
	},
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
