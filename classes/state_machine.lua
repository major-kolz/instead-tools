-- Copyright 2014 Nikolay Konovalow
-- Licensed under the Apache License, Version 2.0 <LICENSE-APACHE or
-- http://www.apache.org/licenses/LICENSE-2.0>

require "useful"

local function tcall(f, s)				-- wiki, "Приемы программирования", "Пример реализации фонарика" - vorov2
	if type(f) == "function" then
		return tcall(f(s), s)
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
		if machine.states[state].iam then							-- Отображаемое имя объекта может совпадать с тэгом состояния
			return state;
		end
	end
	
	local state_holder = machine.states[state]
	isErr( state_holder == nil, "Your machine haven't state: " .. state );	-- Ошибка укажет на stm в этом файле, увы...
	isErr( type( state_holder ) ~= "table", "Your machine state '" .. state .. "' isn't table" )
	
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
			isErr( initial_branch == nil, "This state machine haven't previous state! Give second parameter if it's correct" )
			return initial_branch
		end
	end
end

function stmJump( otherwise )												-- Безусловный обработчик перехода на сохраненное состояние
	return function( machine )
		if machine.stm_savedState then
			return machine.stm_savedState
		else
			isErr( otherwise == nil, "This state machine haven't saved state! You may specify 'emergency' state for this case" )
			return otherwise 
		end
	end
end

function stm_handler( machine, handlerName )
	local handler = stm_select(machine, machine.current_state, handlerName)
	local jumpTo;
	
	if handlerName == "touch" and curr(machine).takable then	-- takable - не наследуемое свойство состояния 
		take(machine)
		jumpTo = curr(machine, true).taked
	else
		jumpTo = curr(machine, true)[handlerName]
	end

	jumpTo = tcall(jumpTo, machine)									-- "разворачиваем" обработчик
	if jumpTo then
		machine.stm_prevState, machine.current_state = machine.current_state, jumpTo
	end	

	return handler, machine
end

-- Дополнительные поля состояний:
-- takable				брать при первом touch (не наследуется)
-- reflexive			use и used воспринимаются как одно и тоже (used переадресовывается)
-- iam					название состояние совпадает с отображаемым именем

-- touch покрывает act, inv и tak классического API
-- Имя не обязательно присваивать в nam, можно писать и так (из-за синтаксиса Lua это будет 1й элемент таблицы)

stm = function(v)
	-- Prepare for construction
	-- TODO советовать что использовать взамен
	for _, field in ipairs { "disp", "dsc", "act", "take", "inv", "use", "used", "nouse", "stm_prevState", "stm_savedState" } do
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
		stead.add_var( v, {current_state = "init"} )					
	elseif v.states.def then											-- Если не задан init, то первым состоянием будет def
		stead.add_var( v, {current_state = "def"} )				
	end

	-- Build state machine
	v.disp = function(s)													-- В случае disp==nil (безымянное состояния), используем v.nam
		return tcall( stm_handler(s, "nam") )
	end
	v.dsc = function(s)
		return tcall( stm_handler(s, "dsc") )
	end
	v.act = function(s)
		return tcall( stm_handler(s, "touch") ) 
	end
	v.inv = function(s)
		return tcall( stm_handler(s, "touch") )
	end
	v.use = function(s, w)												
		return tcall( stm_handler(s, "use"), w)
	end
	v.used = function(s, w)
		if curr(s).reflexive then
			return s.use(w, s);
		end
	
		return tcall( stm_handler(s, "used"), w )
	end

	return obj(v)
end
