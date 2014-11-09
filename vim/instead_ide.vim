" Не завершено

nmap <C-c> :call MKC(0)<CR>
imap <C-c> <Esc>:call MKC(1)<CR>
" ****************************** Описание ******************************
" Функция авто-создания конструкции по ключевому слову под курсором (nmod) / перед курсором (imod)
" Создается заготовка конструкции и размещаются метки ТУДА и ОБРАТНО
" @args: isImode указывает находимся ли в режиме вставки
" ******************************  Логика  ******************************
" В зависимости от блока, в котором оказалось обрабатываемое слово создаются следующие конструкции:
" 1. way		 -  заготовка комнаты. Если комната существует - добавить в обе взаимные пути 
" 2. obj		 -  заготовка объекта.
" 3. ссылка  -  xact
" 4. функция -  var-переменная (с инициализацией по-умолчанию)   
function MKC(isImode)
	if a:isImode
		normal b
	endif
	normal my
	let id = expand('<cWORD>')
	let type = "undefined" 	" Тип создаваемой конструкции
	
	if match(id, '{.*|.*}') != -1					" xact без пробелов
		let type = 'xact'
		let id = strpart( id, 1, match(id, '|' )-1 )		" Извлекаем имя xact
		call ConstructXact(id)
	elseif match(id, '{.*|.* ') != -1			" xact с пробелами, начало выраженя
		let type = 'xact'
		let id = strpart( id, 1, match(id, '|' )-1 )
		call ConstructXact(id)
	elseif match(id, '{.*}') != -1					" Ссылка в dsc на этот объект, пропускаем
		let id = 0	
	elseif match(id, '.*}') != -1					" xact с пробелами, конец выражения
		let type = 'xact'
		let currLine = getline( line(".") )
		let id = strpart( currLine, match(currLine, '{.*|.*') )	" Отрезаем от {<name> до конца строки
		let id = strpart( id, 1, match(id, '|' )-1	)				" Вырезаем <name>
		unlet l:currLine
		call ConstructXact(id)
	elseif (match(id, '".*"') != -1) || 
				\ (match(id, '\".*\"') != -1)		" Если id облачен в кавычки - нужно создать obj/room/way
		for n in range( line("."), 1, -1 )
			let currLine = getline( n )
			let blockStart = match(currLine, '.\{-2,3} \{-0,1}= \{-0,1}{\| \{-0,1}function \{-0,1}(' )
			if blockStart != -1
				let blockStart = strpart( currLine, blockStart, match(currLine, ' ')-1 )
				break
			endif
		endfor
		
		let id = strpart( id, 1, strlen(id)-3 )

		if blockStart == 'obj'
			let type  = 'obj'
		elseif blockStart == 'room'
			let type = 'room'
		elseif blockStart == 'way'
			let type = 'way'
		endif
		unlet l:currLine l:blockStart
	else														" Новая переменная
		let type = 'variable'
		"matchend() " last item of match
	endif

	if type == 'undefined'
		echo "No construction for creating found"
	else
		echo "Create new" "|".type."| for: " id
	endif

	unlet l:id l:type 
	normal 'y
	if a:isImode
		normal e<Esc>
	endif
endfunc

" ****************************** Описание ******************************
" Функция авто-создания конструкции xact 
" @args: nam - название xact
" ******************************  Логика  ******************************
" Ищем в текущем объекте\комнате список obj и добавляем xact первым элементом
" Если поиск провалился - создаем список obj в конце объекта\комнаты
" Если xact принимает аргументы - создать xact( "id", code[[]] ),
" Иначe - xact( "id", "" ),
function ConstructXact( nam )
	let xactPos = line(".")
	for n in range( xactPos, 1, -1 )
		let objBlock = match( getline(n), 'obj \{-0,1}= \{-0,1}{' )
		if objBlock != -1 
			let objBlock = n
			break
		endif
		let defStart = match( getline(n), ' \{-0,1}= \{-0,1}.\{-3,4} \{-0,1}{' )
		if defStart != -1
			let defStart = n
			break
		endif
	endfor
	
	if objBlock == -1										" Над ключевым словом нет блока obj = {}
		call cursor( defStart, match( getline(defStart), '{' ) )
		normal %
		for n in range( line("."), xactPos, -1 )
			let objBlock = match( getline(n), 'obj \{-0,1}= \{-0,1}{' )
			if objBlock != -1 
				let objBlock = n
				break
			endif
		endfor
	endif
	
	let withCode = match( a:nam, '(.*)' )
	if withCode == -1
		let construct = printf("\t\txact( \"%s\", \"\" ),", a:nam)
	else
		let construct = strpart( a:nam, 0; withCode )
	endif

	if objBlock == -1										" Под ключевым словом нет блока obj = {} (создать)
		let currLine = line(".")
		call append( currLine-1, "\tobj = {" )
		call append( currLine, construct )
		call append( currLine+1, "\t}," )
		unlet l:currLine
	else														" Добавить 
		call append( objBlock+1, construct )
	endif

	unlet l:xactPos l:objBlock l:defStart l:withCode l:construct
endfunction
