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

require"useful"					-- набор полезных функций
require "state_machine"			-- файл state_machine.lua должен находиться в папке игры или в <instead>/stead/

main = room {
	nam =  'Мастерская',
	dsc =  "Тестовая комната для испытания конечных автоматов.";
	obj = {
		"power_drill";
	},
};

--=== stm - [finite] state machine, конечный автомат - функция для построения интерактивных объектов
-- Синтаксис: 
-- *	<идентификатор> = stm{ 
-- *		nam = "stm_name",									-- Имя машине давать не обязательно, эту строчку можно опустить
-- *		var{ <перечень сохраняемых переменных> },	-- В случае необходимости 
-- *		states = { <перечень состояний> }, 
-- *		branches = { <перечень переходов> },
-- *	}
--=== states представляет собой таблицу состояний объекта.
-- Синтаксис состояния:
-- &	<тэг состояния> = {
-- &		"<Отображаемое имя состояния>", 			-- короткая форма для задания nam
-- &		iam = true,										-- отображаемое имя совпадает с тэгом состояния
-- &		reflexive = true,								-- use и used воспринимаются как одно и тоже (used переадресовывается)
-- &		takable = true,								-- брать при первом touch (не наследуется)
-- &		extends = "<имя предка>",					-- если одно из полей nam, dsc, touch, use/ed не определено, вызывать соответствующее поле у состояния-предка
-- &		bind = "<идентификатор связанной stm>"	-- При каждом взаимодействии с этой stm будет вызываться поле call связанной 
-- &
-- &		nam = <имя>,									-- имя в инвентаре, если конечный автомат в этом состоянии
-- &		dsc = <описание>,								
-- &		touch = <реакция на воздействие игроком>,	-- покрывает act и inv классического API
-- &		use = <реакция на применение>,
-- &		used = <реакция на воздействие объектом>,
-- &		call = <реакция на воздействие на сопряженную stm>,
-- &	},
-- Если тэг - комбинация слов или текст кириллицей - то он записывается в виде ["тэг"]. Латиницей можно и без скобок с кавычками
-- тэги init и def зарезервированы под служебные состояния. def является предком все остальных состояний, init - начальное состояние stm. Может быть строкой тэгом состояния, выбранного за начальное. Если init не задан - начальным состоянием будет def
--=== branches задается таблицей условных переходов
-- Синтаксис условного перехода:
-- #	<идентификатор> = { 								-- каждый условный переход должен иметь состояние с таким же идентификатором
-- #		

power_drill = stm{
	states = {
		init = "На столе",
		def = {},

		["На столе"] = { 									-- можно сгенерировать состояние с помощью функции stmTak
			nam = "Дрель", dsc = [[На столе лежит {дрель}]], 
		},
	},
	branches = {
	},
}

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
