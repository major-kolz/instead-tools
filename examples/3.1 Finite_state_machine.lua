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
		"pistole", "magazine", "aim";
	},
};

pistole = stm {
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
		
		def = { bind = "magazine" },
		["На столе"] = { "Пистолет", dsc = "На столе лежит {пистолет}.", touch = "Макаров...", takable = true },
		["Снаряженный"] = { 
			"Пистолет",
			touch = "Я извлек магазин", 
			use = "Peow" 
		},
		["Пустой, взведенный"] = { 
			extends = "Снаряженный", 
			use = "Пистолет глухо щелкнул: патронник пуст и боек отработал в холостую";
		},
		["Пустой"] = { 
			nam = "Разряженный пистолет", touch = "Я извлек магазин", 
			use = "Боек глухо клацнул, не обнаружив патрон в патроннике." 
		},
		["Пистолет без магазина"] = { 
			iam = true, 
			touch = "Если пустующий теперь слот развернуть к свету, то можно разглядеть анодированные детали экстрактора",
			use = "Боек глухо клацнул, не обнаружив патрон в патроннике."
		};
		["Патрон в патроннике"] = { extends = "Пистолет без магазина", use = "peow" },
	},
	branches = { 		-- Обработчики переходов состояния. Если возвращена строка - это название нового состояния. Переход может быть безусловным (тогда прямо присваиваем строку обработчику)
		init = { touch = function(s) if s.may then take(s); return "Пистолет без магазина" end end },
		def = {},

		["На столе"] = { taked = stmPrev "Пистолет без магазина"; },
		["Снаряженный"] = {
			touch = function(s)
				if magazine.charge == 0 then
					return "Пистолет без магазина"
				else
					return "Патрон в патроннике"
				end
			end,
			use = function(s, w)
				if w == aim then
					if magazine.charge == 0 then 
						return "Пустой"
					else
						magazine.charge = magazine.charge - 1;
					end
				end
			end,
		},
		["Пистолет без магазина"] = {
			used = function(s, w)
				if w == magazine then
					if w.charge == 0 then
						return "Пустой, взведенный" 
					else 
						magazine.charge = magazine.charge - 1;
						return "Снаряженный"
					end
				end
			end;
		},
		["Патрон в патроннике"] = {
			extends = "Пистолет без магазине",
			use = function(s, w)
				if w == aim then
					return "Пистолет без магазина"
				end
			end,
		},
		["Пустой"] = {
			extends = "Снаряженный",
		},
		["Пустой, взведенный"] = {
			extends = "Патрон в патроннике",
		},
	},
}

magazine = stm {
	nam = "Магазин",
	var {
		charge = 4;
	},
	states = {
		init = "out";

		def = { "Магазин", },
		inhand = {
			touch = _say("Патронов в магазине: %d", "charge"), 
			use = function(s, w)
				if w == pistole then
					if w.current_state == "Патрон в патроннике" then
						p "Вставляю обойму в пистолет" 
					else
						p "Вставляю обойму и передергиваю затвор"
					end
				end
			end,
		},
		out = { dsc = [[На столе лежит {магазин}.]], takable = true;  },
		empty = {},
	},
	branches = {
		out = {
			taked = "inhand";
		},
		inhand = {
			use = function(s, w)
				if w == pistole then
					disable(s); 
					if s.charge == 0 then return "empty";
					else	return "def" end
				end
			end,
		};
		def = {
			call = function(s, w)
				if w == pistole then
					enable(s)
					return "inhand"
				end 
			end,
		};
	};
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
