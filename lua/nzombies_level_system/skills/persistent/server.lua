local SKILL = include("shared.lua")

local function calc_mult(ply)
	--calculate how much of a bonus they get
	return ply:NZLSGetSkillLevelSum("persistent") * SKILL.Mult
end

hook.Add("PlayerDowned", "nz_ls_persistent_skill_down_hook", function(who)
	if who then
		local id = who:EntIndex()
		local mult = who:IsPlayer() and calc_mult(who) or calc_mult(who:GetPerkOwner())
		
		nzRevive.Players[id].DownTimeMax = nzRevive.Players[id].DownTimeMax + mult
	end
end)

return SKILL