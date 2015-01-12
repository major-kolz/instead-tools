-- Copyright 2014 Nikolay Konovalow
-- Licensed under the Apache License, Version 2.0 <LICENSE-APACHE or
-- http://www.apache.org/licenses/LICENSE-2.0>


--====================| Набор полезных функций |====================--
-- Отображение документа: 
-- 	табуляция = 3 пробела, 133 символа в строке 
-- Соглашение о именовании:
-- 	нижнее подчеркивание в конце имени	= возвращается значение
-- 	нижнее подчеркивание в начале имени = возвращается функция 
-- 	отсутствие подчеркивание 				= процедура (ничего не возвращает)
	

--| ret = state and <exp1> or <exp2>  Если state истинно, то ret получит <exp1> иначе <exp2>. Из Programming on Lua 2ed, Ierusalimschy
--| В строку темы default помещается 84 символа: 82 знака '*' и 2 '|'

function isErr( cond, msg, lvl )			-- Лаконичная форма для отлова ошибок.   
	if cond then								-- Если используете непосредственно в комнатах/объектах - передавайте '2' на месте lvl
		error( msg, lvl or 3 )
	end
end

function offset_( size ) 					-- Вывести отступ указанной размерности (в пикселях)
	isErr( size == nil or size < 0, "Недопустимая величина отступа: " .. (size or 'nil') );
	return img("blank:" .. size .."x1");
end

function prnd( arg )							-- Возвращает случайную реплику из таблицы arg
	isErr( type(arg) ~= "table", "'prnd' get table as argument" )
	unfold( arg[ rnd(#arg) ] );
end

function floor_ (num, round_to)			-- Возвращает num с точностью до round_to знака после запятой 
	return string.format("%." .. round_to .. "f", num);
end

function phx_ (num)							-- Вывести num в шестнадцатеричном представлении 
	return string.format("%X", num);	
end

function _dynout (vis_desc)				-- Динамическое описание сцены по совету v.v.b; вызывая, по очереди выведем весь vis_desc
	local visit = 0;							-- После выхода из игры вывод пойдет сначала
	isErr( type(vis_desc) ~= "table", "_dynout take table as parameter")

	return function ()
		if visit ~= #vis_desc then
			visit = visit + 1;
		end
		return unfold( vis_desc[visit] );	
	end
end

function switch (condition)				-- Оператор выбора для условия condition
	return function(data)					-- data может иметь поле def: на случай недопустимых значений condition 
		isErr( type(data) ~= "table", "Switch data should be table. Got: " .. type(data) );

		local react = data[condition] or data.def or function() return true end;
		unfold( react )
	end
end

--{ Следующие секцию я подсмотрел у vorov2
function unfold ( handler, mayTable )	-- Вспомогательная функция, обеспечивающая полиморфизм данных
	local t = type(handler)					-- В зависимости от типа (строка/функция), либо выводит, либо исполняет handler
	if t == "string" then
		p( handler );
	elseif t == "function" then
		handler();
	elseif t == "table" and mayTable then -- Если передать вторым параметром true, то будет "проигрывать" таблицы
		for _, val in ipairs(handler) do
			unfold( handler )
		end
	else
		error ("Check data's fields! One of them is: " .. t, ); 
	end
end
function sound (nam, chanel)				
	set_sound("snd/" .. nam .. ".ogg", chanel);
end

function music (nam)							
	set_music("mus/" .. nam .. ".ogg");	
end 

function image_ (nam)						
	return 'img/' .. nam .. '.png';	
end

function _if ( cond, pos, neg )			-- Сокращение на случай, если обработчик имеет два состояния и возвращает текст
	return function(s)						-- cond - строка с именем управляющей переменной (из этого объекта/комнаты)
		if s[cond] then
			unfold( pos );
		else
			unfold( neg );
		end
	end
end

function _trig ( cond, pos, neg )		-- Для двухступенчатых событий. Первый раз выполняется posact, все остальные - negact 
	return function(s)						-- Пример использования: объекты с вводным(расширенным) и игровым описаниями 
		if s[cond] then
			unfold( pos );
			s[cond] = false;
		else
			unfold( neg );
		end
	end
end
--}

function _say ( phrase, ... )				-- Создание обработчика-индикатора (показывают value-поле[/поля] данного объекта)
	-- Рекомендую для act/inv - отображать внутренние счетчики в одну строчку
	local value = {...}
	local react;				
	
	if value == nil then						-- Короткая форма: строка, отображаемые поля помечаются @ (пример: "Кокосов: @count")
		local start, finish;
		local txt = {};
		local var = {};
		while phr ~= nil do
			start, finish= string.find( phrase, "@[a-zA-z]*" )

			if start == nil or finish == nil then break end

			table.insert( txt, string.sub( phrase, 1, start-1 ));
			table.insert( var, string.sub( phrase, start+1, finish )); 
			phrase = string.sub( phrase, finish+1 )
		end
		react = function( s )
			local handler = ""

			for i = 1, #var do handler = handler .. txt[i] .. s[var[i]]	end

			if #txt == #var then p( handler );
			else                 p( handler .. txt[#txt] )	end
		end
	elseif #value > 0 then				-- Расширенная форма с заполнителями в С-стиле %<...> 
		for _, v in ipairs( value ) do isErr( type(v) ~= "string", "Value may be string or table of strings" ) end
		react = function( s )						
			local open_values = {}
			for _, v in ipairs( value ) do table.insert( open_values, s[v] ) end 
			p( string.format(phrase, stead.unpack(open_values)) )
		end
	else
		error( "Check '_say' second argument's: it should be string and (optional) fields' name (strings too)", 2 )
	end

	return react 	
end
-- vim: set tabstop=3 shiftwidth=3 columns=133
