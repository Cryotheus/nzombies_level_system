--This is mainly just the loader

if SERVER then
	AddCSLuaFile()
	
	resource.AddSingleFile("materials/gui/nzombies_level_system/background.png")
	resource.AddSingleFile("materials/gui/nzombies_level_system/circle.png")
	resource.AddSingleFile("materials/gui/nzombies_level_system/circle_256.png")
	resource.AddSingleFile("materials/gui/nzombies_level_system/progress_bar.png")
	resource.AddSingleFile("materials/gui/nzombies_level_system/progress_bar_composite.png")
	resource.AddSingleFile("materials/gui/nzombies_level_system/skillicons/agility.png")
	resource.AddSingleFile("materials/gui/nzombies_level_system/skillicons/leap.png")
	resource.AddSingleFile("materials/gui/nzombies_level_system/skillicons/relief.png")
	resource.AddSingleFile("materials/gui/nzombies_level_system/skillicons/wip.png")
	resource.AddSingleFile("materials/gui/nzombies_level_system/skillicons/zombie_resistance.png")
	resource.AddSingleFile("materials/gui/nzombies_level_system/skin.png")
	
	resource.AddSingleFile("sound/nzombies_level_system/gui/bleep.wav")
	resource.AddSingleFile("sound/nzombies_level_system/gui/prestiege.wav")
	resource.AddSingleFile("sound/nzombies_level_system/gui/skill_upgrade.wav")
	resource.AddSingleFile("sound/nzombies_level_system/gui/warp.wav")
	resource.AddSingleFile("sound/nzombies_level_system/gui/wip.wav")
end

--NZLSNastyReload should pretty much always be false

if NZLS then
	if NZLSNastyReload then print("[nZLS] Global already exists; but not returning.")
	else print("[nZLS] Global already exists; returning.") return end
end

NZLS = NZLS or {}
NZLS.skills = NZLS.skills or {}

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
	--fn_ is handled by other scripts, and should never be loaded here
	
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