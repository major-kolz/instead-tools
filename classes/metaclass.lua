-- Copyright 2014 Nikolay Konovalow
-- Licensed under the Apache License, Version 2.0 <LICENSE-APACHE or
-- http://www.apache.org/licenses/LICENSE-2.0>

require "useful"

function isEq ( a, b )
	if a == b then
		return true
	elseif a == b.parent then
		return true
	elseif a.parent == b then
		return true
	elseif a.parent == b.parent then
		return true
	end
	
	return false
end

function metaclass ( v )
	v.parent = v
	return obj(v)
end

function extends ( parent, complementing )
	return function( child )
		child.parent = parent
		local safed = {}
		for v, w in pairs(parent.variables_save) do			-- Наследуются лишь объявленный через var переменные
			if not child[v] then
				print( v, w )
				safed[v] = w
			end
		end	
		print "---"
		for i, v in pairs( safed ) do 
			print( i, v )
		end 
		stead.add_var( child, safed )

		for _, v in ipairs { 'dsc', 'act', 'tak', 'inv', 'use', 'used' } do
			if child[v] == nil then
				child[v] = parent[v]
			elseif complementing then
				local handler = child[v]
				child[v] = function( arg1, arg2 )  
					if not parent[v]( child, arg2 ) then 
						handler( child, arg2 );
					end
				end;
			end
		end

		return obj(child)
	end
end
