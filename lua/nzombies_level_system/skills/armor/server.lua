local SKILL = include("shared.lua")

local function calc_mult(ply, level)
	--calculate how much of a bonus they get
	--if the level parameter is not specified, then fetch the level
	if level then return level * SKILL.Mult end
	
	return ply:NZLSGetSkillLevel("armor") * SKILL.Mult
end

hook.Add("OnRoundPreparation", "nz_ls_armor_skill_prep_hook", function(round)
	for _, ply in pairs(player.GetHumans()) do
		--
		if not ply then continue
		 
		local amnt = math.min(ply:Armor() + calc_mult(ply) or 0, 100)
		
		--print("Setting player armor to " .. amnt)
		
		ply:SetArmor(amnt)
	end
end)

return SKILL