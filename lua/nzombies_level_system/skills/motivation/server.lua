local SKILL = include("shared.lua")

local function calc_mult(ply, level)
	--calculate how much of a bonus they get
	--if the level parameter is not specified, then fetch the level
	if level then return level * SKILL.Mult end
	
	return ply:NZLSGetSkillLevelSum("motivation") * SKILL.Mult
end

hook.Add("PlayerSpawn", "nz_ls_motivation_skill_spawn_hook", function(ply)
	timer.Create("nz_ls_motivation_skill_timer", 0.1, 1, function()
		ply:SetArmor(calc_mult(ply))
	end)
end)

return SKILL