--====================| Набор полезных функций |====================--
-- Отображение документа: 
-- 	табуляция = 3 пробела, 133 символа в строке 
-- Соглашение о именовании:
-- 	нижнее подчеркивание в конце имени	= возвращается значение
-- 	нижнее подчеркивание в начале имени = возвращается функция 
-- 	отсутствие подчеркивание 				= процедура (ничего не возвращает)
-- Автор:
-- 	Николай Коновалов aka major kolz

--| ret = state and <exp1> or <exp2>  Если state истинно, то ret получит <exp1> иначе <exp2>. Из Programming on Lua 2ed, Ierusalimschy
--| В строку темы default помещается 84 символа: 82 знака '*' и 2 '|'

function offset_ (size) 					-- Вывести отступ указанной размерности (в пикселях)
	assert( size ~= nil and size > 0, "Недопустимая величина отступа: " .. size );
	return img("blank:" .. size .."x1");
end

function prnd_ (var)							-- Возвращает случайную реплику из набора var	
	return var[ rnd(#var) ];
end

function prnd (var)
	p (var[ rnd(#var) ]);
end

function floor_ (num, round_to)			-- Возвращает num с точностью до round_to знака после запятой (TODO через string.format) 
	return ( num - num%(0.1^round_to) );
end

function phx_ (num)							-- Вывести num в шестнадцатеричном представлении 
	return string.format("%x", num);	
end

function CaptainObviously_ (s)			-- Возвращает имя или описание объекта s					
	local who = s.disp or s.nam;
	local t = type(who); 
	if t == "string" then
		return who;
	elseif t == "function" then
		return who();
	end
end

function _dynout (vis_desc)				-- Динамическое описание сцены по совету v.v.b; вызывая, по очереди выведем весь vis_desc
	local visit = 0;							-- После выхода из игры вывод пойдет сначала
	return function ()
		if visit ~= #vis_desc then
			visit = visit + 1;
		end
		return vis_desc[visit];	
	end
end

function switch (condition)				-- Оператор выбора для условия condition
	return function(data)					-- data может иметь поле def: на случай недопустимых значений condition 
		assert( type(data) == "table", "Switch data should be table. Got: " .. type(data) );

		local react = data[condition] or data.def or function() return true end;
		local t = type( react );
	
		if t == "string" then
			p (react);
		elseif t == "function" then
			react();
		else
			error ("Check data fields! One of them is: " .. t, 2 ); 
		end	
	end
end

--{ Следующие секцию я подсмотрел у vorov2
function sound (nam, chanel)				
	set_sound("snd/" .. nam .. ".ogg", chanel);
end

function music (nam)							
	set_music("mus/" .. nam .. ".ogg");	
end 

function image_ (nam)						
	return 'img/' .. nam .. '.png';	
end

function _if ( cond, posact, negact )		-- Сокращение на случай, если обработчик имеет два состояния и возвращает текст
	return function(s)							-- cond - строка с именем управляющей переменной (из этого объекта/комнаты)
		if s[cond] then
			p( posact );
		else
			p( negact );
		end
	end
end

function _trig ( cond, posact, negact )	-- Для двухступенчатых событий. Первый раз выполняется posact, все остальные - negact 
	return function(s)							-- Пример использования: объекты с вводным(расширенным) и игровым описаниями 
		if s[cond] then
			p( posact );
			s[cond] = false;
		else
			p( negact );
		end
	end
end
--}

-- vim: set tabstop=3 shiftwidth=3 columns=133
