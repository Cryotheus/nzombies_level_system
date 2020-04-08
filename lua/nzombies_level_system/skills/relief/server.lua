local SKILL = include("shared.lua")

local function calc_mult(ply, level)
	--calculate how much of a bonus they get
	--if the level parameter is not specified, then fetch the level
	if level then return level * SKILL.Mult end
	
	return ply:NZLSGetSkillLevelSum("relief") * SKILL.Mult
end

hook.Add("OnRoundPreparation", "nz_ls_armor_skill_prep_hook", function(round)
	timer.Create("nz_ls_motivation_skill_timer", 2, 1, function()
		for _, ply in pairs(player.GetHumans()) do
			if not ply then continue end
			
			ply:AddArmor(calc_mult(ply), 100)
		end
	end)
end)

return SKILL