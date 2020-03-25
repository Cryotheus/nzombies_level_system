print("Core loaded (server realm)")
print(load_script)

--shared functions

include("fn_core")

--not shared stuff

local rewarded_revives_max = 3 --TODO make a convar for this

local check_exp = false
local check_exp_list = {}
local file_path = "nz_level_system/"
local file_path_players = file_path .. "players/"
local ply_data = {}
local ply_meta = FindMetaTable("Player")
local rewarded_revives = 0
local sql_mode = false

local nz_ls_save_sql = CreateConVar("nz_ls_save_sql", "0", {FCVAR_ARCHIVE, FCVAR_NEVER_AS_STRING}, string helptext, number min = nil, number max = nil )

--functions

------------------------------------------------------------------------------------------
--                                                                                      --
-- USING access_pd TO SET VALUES PROBABLY WONT WORK, USE ply_data[ply:UserID()] INSTEAD --
--                                                                                      --
------------------------------------------------------------------------------------------

local function access_pd(ply)
	--because I'm lazy
	return ply_data[ply:UserID()]
end

local function async_path(steam_id)
	--I structure the files in a way that no folder has more than 10 files and 10 folders
	--this way, if we have to search through all of them we can do it asynchronously so the server does not experience major lag
	local digits = string.sub(steam_id, 11)
	local path = file_path_players .. steam_id[9] .. "/"
	
	--we use table.Count instead of # as table.Count is more efficient
	for place = 1, table.Count(digits) do path = path .. digits[place] .. "/" end
	
	return path
end

local function get_exp(ply)
	--get the player's current exp
	return  access_pd(ply).experience or 0
end

local function get_level(ply)
	--get the player's current level
	return calc_level(get_exp(ply))
end

local function get_points(ply)
	--returns the total amount of skill points they have been given
	return access_pd(ply).points or 0
end

local function get_points_eaten(ply)
	--returns how many skill points they have spent
	return access_pd(ply).points_used or 0
end

local function get_points_left(ply)
	--gets the amount of skill points they have left
	local pd = access_pd(ply)
	
	return get_points(pd) - get_points_eaten(pd)
end

local function get_skills(ply)
	--
	return access_pd(ply).skills
end

local function get_skill_level(ply, skill_name)
	--returns how many times the skill has been leveled
	return IsValid(ply) and access_pd(ply).skills[skill_name] or 0
end

local function save_skills(ply, path)
	--save only the skills
	file.Write(path .. "skills.json", util.TableToJSON(get_skills(ply), true))
end

local function save_stats(ply, path)
	--save their statistics like exp, points, etc.
	local stats = access_pd(ply)
	
	stats.skills = nil
	
	file.Write(path .. "stats.json", util.TableToJSON(get_skills(ply), true))
end

local function set_exp(ply, amount)
	--sets the player's exp
	access_pd(ply).experience = amount
end

local function set_points(ply, amount)
	--sets the total amount of skill points they have been given
	access_pd(ply).points = amount
end

local function set_points_eaten(ply, amount)
	--sets how many skill points they have spent
	access_pd(ply).points_used = amount
end

local function set_skill_level(ply, skill_name, level)
	--sets how many times the skill has been leveled
	local old_level = get_skill_level(ply, skill_name)
	
	if level ~= old_level then
		local skill = nz_level_system.skills[skill_name]
		
		if skill.OnLevelChangedPre then skill.OnLevelChangedPre(ply, old_level, level) end
		
		ply_data[ply:UserID()].skills[skill_name] = level
		
		if skill.OnLevelChangedPost then skill.OnLevelChangedPost(ply, old_level, level) end
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

function ply_meta:NZLSAddExperience(amount)
	--this will make the information on the client get updated
	--print("Used player meta function AddExperience")
	
	check_exp = true
	check_exp_list[self:UserID()] = true
	
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
	--print("Used player meta function AddPoints")
	
	set_points(self, get_points(self) + amount)
end

function ply_meta:NZLSGetExperience()
	--
	--print("Used player meta function GetExperience")
	
	return get_exp(self)
end

function ply_meta:NZLSGetLevel()
	--
	--print("Used player meta function GetLevel")
	return get_level(self)
end

function ply_meta:NZLSGetSkillLevel(skill_name)
	--
	--print("Used player meta function GetSkillLevel")
	return get_skill_level(self, skill_name)
end

function ply_meta:NZLSSetExperience(amount)
	--
	--print("Used player meta function SetExperience")
	set_exp(amount)
end

function ply_meta:NZLSSetPoints(amount)
	--
	--print("Used player meta function SetPoints")
	set_points(self, amount)
end

function ply_meta:NZLSSetSkillLevel(skill_name, level)
	--
	--print("Used player meta function SetSkillLevel")
	set_skill_level(self, skill_name, level)
end

function ply_meta:NZLSRemoveData()
	--
	ply_data[self:UserID()] = {}
end

function ply_meta:NZLSResetData()
	self:NZLSRemoveData()
	
	local pd = access_pd(self)
	
	pd.experience = 0
	pd.points = 0
	pd.points_used = 0
	pd.skills = {}
	
	--print("Resetting data for player " .. self:Nick())
	--PrintTable(access_pd(self))
end

------------------------------------------------------------------------------------------
--                                                                                      --
-- USING access_pd TO SET VALUES PROBABLY WONT WORK, USE ply_data[ply:UserID()] INSTEAD --
--                                                                                      --
------------------------------------------------------------------------------------------

--commands

concommand.Add("nz_ls_give_skill", function(ply, cmd, args)
	local skill_name = args[1]
	
	if nz_level_system.skills[skill_name] then
		local level = tonumber(args[2])
		local max = nz_level_system.skills[skill_name].MaxLevelPrestige or nz_level_system.skills[skill_name].MaxLevel
		
		if level and level > 0 and level <= max then
			ply:PrintMessage(HUD_PRINTTALK, "Set skill " .. skill_name .. " to level " .. level .. ".")
			ply:NZLSSetSkillLevel(skill_name, level)
		else
			ply:PrintMessage(HUD_PRINTTALK, "Specified skill can only have a level from 0 to " .. (max or "nil"))
		end
	else
		ply:PrintMessage(HUD_PRINTTALK, "Skill does not exist with name " .. (skill_name or "nil"))
	end
end, _, "Gives the skill at the specified level.")

concommand.Add("nz_ls_pd", function(ply, cmd, args)
	local skill_name = args[1]
	
	PrintTable(access_pd(ply), 1)
end, _, "Gives the skill at the specified level.")

cvars.AddChangeCallback("nz_ls_save_sql", function(name, old, new)
	--
	sql_mode = nz_ls_save_sql:GetBool()
end)

--hooks
hook.Add("OnBossKilled", "nz_level_system_kill_hook", function()
	print("BOSS KILL! everyone gets rewards")
	PrintMessage(HUD_PRINTTALK, "BOSS KILL! everyone gets rewards")
	
	local exp_bonus = nzRound.Number * 5 + 195
	
	for _, ply in pairs(player.GetHumans()) do
		ply:NZLSAddExperience(exp_bonus)
		ply:NZLSAddPoints(1)
	end
end)

hook.Add("OnPlayerBuyPackAPunch", "nz_level_system_pap_hook", function(ply, gun)
	--give 50 exp for pack a punching a weapon
	ply:NZLSAddExperience(50)
end)

hook.Add("OnRoundPreparation", "nz_level_system_round_prep_hook", function(round)
	--give 1 exp for every 500 points they have at the end of the round
	rewarded_revives = rewarded_revives_max
	
	for _, ply in pairs(player.GetHumans()) do
		ply:NZLSAddExperience(math.floor(ply:GetPoints() / 500))
	end
end)

hook.Add("OnZombieKilled", "nz_level_system_kill_hook", function(enemy, attacker, dmginfo, hitgroup)
	--give 5 exp for killing a zombie and 15 for a headshot kill
	if enemy.MarkedForDeath or not attacker then return end
	
	print("Attacker ", attacker)
	
	if isentity(attacker) and attacker:IsPlayer() then
		if hitgroup == HITGROUP_HEAD then attacker:NZLSAddExperience(15)
		else attacker:NZLSAddExperience(5) end
	end
end)

hook.Add("PlayerDisconnected", "nz_level_system_disconnect_hook", function(ply)
	--
	whole_save(ply)
	
	ply:NZLSRemoveData()
end)

hook.Add("PlayerInitialSpawn", "nz_level_system_ply_init_hook", function(ply)
	--
	ply:NZLSResetData()
end)

hook.Add("PlayerRevived", "nz_level_system_revive_hook", function()
	--give everyone r * 2 + 48 exp for reviving a player, up to 3 per round
	if rewarded_revives > 0 then
		local exp_bonus = math.Clamp(nzRound.Number * 2 + 48 - (rewarded_revives_max -  rewarded_revives) * 5, 20, 200)
		rewarded_revives = rewarded_revives - 1
		
		for _, ply in pairs(player.GetHumans()) do ply:NZLSAddExperience(exp_bonus) end
	end
end)

--TODO use a bitwise system to determine what networked value needs updating
hook.Add("Think", "nz_level_system_think_hook", function()
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
