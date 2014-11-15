--$Name: Пример 3.1 Конечный автомат$
--$Version: 0.1$
--$Author: Николай Коновалов$

instead_version "1.9.1";

require 'xact'
require 'format'
format.para 	= true;			-- Отступы в начале абзаца;
format.dash 	= true;			-- Замена двойного минуса на длинное тире;
format.quotes 	= true;			-- Замена " " на типографские << >>;

require "useful"
require "state_machine"

main = room {
	nam =  '...',
	dsc =  "Тестовая комната";
	obj = {
		"assault_rifle", "aim";
	},
};

assault_rifle = stm {
	nam = "Автомат";
	var { 
		may 		= true,			-- типо стрельбище, нужно получить разрешение инструктора
		charge 	= 30;
	},
	states = {
		{ "Машинган", dsc = "На столе лежит {автомат}.", touch = "О, автомат", takable = true },
		["В руках"] = { iam = true, touch = "Я сжимаю автомат", use = "Peow", reflexive = true },
		["Пустой"] = { nam = "Разряженный автомат", touch ="Я прямо чувствую, что он пуст, он легче" }; 
	},
	branches = { 		-- Обработчики переходов состояния. Если возвращена строка - это название нового состояния. Переход может быть безусловным (тогда прямо присваиваем строку обработчику)
		{
			taked = function(s) if s.may then  return "В руках" end end,
		},
		["В руках"] = {
			use = function(s) 
				if s.charge == 0 
					then	return "Пустой" 
					else	s.charge = s.charge - 1 
				end 
			end,
		},
	},
}

aim = obj{
	nam = "Мишень",
	_firstSign = true;
	dsc = _if( "_firstSign", 
		"Впереди, метрах в сорока, находятся пустые остовы {мишеней}.",
		"Впереди маячит {мишень}." );
	act = _trig( "_firstSign",
		"Какой-то солдат прошел и развесил, начиная с левого краю, свежие бумажки и мишенями",
		"Ни черта не видно" ); 
};
