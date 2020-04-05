local SKILL = include("shared.lua")

local function calc_mult(ply, level)
	--calculate how much of a bonus they get
	--if the level parameter is not specified, then fetch the level
	if level then return level * SKILL.Mult end
	
	return ply:NZLSGetSkillLevelSum("armor") * SKILL.Mult
end

hook.Add("OnRoundPreparation", "nz_ls_armor_skill_prep_hook", function(round)
	for _, ply in pairs(player.GetHumans()) do
		if not ply then continue end
		
		ply:SetArmor(math.min(ply:Armor() + calc_mult(ply) or 0, 100))
	end
end)

return SKILL