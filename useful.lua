-- Copyright 2015 Nikolay Konovalow
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
--| string.format позволяет выводить заданное количество знаков, преобразовывать в другие формты

function offset_( size ) 					-- Вывести отступ указанной размерности (в пикселях)
	isErr( size == nil or size < 0, "Недопустимая величина отступа: " .. (size or 'nil') );
	return img("blank:" .. size .."x1");
end

--{ Метафункции, облегчают написание кода, не описывающего непосредственно игровые конструкции
function isErr( cond, msg, lvl )			-- Лаконичная форма для отлова ошибок.   
	if cond then
		error( msg, lvl or 3 )				-- Если используете непосредственно в комнатах/объектах - передавайте '2' на месте lvl
	end
end

function unfold ( handler, returnIt )	-- Вспомогательная функция, обеспечивающая полиморфизм данных
	local t = type(handler)					-- В зависимости от типа (строка/функция), либо выводит, либо исполняет handler
	if t == "string" then
		if returnIt then
			return handler
		else
			p( handler );
		end
	elseif t == "function" then
		handler();
	else
		error( "Check data's fields! One of them is: " .. t ); 
	end
end
--}

function prnd( arg, needReturn )			-- Возвращает случайную реплику из таблицы arg
	isErr( type(arg) ~= "table", "'prnd' get table as argument" )
	return unfold( arg[ rnd(#arg) ], needReturn );
end

function _prnd( arg )
	return function()
		prnd( arg )
	end
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
		local event = data.event or function() return true end;
		unfold( react )
		unfold( event )						-- Поле event вызывается каждый раз. Можно присвоить функцию со счетчиком, к примеру
	end
end

function _visits (variants)				-- Аналог _dynout, завязанный на посещения комнаты (без def будет выход за границы)
	isErr( type(variants) ~= "table", "_visits take table as parameter" )
	return function()
		switch( visited() )( variants )
	end
end

--{ Следующие секцию я подсмотрел у vorov2
-- unfold входит в их число
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
	
	if #value == 0 then						-- Короткая форма: строка, отображаемые поля помечаются @ (пример: "Всего яблок: @count")
		isErr( string.find(phrase, "@") == nil, "Use phrase without placeholder: @<name>" )
		local start, finish;
		local txt = {};
		local var = {};
		while phrase ~= nil do
			start, finish = string.find( phrase, "@[a-zA-z]*" )

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

function vis_change ( obj )				-- Переключатель состояния объектов 
	if disabled( obj ) then
		obj:enable();
	else 
		obj:disable();
	end
end
-- vim: set tabstop=3 shiftwidth=3 columns=133
