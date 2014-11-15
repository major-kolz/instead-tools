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

<<<<<<< HEAD
--| Чтобы можно было писать require "<clasnam>" и не копировать <clasnam>.lua в папку с проектом 
stead.package.path = stead.package.path .. ";../instead-tools/classes/?.lua" 

=======
>>>>>>> 1141b5227d56832921c6c0158084589ae9f6d258
function isErr( cond, msg, lvl )			-- Лаконичная форма для отлова ошибок.   
	if cond then								-- Если используете непосредственно в комнатах/объектах - передавайте '2' на месте lvl
		error( msg, lvl or 3 )
	end
end

function offset_ (size) 					-- Вывести отступ указанной размерности (в пикселях)
	isErr( size == nil or size < 0, "Недопустимая величина отступа: " .. (size or 'nil') );
	return img("blank:" .. size .."x1");
end

function prnd_ (var)							-- Возвращает случайную реплику из набора var	
	return var[ rnd(#var) ];
end

function prnd (var)
	p (var[ rnd(#var) ]);
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
		return vis_desc[visit];	
	end
end

function switch (condition)				-- Оператор выбора для условия condition
	return function(data)					-- data может иметь поле def: на случай недопустимых значений condition 
		isErr( type(data) ~= "table", "Switch data should be table. Got: " .. type(data) );

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

function _if ( cond, pos, neg )			-- Сокращение на случай, если обработчик имеет два состояния и возвращает текст
	return function(s)						-- cond - строка с именем управляющей переменной (из этого объекта/комнаты)
		if s[cond] then
			p( pos );
		else
			p( neg );
		end
	end
end

function _trig ( cond, pos, neg )		-- Для двухступенчатых событий. Первый раз выполняется posact, все остальные - negact 
	return function(s)						-- Пример использования: объекты с вводным(расширенным) и игровым описаниями 
		if s[cond] then
			p( pos );
			s[cond] = false;
		else
			p( neg );
		end
	end
end
--}

-- vim: set tabstop=3 shiftwidth=3 columns=133
