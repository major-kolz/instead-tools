require "useful"

local function tcall(f, s)				-- wiki, "Приемы программирования", "Пример реализации фонарика" - vorov2
	if type(f) == "function" then
		return tcall(f(s), s)
	else 
		return f
	end
end

local function curr(s, isBranches)	-- Get current machine's state/branch
	local mod = isBranches and "branches" or "states"
	return s[mod][ s.current_state ];
end

local function stm_select ( machine, state, field )
	local state_holder = machine.states[state]
	isErr( state_holder == nil, "Your machine haven't state: " .. state );	-- Ошибка укажет на stm в этом файле, увы...
	isErr( type( state_holder ) ~= "table", "Your machine state '" .. state .. "' isn't table" )

	local reaction = state_holder[field]
	local def = machine.states.def or machine.states[1]
	if not reaction then														-- У состояния опущено какое-то поле 
		local parent = state_holder.extends
		if parent then																-- состояние унаследовано - проверить поле предка
			reaction = stm_select( machine, parent, field )
		else 																			-- проверить поле состояния по-умолчанию				
			reaction = def[field]
		end
	end

	return reaction
end

-- Дополнительные (и не наследуемые) свойства состояний:
-- takable				брать при первом touch
-- reflexive			use и used воспринимаются как одно и тоже (used переадресовывается)
-- iam					название состояние совпадает с отображаемым именем

stm = function(v)
	-- Prepare for construction
	-- TODO советовать что использовать взамен
	for _, field in ipairs { "disp", "dsc", "act", "take", "inv", "use", "used", "nouse", "enter", "exit", "entered", "left"} do
		isErr( type(v[field]) ~= "nil", "You shouldn't use '" .. field .. "' field in your state machine" );
	end

	isErr( type(v.states) ~= "table", "Your state machine haven't field 'states'" )
	isErr( type(v.branches) ~= "table", "Your state machine haven't field 'branches'" )
	isErr( not(v.states.def or v.states[1]), "Your state machine haven't default state. Put 'def=true' to 'states' if it correct")

	for state, _ in pairs(v.branches) do 							-- Проверка на опечатки (или неиспользуемый код)
		--- Может сработать в холостую, если мешать стиль состояния по умолчанию (явный - def - и неявный - просто {...})
		isErr( v.states[state] == nil, "Machine's branches '" .. state .. "' written with mistake (or redundant)" );
	end

	if v.states.init then												-- current_state содержит тэг текущего состояния
		stead.add_var( v, {current_state = "init"} )					
	elseif v.states.def then											-- Если не задан init, то первым состоянием будет def
		stead.add_var( v, {current_state = "def"} )				
	else 																		-- Тэг может быть и числом. '1' это тоже, что и def (не мешать!)	
		stead.add_var( v, {current_state = 1} )
	end

	-- Build state machine
	v.disp = function(s)
		local disp = stm_select(s, s.current_state, "nam")		
		if not disp then
			if curr(s).iam then											-- Отображение имени объекта может совпадать с тэгом состояния
				disp = s.current_state 
			else 																-- Сокращенная форма, без присваивания в nam
				disp = stm_select(s, s.current_state, 1)
			end
		end

		return tcall( disp )												-- В случае disp==nil (безымянное состояния), используем v.nam
	end
	v.dsc = function(s)
		local dsc = stm_select(s, s.current_state, "dsc")
		return tcall( dsc )
	end
	v.act = function(s)
		local act = stm_select(s, s.current_state, "touch")	-- touch покрывает act, inv и tak классического API
		local jumpTo = curr(s, true).taked
		jumpTo = tcall(jumpTo, s)
		if curr(s).takable == true then								-- Свойство takable не наследуется!  
			take(s)
		end

		if jumpTo and have(s) then
			s.current_state = jumpTo
		end 

		return tcall(act) 
	end
	v.inv = function(s)
		local inv = stm_select(s, s.current_state, "touch");
		local jumpTo = curr(s, true).check
		jumpTo = tcall(jumpTo, s)

		if jumpTo then
			s.current_state = jumpTo
		end

		return tcall(inv, s)
	end
	v.use = function(s, w)												
		local use = stm_select(s, s.current_state, "use");
		local jumpTo = curr(s, true).use
		jumpTo = tcall(jumpTo, s)
		if jumpTo then
			s.current_state = jumpTo
		end

		return tcall(use, w)
	end
	v.used = function(s, w)
		if curr(s).reflexive then
			return s:use(w);
		end
	
		local used = stm_select(s, s.current_state, "used");
		return tcall(used, w);
	end

	return obj(v)
end
