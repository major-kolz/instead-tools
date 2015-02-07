-- Модуль для последовательной подачи текста cutscene, модернизированный  
-- Основа: http://instead.syscall.ru/wiki/ru/gamedev/modules/cutscene, автор: Пётр Косых	
--
-- Отличия от основной версии: 
--		тэги теперь облекаются в квадратные скобки, а не в фигурные (можно вставлять в текст xact)
--		Внешний вид [cut] "по-умолчанию" теперь определяется полем _cutDefTxt (">>>"). 
--		[cut] теперь предварен _cutPrefix (по-умолчанию: "^^" - кнопка выводится через пустую строку)  
--		Добавлен тэг [upd], что эквивалентен прошлому {cut}{cls}. 
--		[upd] вызывает метод update() комнаты-cutscene
--		Удален cls (upd покрывает функциональность)
--		Можно использовать left
-- https://github.com/major-kolz/instead-tools/blob/master/cutscene.lua
-- v1.2 by major kolz

require "timer"
require "xact"

local function get_token(txt, pos)
	pos = tonumber(pos) or 1;
	local s, e;
	e = pos
	while true do
		s, e = txt:find("[\\%[]", e);
		if not s then
			break
		end
		if txt:sub(s, s) == '\\' then
			e = e + 2
		else
			break
		end
	end
	local nest = 1
	local ss, ee
	ee = e
	while s do
		ss, ee = txt:find("[\\%[%]]", ee + 1);
		if ss then
			if txt:sub(ss, ss) == '\\' then
				ee = ee + 1
			elseif txt:sub(ss, ss) == '%]' then
				nest = nest + 1
			else
				nest = nest - 1
			end
			if nest == 0 then
				return s, ee
			end
		else
			break
		end
	end
	return nil
end

local function parse_token(txt)
	local s, e, t
	t = txt:sub(2, -2)
	local c = t:gsub("^([a-zA-Z]+)[ \t]*.*$", "%1");
	local a = t:gsub("^[^ \t]+[ \t]*(.*)$", "%1");
	if a then a = a:gsub("[ \t]+$", "") end
	return c, a
end

cutscene = function(v)
	v.txt = v.dsc
	v.forcedsc = true
	v._cutPrefix = v._cutPrefix or "^^";			-- предварять cut-кнопку пустой строкой
	v._cutDefTxt = v._cutDefTxt or ">>>";			-- определим внешний вид cut-кнопки (наверное, можно и картинку через img ) 
	v._readFrom = 1;										-- счетчик для не отображаемой (просмотренной) части

	v.update = v.update or function() return false end;
	v.left_react = "";
	if v.left then
		v.left_react = v.left	
	end

	v.left = function(s)
		timer:set(s._timer);
		s:reset()
		local t = type( s.left_react );
		if t == "string" then
			p( s.left_react );
		elseif t == "function" then
			s:left_react();
		else
			error("Illegal 'left' handler! Type is: " .. t )
		end
	end;

	if v.timer then
		error ("Do not use timer in cutscene.", 2)
	end

	v.timer = function(s)
		s._fading = nil
		s._state = s._state + 1
		timer:stop()
		s:step()
		return true
	end;

	if not v.pic then
		v.pic = function(s)
			return s._pic
		end;
	end

	if not v.fading then
		v.fading = function(s)
			return s._fading
		end
	end

	v.reset = function(s)
		s._state = 1
		s._code = 1
		s._fading = nil
		s._txt = nil
		s._dsc = nil
		s._pic = nil
	end

	v:reset()

	if v.entered then
		error ("Do not use entered in cutscene.", 2)
	end

	v.entered = function(self)
		self:reset()
		self._timer = timer:get()
		self:step();
	end;

	v.step = function(self)
		local s, e, c, a 					-- search start, search end, command descriptor, command argument
		local n = v._state
		local txt = ''
		local code = 0
		local out = ''

		if not self._txt then
			if type(self.txt) == 'table' then
				local k,v 
				for k,v in ipairs(self.txt) do
					if type(v) == 'function' then
						v = v()
					end
					txt = txt .. tostring(v)
				end
			else
				txt = stead.call(self, 'txt')
			end
			self._txt = txt
		else
			txt = self._txt
		end
		while n > 0 and txt do
			if not e then
				e = self._readFrom
			end
			local oe = e
			s, e = get_token(txt, e)
			if not s then
				c = nil
				out = out..txt:sub(oe)
				break
			end
			local strip = true
			c, a = parse_token(txt:sub(s, e))
			if c == "pause" or c == "fading" then
				n = n - 1
			elseif c == "cut" or c == "upd" then
				n = n - 1
				out = out .. "^"
			elseif c == "pic" then
				self._pic = a
			elseif c == "code" then
				code = code + 1
				if code >= self._code then
					local f = stead.eval(a)
					if not f then
						error ("Wrong expression in cutscene: "..tostring(a))
					end
					self._code = self._code + 1
					f()
				end
			elseif c == "walk" then
				if a and a ~= "" then
					return stead.walk(a)
				end
				strip = false
			else
				error( "Illegal command: " .. c );
			end

			if strip then
				out = out..txt:sub(oe, s - 1)
			elseif c then
				out = out..txt:sub(oe, e)
			else
				out = put..txt:sub(oe)
			end
			e = e + 1
		end
		v._dsc = out
		if c == 'pause' then
			if not a or a == "" then
				a = 1000
			end
			timer:set(tonumber(a))
		elseif c == 'cut' then
			self._state = self._state + 1
			if not a or a == "" then
				a = v._cutDefTxt
			end
			v._dsc = v._dsc .. v._cutPrefix .. "{cut|"..a.."}";
		elseif c == 'upd' then
			self._state = 1
			if not a or a == "" then
				a = v._cutDefTxt
			end
			v._dsc = v._dsc .. v._cutPrefix .. "{upd(" .. e .. ")|"..a.."}";
		elseif c == "fading" then
			if not a or a == "" then
				a = game.gui.fading
			end
			self._fading = tonumber(a)
			timer:set(10)
		end
	end
	v.dsc = function(s)
		if s._dsc then
			return s._dsc
		end
	end
	if not v.obj then
		v.obj = {}
	end
	stead.table.insert(v.obj, 1, xact('cut', function() here():step(); return true; end ))
	stead.table.insert(v.obj, 2, xact('upd', function() 
			here():update();
			here()._readFrom = tonumber(arg1);
			here():step(); 
			return true; end )
	)
	return room(v)
end
