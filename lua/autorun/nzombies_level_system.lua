AddCSLuaFile()

resource.AddSingleFile("materials/gui/background.png")
resource.AddSingleFile("materials/gui/skillicons/armor.png")
resource.AddSingleFile("materials/gui/skillicons/jump.png")
resource.AddSingleFile("materials/gui/skillicons/sprint.png")
resource.AddSingleFile("materials/gui/skillicons/zombie_resistance.png")

--This is mainly just the loader
--also, this should pretty much always be false
nz_allow_nasty_reload = false

if nz_level_system then
	if nz_allow_nasty_reload then print("\n\n\n\n\n\n\n\nGlobal already exists; but not returning.")
	else print("\n\n\n\n\n\n\n\nGlobal already exists; returning.") end
end

nz_level_system = nz_level_system or {}
nz_level_system.skills = nz_level_system.skills or {}

local max_search_level = 4

local function check_script_flag(script_path, text_flag)
	local explode = string.Split(script_path, "/")
	
	return string.StartWith(explode[#explode], text_flag)
end

local function load_script(script_path)
	--check if they are flagged with cl for client, sh for shared, and sv for server
	--learned this naming method from Zet0rz but never actually tried it...
	--I'll be using the same method to load scripts as I did in my first c++ game
	
	--I like bit flags :D
	local bits = bit.bor(
		check_script_flag(script_path, "cl_") and 1 or 0,
		check_script_flag(script_path, "sh_") and 2 or 0,
		check_script_flag(script_path, "sv_") and 4 or 0)
	
	if SERVER then
		if bit.band(bits, 3) ~= 0 then AddCSLuaFile(script_path) end
		if bit.band(bits, 6) ~= 0 then include(script_path) end
	elseif bit.band(bits, 3) ~= 0 then include(script_path) end
end

local function search_directory(directory, level)
	local scripts, folders = file.Find(directory .. "*", "LUA", "nameasc")
	
	--first load all the scripts
	for _, script in ipairs(scripts) do
		print("Request to load script " .. script .. " in directory " .. directory)
		
		load_script(directory .. script)
	end
	
	--we also use ipairs to keep this ordered
	if level == 0 then
		for _, folder in ipairs(folders) do
			if folder == "skills" then continue end
			
			search_directory(directory .. folder .. "/", level + 1)
		end
	elseif level < max_search_level then for _, folder in ipairs(folders) do search_directory(directory .. folder .. "/", level + 1) end end
end

search_directory("nzombies_level_system/", 0)