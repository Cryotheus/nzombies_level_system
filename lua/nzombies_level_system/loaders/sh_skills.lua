print("Skills loading")

local directory = "nzombies_level_system/skills/"
local _, folders = file.Find(directory .. "*", "LUA", "nameasc")
local ply_meta = FindMetaTable("Player")

local function load_skill(skill_name, skill_path)
	print("  Loading skill module " .. skill_name)
	
	if SERVER then
		AddCSLuaFile(skill_path .. "client.lua")
		AddCSLuaFile(skill_path .. "shared.lua")
		
		NZLS.skills[skill_name] = include(skill_path .. "server.lua")
	else NZLS.skills[skill_name] = include(skill_path .. "client.lua") end
end

for _, folder in ipairs(folders) do load_skill(folder, directory .. folder .. "/") end

print("Skills loaded")