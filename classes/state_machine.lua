function stm ( v )
	-- Prepare for construction
	for _, field in ipairs { "desc", "dsc", "act", "take", "inv", "use", "used", "nouse", "enter", "exit", "entered", "left"} do
		isErr( type(v[field]) ~= "nil", "You shouldn't use '" .. field .. "' field in your state machine" );
	end

	isErr( type(v.states) ~= "table", "Your state machine haven't field 'states'" )
	isErr( type(v.branches) ~= "table", "Your state machine haven't field 'branches'" )
	isErr( not(v.states.def or v.states[1]), "Your state machine haven't default state. Put 'def=true' to 'states' if it correct")

	if v.states.init then														-- current_state содержит тэг текущего состояния
		stead.add_var( v, {current_state = "init"} )
	elseif v.states.def then
		stead.add_var( v, {current_state = "def"} )						-- тэг может быть и числом. 1 зарезервировано за def
	else
		stead.add_var( v, {current_state = 1} )
	end

	-- State machine
	v.disp = function(s)
		local disp = stm_select(s, s.current_state, "nam")				
		if not disp then
			if s.states[s.current_state].iam then
				disp = s.current_state											-- Отображение имени объекта может совпадать с тэгом состояния 
			else
				disp = stm_select(s, s.current_state, 1)					-- Сокращенная форма, без присваивания в nam
			end
		end

		return tcall( disp )
	end
	v.dsc = function(s)
		local dsc = stm_select(s, s.current_state, "dsc")
		return tcall( dsc )
	end
	v.act = function(s)
		local act = stm_select(s, s.current_state, "touch");			-- touch покрывает act, inv и tak классического API
		local jumpTo = s.branches[s.current_state].taked
		jumpTo = tcall(jumpTo, s)
		if s.states[s.current_state].takable == true then				-- Свойство takable не наследуется!  
			take(s)
		end

		if jumpTo and have(s) then
			s.current_state = jumpTo
		end 

		return tcall(act) 			
	end
	v.inv = function(s)
		local inv = stm_select(s, s.current_state, "touch");
		return tcall(inv)
	end

	return obj(v)
end

function stm_select ( machine, current_state, field, mode )
	mode = mode or "states"														-- Параметр со значением по-умолчанию
	isErr( type( machine[mode][current_state] ) ~= "table", "Your machine haven't state: " .. current_state )

	local reaction = machine[mode][current_state][field]
	local def = machine[mode].def or machine[mode][1]
	if not reaction then															-- У состояния опущено какое-то поле 
		local parent = machine[mode][current_state].extends
		if parent then																	-- состояние унаследовано - проверить поле предка
			reaction = machine[mode][parent].field			
			if not reaction then														-- и тут нет - спуститься по фамильному древу 	
				reaction = stm_select( machine, parent, field, mode )
			end
		else 																							
			reaction = def[field]
		end
	end

	return reaction
end

function tcall(f, s)				-- wiki, "Приемы программирования", "Пример реализации фонарика" - vorov2
	if type(f) == "function" then
		return tcall(f(s), s)
	else 
		return f
	end
end
