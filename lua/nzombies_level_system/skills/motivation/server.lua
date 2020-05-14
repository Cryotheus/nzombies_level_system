local SKILL = include("shared.lua")

local function calc_mult(ply)
	--calculate how much of a bonus they get
	
	return ply:NZLSHasData() and ply:NZLSGetSkillLevelSum("motivation") * SKILL.Mult or 0
end

hook.Add("PlayerSpawn", "nz_ls_motivation_skill_spawn_hook", function(ply)
	timer.Create("nz_ls_motivation_skill_timer", 0.1, 1, function()
		ply:SetArmor(calc_mult(ply))
	end)
end)

return SKILL