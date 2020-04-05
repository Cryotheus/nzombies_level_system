--these are the functions used by sv_core AND cl_core
--this will be ignored by the loader

local function calc_exp(level)
	--calculate exp from level
	--also num * num is cheaper than 
	return level * level * 100
end

local function calc_level(exp)
	--calculate level from exp
	return math.floor(math.sqrt(exp / 100))
end

return calc_exp, calc_level