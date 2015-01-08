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

local function stm_curr(s, isBranches)										-- Get current machine's state/branch
	local mod = isBranches and "branches" or "states"
	return s[mod][ s.current_state ] or {};
end

local function stm_select ( machine, state, field )
	local state_holder = machine.states[state]
	isErr( state_holder == nil, 											-- Ошибка укажет на stm в этом файле, увы...
			"Your machine '".. deref(machine) .."' haven't state: " .. state 
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

local function stm_handler( machine, handlerName, ... )			-- Показываем реакцию, проверяем условие изменения состояния
	local handler, jumpTo;

	if handlerName == "nam" or handlerName == 1 then
		isErr( stm_curr(machine) == nil, "State '" .. tostring(state) .. "' doesn't exist (".. deref(machine) ..")" )
		if stm_select(machine,machine.current_state,"iam") then	-- Отображаемое имя объекта может совпадать с тэгом состояния
			handler = state;
		end
	else
		handler = stm_select(machine, machine.current_state, handlerName)
	end

	if handlerName == "touch" then
		local binding = stm_select(machine, machine.current_state, "bind")
		if binding then														-- Обработчик одной stm может запускать обработчик у другой
			ref(binding):call( machine )
		else 
			binding = stm_select(machine, machine.current_state, "binds")
			if binding then													-- или нескольких сразу
				for _, obj in ipairs( stm_curr(machine).binds ) do
					ref(obj):call( machine )
				end
			end
		end

		if stm_curr(machine).takable then										-- Обработчик может инициировать взятие объекта
			take(machine)
			jumpTo = stm_curr(machine, true).taked
		else
			jumpTo = stm_curr(machine, true).touch
		end
	else
		jumpTo = stm_curr(machine, true)[handlerName]
	end

	jumpTo = tcall(jumpTo, machine, ...)								-- "разворачиваем" обработчик перехода
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
-- init - начальное состояние конечного автомата. Может быть ссылкой - хранить строку-имя начального состояния 
-- TODO add 'nouse' handler
stm = function(v)
	-- Prepare for construction
	local occupied = { "disp","dsc","act","take","inv","use","used","nouse","stm_prevState","stm_savedState","call" }
	for _, field in ipairs(occupied) do
		isErr( type(v[field]) ~= "nil", "You shouldn't use '" .. field .. "' field in your state machine" );
	end
	v.nam = v.nam or "name no need";

	isErr( v.states.initial ~= nil, "Name of initial state is 'init' instead of 'initial'" )
	isErr( v.states.default ~= nil, "Name of default state is 'def' instead of 'default'" )
	isErr( type(v.states) ~= "table", "Your state machine haven't field 'states'" )
	isErr( type(v.branches) ~= "table", "Your state machine haven't field 'branches'" )
	isErr( not(v.states.def), "Your state machine haven't default state. Put 'def={}' to 'states' if it correct")

	for state, _ in pairs(v.branches) do 							-- Проверка на опечатки (или неиспользуемый код)
		isErr( v.states[state] == nil, "Machine's branches '" .. state .. "' written with mistake (or redundant)" );
	end

	stead.add_var(v, {stm_prevState = false, stm_savedState = false} )
	if v.states.init then												-- current_state содержит тэг текущего состояния
		if type(v.states.init) == "string" then					-- Начальным состоянием можно задать, поместив тэг в init
			stead.add_var( v, {current_state = v.states.init} )
		else 																		-- или создать состояние с таким тэгом 
			stead.add_var( v, {current_state = "init"} )					
		end
	elseif v.states.def then											-- Если не задан init, то начальным состоянием будет def
		stead.add_var( v, {current_state = "def"} )				
	end

	-- Build state machine
	v.disp = function(s)
		local disp = tcall( stm_handler(s, "nam") )
		if not disp then
			disp = tcall( stm_handler(s, 1) )
			isErr( not disp, "Current state " .. s.current_state .. " of '" .. deref(s) .. "' haven't name (state 'def', too" )
		end
		return disp
	end
	v.dsc = function(s)
		local dsc = tcall( stm_handler(s, "dsc") )
		isErr( dsc == nil, "This state ('" .. s.current_state .. "', obj = " .. deref(s) .. ") haven't dsc and can't be represented at scene. If it is correct - put 'dsc=true'" );
		return dsc
	end
	v.act = function(s)
		return tcall( stm_handler(s, "touch") ) or true
	end
	v.inv = function(s)
		return tcall( stm_handler(s, "touch") ) or true
	end
	v.use = function(s, w)	
		return tcall( stm_handler(s, "use", w) ) or true
	end
	v.used = function(s, w)
		if stm_curr(s).reflexive then
			return s.use(w, s);
		end
		return tcall( stm_handler(s, "used", w) ) or true
	end
	v.call = function(s, w)												-- Непрямое взаимодействие объектов (ружье и мишень, фонарик и тень)
		return tcall( stm_handler(s, "call", w) )
	end

	return obj(v)
end

function stmPrev( initial_branch )					-- Безусловный обработчик перехода назад
	return function( machine )							-- Если требуется переход при выполнении условия.
		if machine.stm_prevState then						-- то лучше писать обработчик самому
			return machine.stm_prevState					-- Прошлое значение вызывается этой строкой
		else
			isErr( initial_branch == nil, "This state machine haven't previous state! For avoid it specify 'stmPrev(<state>)'" )
			return initial_branch
		end
	end
end

function stmJump( otherwise )							-- Безусловный обработчик перехода на сохраненное состояние
	return function( machine )
		if machine.stm_savedState then
			return machine.stm_savedState
		else
			isErr( otherwise == nil, "This state machine haven't saved state! For avoid it specify 'stmJump(<state>)'" )
			return otherwise 
		end
	end
end

function stmTak( dsc, tak, used )					-- Короткая форма для создания состояния. Так как нет имени переход в branches обязателен!
	isErr( not string.match(dsc, "{.*}"), "Do you forgot {<link>} in dsc?" ) 
	return { dsc = dsc, touch = tak, used = used, takable = true }
end
