print("Core loaded")

--shared functions

local function calc_exp(level)
	--calculate exp from level
	--also num * num is cheaper than 
	return level * level * 100
end

local function calc_level(exp)
	--calculate level from exp
	return math.floor(math.sqrt(exp / 100))
end

--not shared stuff

if SERVER then
	--SERVER
	
	local check_exp = false
	local check_exp_list = {}
	local ply_data = {}
	local ply_meta = FindMetaTable("Player")
	
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
	
	local function get_skill_level(ply, skill_name)
		--returns how many times the skill has been leveled
		return access_pd(ply).skills[skill_name] or 0
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
	
	--hooks
	hook.Add("OnBossKilled", "nz_level_system_kill_hook", function()
		print("BOSS KILL! everyone gets rewards")
		
		local exp_bonus = nzRound.Number * 5 + 95
		
		for _, ply in player.GetHumans() do
			ply:NZLSAddExperience(exp_bonus)
			ply:NZLSAddPoints(1)
		end
	end)
	
	hook.Add("OnZombieKilled", "nz_level_system_kill_hook", function(enemy, attacker, dmginfo, hitgroup)
		if enemy.MarkedForDeath or not attacker then return end
		
		print("Attacker ", attacker)
		
		if isentity(attacker) and attacker:IsPlayer() then
			if hitgroup == HITGROUP_HEAD then attacker:NZLSAddExperience(15)
			else attacker:NZLSAddExperience(5) end
		end
	end)
	
	hook.Add("PlayerDisconnected", "nz_level_system_disconnect_hook", function(ply)
		--
		ply:NZLSRemoveData()
	end)
	
	hook.Add("PlayerInitialSpawn", "nz_level_system_ply_init_hook", function(ply)
		--
		ply:NZLSResetData()
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
else
	--CLIENT
	
	local current_level = 0
	local exp = 0
	local exp_passed = 0
	local exp_required = 0
	local local_player = nil
	local percent = 0
	
	local scr_h = 0
	local scr_w = 0
	
	local bar_bg_corner = 0
	local bar_bg_h = 0
	local bar_bg_w = 0
	local bar_bg_x = 0
	local bar_bg_y = 0
	local bar_corner = 0
	local bar_h = 0
	local bar_level_text = ""
	local bar_level_text_font = ""
	local bar_level_text_x = 0
	local bar_level_text_y = 0
	local bar_scale = 1
	local bar_w = 0
	local bar_x = 0
	local bar_y = 0
	local color_blood = Color(128, 32, 32)
	local percent_bar_w = 0
	
	--I have a table for this specific font I use in my progress bar addon. This will keep me from making duplicvate fonts
	--I may make the functions themself global, but for now I'll have it like this
	CryotheumDynamicFontData = CryotheumDynamicFontData or {}
	
	local function calc_vars()
		scr_h = ScrH()
		scr_w = ScrW()
		
		bar_bg_corner = 8 * bar_scale
		bar_bg_h = 16 * bar_scale
		bar_bg_w = 388 * bar_scale
		bar_bg_x = (scr_w - bar_bg_w) / 2
		bar_bg_y = scr_h - bar_bg_h - bar_scale * 4
		bar_corner = 4 * bar_scale
		bar_h = 8 * bar_scale
		bar_level_text_x = scr_w / 2
		bar_level_text_y = scr_h - bar_h - bar_scale * 12
		bar_w = 380 * bar_scale
		bar_x = (scr_w - bar_w) / 2
		bar_y = scr_h - bar_h - bar_scale * 8
	end
	
	local function create_font(size, weight)
		surface.CreateFont("pbgenfont" .. size .. "." .. weight, {
			font = "DK Umbilical Noose",
			size = size,
			weight = weight,
			antialias = true,
		})
	end
	
	local function register_font(size, weight)
		if CryotheumDynamicFontData[size] then
			if CryotheumDynamicFontData[size][weight] then return
			else
				CryotheumDynamicFontData[size][weight] = true
				
				create_font(size, weight)
			end
		else
			CryotheumDynamicFontData[size] = {[weight] = true}
			
			create_font(size, weight)
		end
	end
	
	local function set_font(size, weight)
		bar_level_text_font = "pbgenfont" .. size .. "." .. weight
		
		register_font(size, weight)
	end
	
	calc_vars()
	set_font(16 * bar_scale, 150)
	
	if not local_player then
		--make sure local_player is not nil, yes this can happen and I don't know what causes it
		--also it seems that if we define local_player as LocalPlayer() in the init it doesn't work with GetNWInt
		print("[nZ LS] Local player was invalid! Attempting to obtain the local player...")
		
		timer.Create("nz_level_system_local_player_timer", 20.0, 0, function()
			local_player = LocalPlayer()
			
			if local_player then
				calc_vars()
				print("[nZ LS] Obtained local player.")
				
				hook.Add("Think", "nz_level_system_think_hook", function()
					--
					local fetch = local_player:GetNWInt("nz_ls_exp")
					
					if fetch ~= exp then
						current_level = calc_level(fetch)
						exp = fetch
						exp_passed = calc_exp(current_level)
						exp_required = calc_exp(current_level + 1)
						percent = (exp - exp_passed) / exp_required
						percent_bar_w = percent * bar_w
						
						--we cache the text so it isn't converted every frame
						bar_level_text = tostring(current_level)
					end
				end)
				
				timer.Remove("nz_level_system_local_player_timer")
			end
		end)
	end
	
	hook.Add("OnScreenSizeChanged", "nz_ls_screen_res_changed_hook", function()
		calc_vars()
		set_font(16 * bar_scale, 150)
	end)
	
	local fl_draw_DrawText = draw.DrawText
	local fl_draw_RoundedBox = draw.RoundedBox
	
	hook.Add("HUDPaint", "nz_level_system_hud_paint_hook", function()
		--TODO possibly add stencil animations?
		fl_draw_RoundedBox(bar_bg_corner, bar_bg_x, bar_bg_y, bar_bg_w, bar_bg_h, color_black)
		fl_draw_RoundedBox(bar_corner, bar_x, bar_y, percent_bar_w, bar_h, color_blood)
		
		--I may make it more descriptive later
		fl_draw_DrawText(bar_level_text, bar_level_text_font, bar_level_text_x, bar_level_text_y, color_white, TEXT_ALIGN_CENTER)
	end)
end
