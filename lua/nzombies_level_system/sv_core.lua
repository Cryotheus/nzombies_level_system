print("Core loaded (server realm)")

--shared functions

AddCSLuaFile("fn_core.lua")

local calc_exp, calc_level = include("fn_core.lua")

--not shared stuff
local check_exp = false
local check_exp_list = {}
local file_path = "nz_level_system/"
local file_path_players = file_path .. "players/"
local ply_data = {}
local ply_meta = FindMetaTable("Player")

local sql_mode = false

local nz_ls_save_sql = CreateConVar("nz_ls_save_sql", "0", {FCVAR_ARCHIVE, FCVAR_NEVER_AS_STRING}, "", 0, 1)

--functions

local function async_path(steam_id)
	--I structure the files in a way that no folder has more than 10 files and 10 folders
	--this way, if we have to search through all of them we can do it asynchronously so the server does not experience major lag
	local digits = string.sub(steam_id, 11)
	local path = file_path_players .. steam_id[9] .. "/"
	
	--we use string.len instead of # as string.len is more efficient
	for place = 1, string.len(digits) do path = path .. digits[place] .. "/" end
	
	return path
end

local function check(ply)
	check_exp = true
	check_exp_list[ply:UserID()] = true
end

local function get_exp(ply)
	--get the player's current exp
	return ply_data[ply:UserID()].experience or 0
end

local function get_level(ply)
	--get the player's current level
	return calc_level(get_exp(ply))
end

local function get_points(ply)
	--returns the total amount of skill points they have been given
	return ply_data[ply:UserID()].points or 0
end

local function get_points_eaten(ply)
	--returns how many skill points they have spent
	return ply_data[ply:UserID()].points_used or 0
end

local function get_points_left(ply)
	--gets the amount of skill points they have left
	return get_points(ply) - get_points_eaten(ply)
end

local function get_points_prestiege(ply)
	--returns the total amount of skill points they have been given
	return ply_data[ply:UserID()].points_prestiege or 0
end

local function get_points_prestiege_eaten(ply)
	--returns how many skill points they have spent
	return ply_data[ply:UserID()].points_prestiege_used or 0
end

local function get_points_prestiege_left(ply)
	--gets the amount of skill points they have left
	return get_points_prestiege(ply) - get_points_prestiege_eaten(ply)
end

local function get_skills(ply)
	--
	return ply_data[ply:UserID()].skills
end

local function get_skill_level(ply, skill_name)
	--returns how many times the skill has been leveled
	local skill = ply_data[ply:UserID()].skills[skill_name] or {}
	
	return skill and skill.level or 0
end

local function get_skill_level_prestiege(ply, skill_name)
	--returns how many times the skill has been prestiege leveled
	local skill = ply_data[ply:UserID()].skills[skill_name] or {}
	
	return skill.level_prestiege or 0
end

local function load(ply)
	local id = ply:UserID()
	local path = async_path(ply:SteamID())
	
	ply_data[id] = {}
	
	--we pre set these in case they have no saved data
	ply_data[id].experience = 0
	ply_data[id].points = 0
	ply_data[id].points_prestiege = 0
	ply_data[id].points_prestiege_used = 0
	ply_data[id].points_used = 0
	ply_data[id].skills = {}
	
	local skills_read = file.Read(path .. "skills.json", "DATA")
	local stats_read = file.Read(path .. "stats.json", "DATA")
	
	if stats_read then ply_data[id] = table.Merge(ply_data[id], util.JSONToTable(stats_read)) end
	if skills_read then ply_data[id].skills = util.JSONToTable(skills_read) end
end

local function save_skills(ply, path)
	--save only the skills
	file.Write(path .. "skills.json", util.TableToJSON(get_skills(ply), true))
end

local function save_stats(ply, path)
	--save their statistics like exp, points, etc. but not skills
	local stats = table.Copy(ply_data[ply:UserID()])
	stats.skills = nil
	
	file.Write(path .. "stats.json", util.TableToJSON(stats, true))
end

local function set_exp(ply, amount)
	--sets the player's exp
	ply_data[ply:UserID()].experience = amount
end

local function set_points(ply, amount)
	--sets the total amount of skill points they have been given
	ply_data[ply:UserID()].points = amount
end

local function set_points_eaten(ply, amount)
	--sets how many skill points they have spent
	ply_data[ply:UserID()].points_used = amount
end

local function set_points_prestiege(ply, amount)
	--sets the total amount of skill points they have been given
	ply_data[ply:UserID()].points_prestiege = amount
end

local function set_points_prestiege_eaten(ply, amount)
	--sets how many skill points they have spent
	ply_data[ply:UserID()].points_prestiege_used = amount
end

local function set_skill_level(ply, skill_name, level)
	--sets how many times the skill has been leveled
	local old_level = get_skill_level(ply, skill_name)
	
	if level ~= old_level then
		local ply_skill = ply_data[ply:UserID()].skills[skill_name]
		local skill = NZLS.skills[skill_name]
		
		if skill.OnLevelChangedPre then skill.OnLevelChangedPre(ply, old_level, level) end
		
		if level == 0 then
			if get_skill_level_prestiege(ply, skill_name) > 0 then ply_skill.level = nil
			else ply_skill = nil end
		else
			if ply_skill then ply_skill.level = level
			else ply_skill = {["level"] = level} end
		end
		
		if skill.OnLevelChangedPost then skill.OnLevelChangedPost(ply, old_level, level) end
		
		ply_data[ply:UserID()].skills[skill_name] = ply_skill
	end
end

local function set_skill_level_prestiege(ply, skill_name, level)
	--sets how many times the skill has been leveled
	if level ~= old_level then
		local ply_skill = ply_data[ply:UserID()].skills[skill_name]
		local skill = NZLS.skills[skill_name]
		
		if skill.OnLevelPrestiegeChangedPre then skill.OnLevelPrestiegeChangedPre(ply, old_level, level) end
		
		if level == 0 then
			if get_skill_level(ply, skill_name) > 0 then ply_skill.level_prestiege = nil
			else ply_skill = nil end
		else
			if ply_skill then ply_skill.level_prestiege = level
			else ply_skill = {["level_prestiege"] = level} end
		end
		
		if skill.OnLevelPrestiegeChangedPost then skill.OnLevelPrestiegeChangedPost(ply, old_level, level) end
		
		ply_data[ply:UserID()].skills[skill_name] = ply_skill
	end
end

local function whole_save(ply)
	--we want to keep files small for asynchronous querying
	local path = async_path(ply:SteamID())
	
	file.CreateDir(path)
	save_skills(ply, path)
	save_stats(ply, path)
end

--meta functions for modules to interact with
--TODO: add docs
--note: if you need any more functions to interact with this file, make a request on the github! https://github.com/Cryotheus/nzombies_level_system

function ply_meta:NZLSAddExperience(amount)
	--this will make the information on the client get updated
	check(self)
	
	local current_exp = get_exp(self)
	local current_level = calc_level(current_exp)
	local new_exp = current_exp + amount
	local new_level = calc_level(new_exp)
	
	if new_level > current_level then
		--in case they level up multiple times
		self:NZLSAddPoints(new_level - current_level)
	end
	
	set_exp(self, new_exp)
end

function ply_meta:NZLSAddPoints(amount)
	--
	set_points(self, get_points(self) + amount)
end

function ply_meta:NZLSAddPointsPrestiege(amount)
	--
	set_points_prestiege(self, get_points_prestiege(self) + amount)
end

function ply_meta:NZLSGetExperience()
	--
	return get_exp(self)
end

function ply_meta:NZLSGetLevel()
	--
	return get_level(self)
end

function ply_meta:NZLSGetPoints()
	--
	return get_points(self)
end

function ply_meta:NZLSGetSkillLevel(skill_name)
	--
	return get_skill_level(self, skill_name)
end

function ply_meta:NZLSGetSkillLevelPrestiege(skill_name)
	--
	return get_skill_level_prestiege(self, skill_name)
end

function ply_meta:NZLSGetSkillLevelSum(skill_name)
	--
	return get_skill_level(self, skill_name) + get_skill_level_prestiege(self, skill_name)
end

function ply_meta:NZLSHasData()
	if ply_data[self:UserID()] then return true end
	
	return false
end

function ply_meta:NZLSSetExperience(amount)
	--
	check(self)
	set_exp(self, amount)
end

function ply_meta:NZLSSetPoints(amount)
	--
	set_points(self, amount)
end

function ply_meta:NZLSSetPointsPrestiege(amount)
	--
	set_points_prestiege(self, amount)
end

function ply_meta:NZLSSetSkillLevel(skill_name, level)
	--
	set_skill_level(self, skill_name, level)
end

function ply_meta:NZLSSetSkillLevelPrestiege(skill_name, level)
	--
	set_skill_level_prestiege(self, skill_name, level)
end

function ply_meta:NZLSSetSkillLevelSum(skill_name, level)
	local data = NZLS.skills[skill_name]
	local max_level = data.MaxLevel
	local max_level_prestiege = data.MaxLevelPrestige or 0
	
	set_skill_level(self, skill_name, math.min(level, max_level))
	set_skill_level_prestiege(self, skill_name, math.Clamp(level - max_level, 0, max_level_prestiege))
end

function ply_meta:NZLSRemoveData()
	--
	ply_data[self:UserID()] = {}
end

function ply_meta:NZLSResetData()
	self:NZLSRemoveData()
	
	print("Resetting ply data for " .. self:Nick())
	
	load(self)
	
	print("Data")
	PrintTable(ply_data[self:UserID()], 1) 
end

--commands

concommand.Add("nz_ls_debug_pd", function(ply, cmd, args)
	if not ply or not ply:IsSuperAdmin() then ply:PrintMessage(HUD_PRINTCONSOLE, "[nZLS] This command can only be used by super admins.") return end
	
	local skill_name = args[1]
	
	PrintTable(ply_data[ply:UserID()], 1)
end, _, "Provides information about the player data.")

concommand.Add("nz_ls_purchase", function(ply, cmd, args)
	if not IsValid(ply) then return end
	
	local skill_name = args[1]
	
	if NZLS.skills[skill_name] then
		local current_level = get_skill_level(ply, skill_name)
		local current_level_prestiege = get_skill_level_prestiege(ply, skill_name)
		local data = NZLS.skills[skill_name]
		local max_level = data.MaxLevel
		local max_level_prestiege = data.MaxLevelPrestige
		
		if current_level < max_level then
			local cost = data.Cost(current_level + 1)
			
			if get_points_left >= cost then
				
			else ply:PrintMessage(HUD_PRINTCONSOLE, "[nZLS] You need atleast " .. cost .. " points to upgrade this skill to the next level.") end
		elseif max_level_prestiege and current_level_prestiege < max_level_prestiege - max_level then
			local cost = data.Cost(current_level_prestiege + 1)
			
			if get_points_prestiege_left >= cost then
				
			else ply:PrintMessage(HUD_PRINTCONSOLE, "[nZLS] You need atleast " .. cost .. " prestiege points to upgrade this skill to the next level.") end
		else ply:PrintMessage(HUD_PRINTCONSOLE, "[nZLS] Skill is at max level and cannot be upgraded further.") end
	else ply:PrintMessage(HUD_PRINTCONSOLE, "[nZLS] Skill does not exist with name " .. (skill_name or "nil")) end
end, _, "Purchase the specified skill.")

--convars

cvars.AddChangeCallback("nz_ls_save_sql", function(name, old, new)
	--
	sql_mode = nz_ls_save_sql:GetBool()
end)

--hooks
hook.Add("PlayerDisconnected", "nz_level_system_disconnect_hook", function(ply)
	--
	whole_save(ply)
	
	ply:NZLSRemoveData()
end)

hook.Add("PlayerInitialSpawn", "nz_level_system_ply_init_hook", function(ply)
	--
	ply:NZLSResetData()
end)

hook.Add("Think", "nz_level_system_think_hook", function()
	--TODO use a bitwise system to determine what networked value needs updating --re-evaluate wether this is necessary
	
	if check_exp then
		for user_id, needs_check in pairs(check_exp_list) do
			local ply = Player(user_id)
			
			ply:SetNWInt("nz_ls_exp", get_exp(ply))
			
			if not needs_check then print(ply, "[nZ LS] Checked with no need to?") end
		end
		
		check_exp_list = {}
	end
	
	check_exp = false
end)