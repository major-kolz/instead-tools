-- Licensed under the Apache License, Version 2.0 <LICENSE-APACHE or
-- http://www.apache.org/licenses/LICENSE-2.0>

instead_version "2.0.3";

require 'xact'
require 'format'
format.para 	= true;			-- Отступы в начале абзаца;
format.dash 	= true;			-- Замена двойного минуса на длинное тире;
format.quotes 	= true;			-- Замена " " на типографские << >>;

require 'useful'

main = room{
	nam = "Первая комната",
	var {
		one = 1, 
		two = 'два',
		tree = 3
	},
	dsc = _say "@one is not @two and is not @tree",
	obj = {
		'box',
	}, 
};

box = obj{
	nam = "Ларец",
	_closed = true,
	dsc = _if( '_closed',
		"Предо мной стоит {ларец}.",
		"Предо мной стоит открытый {ларец}."
	),
	act = _trig( '_closed',
		"Со сладким томлением первооткрывателя я подымаю крышку ларца",
		_prnd {
			"Одна труха истлевших бумаг... Как судьба жестока ко мне!..",
			"Но где же мои "
		}
	);
};
