--I have a table for this specific font I use in my progress bar addon. This will keep me from making duplicate fonts
--I may make the functions themself global, but for now I'll have it like this
CryotheumDynamicFontData = CryotheumDynamicFontData or {}

--this one is for more
CryotheumDynamicNZLSFontData = CryotheumDynamicNZLSFontData or {}

print("reloaded font file")

local function create_font(size, weight, font_name)
	surface.CreateFont("nzlsgen." .. font_name .. "." .. size .. "." .. weight, {
		font = font_name,
		size = size,
		weight = weight,
		antialias = true,
	})
end

local function create_dk_font(size, weight)
	surface.CreateFont("pbgenfont" .. size .. "." .. weight, {
		font = "DK Umbilical Noose",
		size = size,
		weight = weight,
		antialias = true,
	})
end

local function register_font(size, weight, font_name)
	--I hate fonts
	--also cool to see the semantic method vs the robust method
	if font_name then
		if not CryotheumDynamicNZLSFontData[font_name] or not CryotheumDynamicNZLSFontData[font_name][size] or not CryotheumDynamicNZLSFontData[font_name][size][weight] then
			table.Merge(CryotheumDynamicNZLSFontData, {[font_name] = {[size] = {[weight] = true}}})
			
			create_font(size, weight, font_name)
		end
		
		return "nzlsgen." .. font_name .. "." .. size .. "." .. weight
	else
		if CryotheumDynamicFontData[size] then
			if not CryotheumDynamicFontData[size][weight] then 
				CryotheumDynamicFontData[size][weight] = true
				
				create_dk_font(size, weight)
			end
		else
			CryotheumDynamicFontData[size] = {[weight] = true}
			
			create_dk_font(size, weight)
		end
		
		return "pbgenfont" .. size .. "." .. weight
	end
end

return register_font