-- Copyright 2014 Nikolay Konovalow
-- Licensed under the Apache License, Version 2.0 <LICENSE-APACHE or
-- http://www.apache.org/licenses/LICENSE-2.0>

require "useful"

local function tcall(f, ...)						-- wiki, "Приемы программирования", "Пример реализации фонарика" - vorov2
	if type(f) == "function" then
		return tcall(f(...), ...)
	else 
		return f
	end
end

local function curr(s, isBranches)										-- Get current machine's state/branch
	local mod = isBranches and "branches" or "states"
	return s[mod][ s.current_state ] or {};
end

local function stm_select ( machine, state, field )
	if field == "nam" or field == 1 then
		isErr( machine.states[state] == nil, "State '" .. state .. "' doesn't exist (".. machine.nam ..")" )
		if machine.states[state].iam then							-- Отображаемое имя объекта может совпадать с тэгом состояния
			return state;
		end
	end
	
	local state_holder = machine.states[state]
	isErr( state_holder == nil, 										-- Ошибка укажет на stm в этом файле, увы...
			"Your machine ('".. machine.nam .."') haven't state: " .. state 
			);
	isErr( type( state_holder ) ~= "table", "Your machine's state '" .. state .. "' isn't table" )
	
	local reaction = state_holder[field]
	local def = machine.states.def
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

function stmPrev( initial_branch )										-- Безусловный обработчик перехода назад
	return function( machine )												-- Если требуется переход при выполнении условия.
		if machine.stm_prevState then											-- то лучше писать обработчик самому
			return machine.stm_prevState										-- Прошлое значение вызывается этой строкой
		else
			isErr( initial_branch == nil, "This state machine haven't previous state! For avoid it specify 'stmPrev(<state>)'" )
			return initial_branch
		end
	end
end

function stmJump( otherwise )												-- Безусловный обработчик перехода на сохраненное состояние
	return function( machine )
		if machine.stm_savedState then
			return machine.stm_savedState
		else
			isErr( otherwise == nil, "This state machine haven't saved state! For avoid it specify 'stmJump(<state>)'" )
			return otherwise 
		end
	end
end

function stm_handler( machine, handlerName, ... )
	local handler = stm_select(machine, machine.current_state, handlerName)
	local jumpTo;
	
	if handlerName == "touch" then
		if curr(machine).bind then
			local another = ref(curr(machine).bind)
			another:call( machine )
		elseif curr(machine).binds then
			for _, obj in ipairs( curr(machine).binds ) do
				ref(obj):call( machine )
			end
		end

		if curr(machine).takable then		-- takable - не наследуемое свойство состояния 
			take(machine)
			jumpTo = curr(machine, true).taked
		else
			jumpTo = curr(machine, true).touch
		end
	else
		jumpTo = curr(machine, true)[handlerName]
	end

	jumpTo = tcall(jumpTo, machine, ...)								-- "разворачиваем" обработчик
	if jumpTo then
		machine.stm_prevState, machine.current_state = machine.current_state, jumpTo
	end	

	return handler, machine, ...
end

-- Дополнительные поля состояний:
-- takable				брать при первом touch (не наследуется)
-- reflexive			use и used воспринимаются как одно и тоже (used переадресовывается)
-- iam					название состояние совпадает с отображаемым именем

-- touch покрывает act, inv и tak классического API
-- Имя не обязательно присваивать в nam, можно писать и так (из-за синтаксиса Lua это будет 1й элемент таблицы)
-- init может быть строкой - тогда она интерпретируется как имя состояния, что должно быть начальным 

stm = function(v)
	-- Prepare for construction
	-- TODO советовать что использовать взамен
	local occupied = { "disp", "dsc", "act", "take", "inv", "use", "used", "nouse", "stm_prevState", "stm_savedState", "call" }
	for _, field in ipairs(occupied) do
		isErr( type(v[field]) ~= "nil", "You shouldn't use '" .. field .. "' field in your state machine" );
	end

	isErr( v.states.initial ~= nil, "Name of initial state is 'init' instead of 'initial'" )
	isErr( v.states.default ~= nil, "Name of default state is 'def' instead of 'default'" )
	isErr( type(v.states) ~= "table", "Your state machine haven't field 'states'" )
	isErr( type(v.branches) ~= "table", "Your state machine haven't field 'branches'" )
	isErr( not(v.states.def), "Your state machine haven't default state. Put 'def={}' to 'states' if it correct")

	for state, _ in pairs(v.branches) do 							-- Проверка на опечатки (или неиспользуемый код)
		--- Может сработать в холостую, если мешать стиль состояния по умолчанию (явный - def - и неявный - просто {...})
		isErr( v.states[state] == nil, "Machine's branches '" .. state .. "' written with mistake (or redundant)" );
	end

	stead.add_var(v, {stm_prevState = false, stm_savedState = false} )
	if v.states.init then												-- current_state содержит тэг текущего состояния
		if type(v.states.init) == "string" then
			stead.add_var( v, {current_state = v.states.init} )
		else
			stead.add_var( v, {current_state = "init"} )					
		end
	elseif v.states.def then											-- Если не задан init, то первым состоянием будет def
		stead.add_var( v, {current_state = "def"} )				
	end

	-- Build state machine
	v.disp = function(s)													-- В случае disp==nil (безымянное состояния), используем v.nam
		local disp = tcall( stm_handler(s, "nam") )
		if not disp then
			disp = tcall( stm_handler(s, 1) )
		end
		return disp
	end
	v.dsc = function(s)
		local dsc = tcall( stm_handler(s, "dsc") )
		isErr( dsc == nil, "This state ('" .. s.current_state .. "', obj = " .. s.nam .. ") haven't dsc and can't be represented at scene" );
		return dsc
	end
	v.act = function(s)
		return tcall( stm_handler(s, "touch") ) or true
	end
	v.inv = function(s)
		return tcall( stm_handler(s, "touch") )
	end
	v.use = function(s, w)	
		return tcall( stm_handler(s, "use", w) ) or true
	end
	v.used = function(s, w)
		if curr(s).reflexive then
			return s.use(w, s);
		end
		return tcall( stm_handler(s, "used", w) ) or true
	end
	v.call = function(s, w)
		return tcall( stm_handler(s, "call", w) )
	end

	return obj(v)
end
