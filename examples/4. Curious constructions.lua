-- Copyright 2014 Nikolay Konovalow
-- Licensed under the Apache License, Version 2.0 <LICENSE-APACHE or
-- http://www.apache.org/licenses/LICENSE-2.0>

instead_version "2.0.3";

require 'xact'
require 'format'
format.para 	= true;			-- Отступы в начале абзаца;
format.dash 	= true;			-- Замена двойного минуса на длинное тире;
format.quotes 	= true;			-- Замена " " на типографские << >>;

--====================| Код |====================-- 
require 'useful'					-- Набор полезных функций

-- Написано с ремайка на INSTEAD Вадимом Балашовым игры werewolf'а "City of Mist"
-- Генерирует текст по заданному шаблону (template), подставляя на место заполнителей случайные строки из phrases и mimics
function combprnd( phrases, template )
	if not template then
		template = "«%s» – %s."
	end

	return function( mimics )
		local phr, mim = prnd(phrases, true), prnd(mimics, true)
		p( string.format( template, phr, mim ) )
	end
end 

-- Для act и inv: в первый раз выводиться first (описание, к примеру), далее выбирается случайно из набора (реакция, скажем)
function	_lookprnd( phrases )
	local check = false
	return function()
		if not check then
			check = true
			p( phrases.first )
		else
			prnd( phrases )
		end
	end
end

-- Для обработчиков входа-выхода и use/used
function _select( variance )
	isErr( type(variance) ~= "table", "Argument of '_select' should be table" )	
	if not variance.react then	variance.react = p 	end		-- можно и walk передать, и prnd

	return function( _, arg )
		local impact = variance[ deref(arg) ]
		if impact then
			variance.react( impact )
		end
	end
end

--====================| Интерактивный пример |====================-- 
main = room {
	nam = "...";
	left = _select {
		room1 = "Можно полюбоваться на ворон, что так любят рассесться у соседа на ели",
		room2 = "Мне все не дает покоя мысль скрестить топку и элементы Пельтье",
		room3 = "Квадракоптер, по щелчку подающий планшет - с которого можно включить свет на кухне...";
	},
	obj = {
		"radio", "box"
	},
	way = {
		"room1", "room2", "room3";
	},
};

radio = obj{
	nam = "_",
	dsc = [[Можно послушать {радио}.]],
	act = function()
		combprnd{
			"Полным ходом идет добыча мифрила с астероида Мория-3",
			"Экономисты прогнозируют повышение цен в секторе частной гидропоники",
			"Превалирующим число голосов Трибунат отклонил прошение о признании высше-верхнего сословия"
			}{
			"звучит из динамиков",
			"зачитывает диктор",
			"пробилось сквозь помехи";
		}
	end
};

box = obj{
	nam = "_",
	dsc = "Или таки дочитать {книгу}.",
	act = _lookprnd {
		first = [["Квантовые вычисления и функциональное программирование"]],
		"О! Иллюстрации",
		"И примеры есть. Интересно, что за язык... Где-то в начале было...",
		"В условии делить с присваиванием?! А, это отрицание такое...";
	},
}

room1 = room{
	nam = "Пост наблюдения",
	dsc = nil,
	way = {
		vroom("Назад", 'main'),
	},
	obj = {
		'monitors', 'ring';	-- объекты для демонстрации _select в качестве обработчика в used
	}
};

room2 = room{
	nam = "У камина",
	dsc = nil,
	way = {
		vroom("Назад", 'main'),
	},
};

room3 = room{
	nam = "Сижу в кресле",
	disp = function(s)
		if here() == s then
			return "В кресле"
		else
			return "В кресло"
		end
	end,
	dsc = nil,
	way = {
		vroom("Назад", 'main'),
	},
};
