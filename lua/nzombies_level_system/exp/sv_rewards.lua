print("Rewards loaded")

local rewarded_revives_max = 3 --TODO make a convar for this
local rewarded_revives = 0

hook.Add("OnBossKilled", "nz_level_system_kill_hook", function()
	print("BOSS KILL! everyone gets rewards")
	PrintMessage(HUD_PRINTTALK, "BOSS KILL! Everyone gets rewards.")
	
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
	
	for _, ply in pairs(player.GetHumans()) do ply:NZLSAddExperience(math.floor(ply:GetPoints() / 500)) end
end)

hook.Add("OnZombieKilled", "nz_level_system_kill_hook", function(enemy, attacker, dmginfo, hitgroup)
	--give 5 exp for killing a zombie and 15 for a headshot kill
	if enemy.MarkedForDeath or not attacker then return end
	
	if isentity(attacker) and attacker:IsPlayer() then
		if hitgroup == HITGROUP_HEAD then attacker:NZLSAddExperience(15)
		else attacker:NZLSAddExperience(5) end
	end
end)

hook.Add("PlayerRevived", "nz_level_system_revive_hook", function()
	--give everyone exp for reviving a player, up to 3 times per round
	if rewarded_revives > 0 then
		local exp_bonus = math.Clamp(nzRound.Number * 2 + 48 - (rewarded_revives_max -  rewarded_revives) * 5, 20, 200)
		rewarded_revives = rewarded_revives - 1
		
		for _, ply in pairs(player.GetHumans()) do ply:NZLSAddExperience(exp_bonus) end
	end
end)