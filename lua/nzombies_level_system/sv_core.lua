print("Core loaded (server realm)")

AddCSLuaFile("fn_core.lua")
util.AddNetworkString("nzls_data")

--fn_ functions
--just my way of keeping functions consistent between two differently sided files without making it global
local calc_exp, calc_level = include("fn_core.lua")

--locals
local check_exp = false
local check_exp_list = {}
local file_path = "nz_level_system/"
local file_path_players = file_path .. "players/"
local modded_skills_map
local modded_skills_map_typed
local modded_skills_string
local modded_skills_string_typed
local ply_data = {}
local ply_meta = FindMetaTable("Player")
local skills_string
local skills_string_empty

--convar defs
local nz_ls_save_sql = CreateConVar("nz_ls_save_sql", "1", {FCVAR_ARCHIVE, FCVAR_NEVER_AS_STRING}, "", 0, 1)

--convar values
local sql_mode = nz_ls_save_sql:GetBool()

--cached functions
local fl_sql_Query = sql.Query --we won't cache the other sql functions as they are only used in create_db

--functions
local function async_path(steam_id)
	--I structure the files in a way that no folder has more than 10 files and 10 folders
	--this way, if we have to search through all of them we can do it asynchronously so the server does not experience a major lag spike
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

local function create_db()
	sql.Begin()
	
	if not sql.TableExists("nzls_stats") then fl_sql_Query("create table nzls_stats(steam_id varchar(14) not null unique primary key,steam_name varchar(64) not null,experience int default 0,points int default 0,points_prestiege int default 0,points_used int default 0,points_prestiege_used int default 0);") end
	if not sql.TableExists("nzls_skills") then fl_sql_Query("create table nzls_skills(steam_id varchar(14) not null unique primary key);") end
	
	modded_skills_map = {}
	modded_skills_map_typed = {}
	modded_skills_string = "steam_id,"
	modded_skills_string_typed = "steam_id varchar(14) not null unique primary key,"
	skills_string = ""
	skills_string_empty = ""
	
	--used to exclude existing skills from the alter table sql query
	--mainly to avoid producing SQL errors
	local existing_skill_columns = fl_sql_Query("pragma table_info(nzls_skills)")
	local existing_skill_map = {}
	
	if existing_skill_columns then for _, column_info in pairs(existing_skill_columns) do existing_skill_map[column_info.name] = true end end
	
	for skill_name, skill_data in pairs(NZLS.skills) do
		local has_prestiege = skill_data.MaxLevelPrestige and true or false --yes this works
		
		modded_skills_map[skill_name] = has_prestiege
		modded_skills_map_typed[skill_name] = {skill_name, false}
		skills_string = skills_string .. skill_name .. ","
		
		if not existing_skill_map[skill_name] then fl_sql_Query("alter table nzls_skills add " .. skill_name .. " int default 0;") end
		
		if has_prestiege then
			local skill_name_prestiege = skill_name .. "_prestiege"
			
			modded_skills_map_typed[skill_name_prestiege] = {skill_name_prestiege, true}
			modded_skills_string = modded_skills_string .. skill_name .. "," .. skill_name_prestiege .. ","
			modded_skills_string_typed = modded_skills_string_typed .. skill_name .. " int default 0," .. skill_name_prestiege .. " int default 0,"
			skills_string_empty = skills_string_empty .. "0,0,"
			
			if not existing_skill_map[skill_name_prestiege] then fl_sql_Query("alter table nzls_skills add " .. skill_name_prestiege .. " int default 0;") end
		else
			modded_skills_string = modded_skills_string .. skill_name .. ","
			modded_skills_string_typed = modded_skills_string_typed .. skill_name .. " int default 0,"
			skills_string_empty = skills_string_empty .. "0,"
		end
	end
	
	modded_skills_string = string.TrimRight(modded_skills_string, ",")
	modded_skills_string_typed = string.TrimRight(modded_skills_string_typed, ",")
	skills_string = string.TrimRight(skills_string, ",")
	skills_string_empty = string.TrimRight(skills_string_empty, ",")
	
	--we need to remove columns for skills that don't exist, in case someone is developing a skills module and they delete/rename a skill
	--only way I could find to remove columns, found on glorious stack overflow
	fl_sql_Query("create temporary table nzls_skills_backup(" .. modded_skills_string_typed .. ");")
	fl_sql_Query("insert into nzls_skills_backup select " .. modded_skills_string .. " from nzls_skills;")
	fl_sql_Query("drop table nzls_skills;")
	fl_sql_Query("create table nzls_skills(" .. modded_skills_string_typed .. ");")
	fl_sql_Query("insert into nzls_skills select " .. modded_skills_string .. " from nzls_skills_backup;")
	fl_sql_Query("drop table nzls_skills_backup;")
	sql.Commit()
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

local function load_data(ply)
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

local function load_sql(ply)
	local id = ply:UserID()
	local name = sql.SQLStr(ply:Nick())
	local steam_id_filtered = string.sub(ply:SteamID(), 7)
	
	ply_data[id] = {}
	
	--first time insertion
	fl_sql_Query("insert or ignore into nzls_stats (steam_id,steam_name,experience,points,points_prestiege,points_used,points_prestiege_used) values(\"" .. steam_id_filtered .. "\"," .. name .. ",0,0,0,0,0);")
	
	--skill values are defaulted to 0
	fl_sql_Query("insert or ignore into nzls_skills (" .. modded_skills_string .. ") values(\"" .. steam_id_filtered .. "\", " .. skills_string_empty .. ");")
	
	--sql reading done below
	local sql_query_stats = fl_sql_Query("select * from nzls_stats where steam_id=\"" .. steam_id_filtered .. "\";")[1]
	
	if sql_query_stats then
		local sql_query_skills = fl_sql_Query("select * from nzls_skills where steam_id=\"" .. steam_id_filtered .. "\";")[1]
		sql_query_stats.steam_id = nil
		sql_query_stats.steam_name = nil
		
		for key, value in pairs(sql_query_stats) do ply_data[id][key] = tonumber(value) or value end
		
		if sql_query_skills then
			sql_query_skills.steam_id = nil
			
			ply_data[id].skills = {}
			
			for skill_name_unfiltered, level_unfiltered in pairs(sql_query_skills) do
				local level = tonumber(level_unfiltered)
				
				if level and level > 0 then
					local skill_map_data = modded_skills_map_typed[skill_name_unfiltered]
					
					local skill_field = skill_map_data[2] and "level_prestiege" or "level"
					local skill_name = skill_map_data[1]
					local skill_source = ply_data[id].skills[skill_name]
					
					if skill_source then ply_data[id].skills[skill_name][skill_field] = level
					else ply_data[id].skills[skill_name] = {[skill_field] = level} end
				end
			end
		else ply_data[id].skills = {} end
	else
		ply_data[id].experience = 0
		ply_data[id].points = 0
		ply_data[id].points_prestiege = 0
		ply_data[id].points_prestiege_used = 0
		ply_data[id].points_used = 0
		ply_data[id].skills = {}
	end
end

local function save_data_skills(ply, path)
	--save only the skills
	file.Write(path .. "skills.json", util.TableToJSON(get_skills(ply), true))
end

local function save_data_stats(ply, path)
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

local function update_data(ply)
	--we probably won't ever have enough data to warrant compression but we might as well since it is a lot of information
	local data = table.Copy(ply_data[ply:UserID()])
	data.experience = nil --we don't need to send exp, it's already networked
	
	local compressed = util.Compress(util.TableToJSON(data))
	local length = compressed:len()
	
	net.Start("nzls_data")
	net.WriteUInt(length, 32)
	net.WriteData(compressed, length)
	net.Send(ply)
end

local function whole_save_data(ply)
	--we want to keep files small for asynchronous querying
	local path = async_path(ply:SteamID())
	
	file.CreateDir(path)
	save_data_skills(ply, path)
	save_data_stats(ply, path)
end

local function whole_save_sql(ply)
	local skill_values = ""
	local steam_id_filtered = string.sub(ply:SteamID(), 7)
	local unfiltered_data = ply_data[ply:UserID()]
	
	for skill_name, has_prestiege in pairs(modded_skills_map) do
		local adding = ""
		local skill_data = unfiltered_data.skills[skill_name] or {}
		
		if has_prestiege then adding = skill_name .. "=" .. (skill_data.level or 0) .. "," .. skill_name .. "_prestiege=" .. (skill_data.level_prestiege or 0) .. ","
		else adding = skill_name .. "=" .. (skill_data.level or 0) .. "," end
		
		skill_values = skill_values .. adding
	end
	
	skill_values = string.sub(skill_values, 1, string.len(skill_values) - 1)
	
	fl_sql_Query("update nzls_skills set " .. skill_values .. " where steam_id=\"".. steam_id_filtered .. "\";")
	fl_sql_Query("update nzls_stats set steam_name="
		.. sql.SQLStr(ply:Nick()) .. ", experience="
		.. unfiltered_data.experience .. ", points="
		.. unfiltered_data.points .. ", points_prestiege="
		.. unfiltered_data.points_prestiege .. ", points_used="
		.. unfiltered_data.points_used .. ", points_prestiege_used="
		.. unfiltered_data.points_prestiege_used .. " where steam_id=\"".. steam_id_filtered .. "\";")
end

--post function setup
local load_function = sql_mode and load_sql or load_data
local save_function = sql_mode and whole_save_sql or whole_save_data

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
	
	check(self)
	load_function(self) --load their info from the saved files/db
	update_data(self) --send the client their data
end

--commands
concommand.Add("nz_ls_debug_pd", function(ply, cmd, args)
	if not ply or not ply:IsSuperAdmin() then ply:PrintMessage(HUD_PRINTCONSOLE, "[nZLS] This command can only be used by super admins.") return end
	
	local skill_name = args[1]
	
	PrintTable(ply_data[ply:UserID()], 1)
end, _, "Provides information about the player data.")

concommand.Add("nz_ls_update_data", function(ply, cmd, args)
	--
	if ply then update_data(ply) end
end, _, "Requests the server to send information about the player.")

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
				--yeah
				
			else ply:PrintMessage(HUD_PRINTCONSOLE, "[nZLS] You need atleast " .. cost .. " prestiege points to upgrade this skill to the next level.") end
		else ply:PrintMessage(HUD_PRINTCONSOLE, "[nZLS] Skill is at max level and cannot be upgraded further.") end
	else ply:PrintMessage(HUD_PRINTCONSOLE, "[nZLS] Skill does not exist with name " .. (skill_name or "nil")) end
end, _, "Purchase the specified skill.")

concommand.Add("nz_ls_test1", function(ply, cmd, args)
	if ply then
		if IsValid(ply) then save_function(ply)
		else for _, human in pairs(player.GetHumans()) do save_function(human) end end
	end
end)

--convars
cvars.AddChangeCallback("nz_ls_save_sql", function(name, old, new)
	local state = nz_ls_save_sql:GetBool()
	
	print("Changed saving mode. This convar is not finished and it is recomended that you restart your server now. Note: existing data will not be transfered.")
	
	load_function = sql_mode and load_sql or load_data
	save_function = sql_mode and whole_save_sql or whole_save_data
end)

hook.Add("InitPostEntity", "nz_level_system_entity_init_hook", function()
	--
	if sql_mode then create_db() end
end)

--hooks
hook.Add("PlayerDisconnected", "nz_level_system_disconnect_hook", function(ply)
	--
	save_function(ply)
	
	ply:NZLSRemoveData()
end)

hook.Add("PlayerFullLoad", "nz_level_system_full_load_hook", function(ply)
	--custom hook
	ply:NZLSResetData()
end)

hook.Add("PlayerInitialSpawn", "nz_level_system_ply_init_hook", function(ply)
	--we can't send net messages through PlayerInitialSpawn hook, as the message doesn't always reach the client
	--so we create a new hook named PlayerFullLoad
	hook.Add("SetupMove", ply, function(self, ply, _, cmd)
		--and yes, we are using the player as the identifier
		if self == ply and not cmd:IsForced() then
			hook.Run("PlayerFullLoad", self)
			hook.Remove("SetupMove", self)
		end
	end)
end)

hook.Add("Think", "nz_level_system_think_hook", function()
	--TODO use a bitwise system to determine what networked value needs updating
	--re-evaluate wether this ^ is necessary
	if check_exp then
		for user_id, needs_check in pairs(check_exp_list) do
			local ply = Player(user_id)
			
			ply:SetNWInt("nz_ls_exp", get_exp(ply))
		end
		
		check_exp_list = {}
	end
	
	check_exp = false
end)