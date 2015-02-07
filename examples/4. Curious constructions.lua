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

-- Написано с адаптации на INSTEAD Вадимом Балашовым игры werewolf'а "City of Mist"
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
--====================| Интерактивный пример |====================-- 
main = room {
	nam = "...";
	obj = {
		"radio", "box"
	},
};

radio = obj{
	nam = "_",
	dsc = [[Можно послушать {радио}.]],
	act = function()
		combprnd{
			"Полным ходом идет добыча мифрила с астероида Мория-3",
			"Экономисты прогнозируют повышение цен в секторе частной гидропоники",
			""; 
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
