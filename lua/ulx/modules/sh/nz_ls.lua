local CATEGORY_NAME = "nZombies Level System"

local ulx_completes_skills = {}

if NZLS and NZLS.skills then for skill, data in pairs(NZLS.skills) do table.insert(ulx_completes_skills, skill) end
else ulx_completes_skills = {"armor", "jump", "sprint"} end

function ulx.nzlsaddexp(ply, targets, amount)
	for _, target in pairs(targets) do target:NZLSAddExperience(amount) end
	
	ulx.fancyLogAdmin(ply, true, "#A gave #T " .. amount .. " experience.", targets)
end

function ulx.nzlsaddpoints(ply, targets, amount, prestiege)
	if prestiege then for _, target in pairs(targets) do target:NZLSAddPointsPrestiege(amount) end
	else for _, target in pairs(targets) do target:NZLSAddPoints(amount) end end
	
	ulx.fancyLogAdmin(ply, true, "#A gave #T " .. amount .. (prestiege and " prestiege points." or " points."), targets)
end

function ulx.nzlssetexp(ply, targets, amount)
	for _, target in pairs(targets) do target:NZLSSetExperience(amount) end
	
	ulx.fancyLogAdmin(ply, true, "#A set the experience of #T to " .. amount .. ".", targets)
end

function ulx.nzlssetpoints(ply, targets, amount, prestiege)
	if prestiege then for _, target in pairs(targets) do target:NZLSSetPointsPrestiege(amount) end
	else for _, target in pairs(targets) do target:NZLSSetPoints(amount) end end
	
	ulx.fancyLogAdmin(ply, true, (prestiege and "#A set the prestiege points of #T to " or "#A set the points of #T to ") .. amount .. ".", targets)
end

function ulx.nzlssetskill(ply, targets, skill_name, level)
	if NZLS.skills[skill_name] then
		local data = NZLS.skills[skill_name]
		local max_level = data.MaxLevel
		local max_level_prestiege = data.MaxLevelPrestige or 0
		
		if level and level >= 0 and level <= max_level + max_level_prestiege then
			for _, target in pairs(targets) do target:NZLSSetSkillLevelSum(skill_name, level) end
			
			ply:PrintMessage(HUD_PRINTCONSOLE, "[nZLS] Set skill " .. skill_name .. " to level " .. level .. ".")
		else ply:PrintMessage(HUD_PRINTCONSOLE, "[nZLS] Specified skill can only have a level from 0 to " .. ((max_level + max_level_prestiege) or "nil")) end
	else ply:PrintMessage(HUD_PRINTCONSOLE, "[nZLS] Skill does not exist with name " .. (skill_name or "nil")) end
end

--usage: ulx nzlsaddexp T:targets I:amount
local ulx_add_exp = ulx.command(CATEGORY_NAME, "ulx nzlsaddexp", ulx.nzlsaddexp)
ulx_add_exp:addParam{["type"] = ULib.cmds.PlayersArg}
ulx_add_exp:addParam{["type"] = ULib.cmds.NumArg, ["min"] = 1, ["max"] = 2147483647, ["hint"] = "amount", ULib.cmds.round}
ulx_add_exp:defaultAccess(ULib.ACCESS_SUPERADMIN)

--usage: ulx nzlsaddpoints T:targets I:amount <B:prestiege?>
local ulx_add_points = ulx.command(CATEGORY_NAME, "ulx nzlsaddpoints", ulx.nzlsaddpoints)
ulx_add_points:addParam{["type"] = ULib.cmds.PlayersArg}
ulx_add_points:addParam{["type"] = ULib.cmds.NumArg, ["min"] = 1, ["max"] = 2147483647, ["hint"] = "amount", ULib.cmds.round}
ulx_add_points:addParam{["type"] = ULib.cmds.BoolArg, ULib.cmds.optional, ["hint"] = "prestiege"}
ulx_add_points:defaultAccess(ULib.ACCESS_SUPERADMIN)

--usage: ulx nzlssetexp T:targets I:amount
local ulx_set_exp = ulx.command(CATEGORY_NAME, "ulx nzlssetexp", ulx.nzlssetexp)
ulx_set_exp:addParam{["type"] = ULib.cmds.PlayersArg}
ulx_set_exp:addParam{["type"] = ULib.cmds.NumArg, ["min"] = 1, ["max"] = 2147483647, ["hint"] = "amount", ULib.cmds.round}
ulx_set_exp:defaultAccess(ULib.ACCESS_SUPERADMIN)

--usage: ulx nzlssetpoints T:targets I:amount <B:prestiege?>
local ulx_set_points = ulx.command(CATEGORY_NAME, "ulx nzlssetpoints", ulx.nzlssetpoints)
ulx_set_points:addParam{["type"] = ULib.cmds.PlayersArg}
ulx_set_points:addParam{["type"] = ULib.cmds.NumArg, ["min"] = 1, ["max"] = 2147483647, ["hint"] = "amount", ULib.cmds.round}
ulx_set_points:addParam{["type"] = ULib.cmds.BoolArg, ULib.cmds.optional, ["hint"] = "prestiege"}
ulx_set_points:defaultAccess(ULib.ACCESS_SUPERADMIN)

--usage: ulx nzlssetskill T:targets S:skill <I:level=0>
local ulx_set_skill = ulx.command(CATEGORY_NAME, "ulx nzlssetskill", ulx.nzlssetskill)
ulx_set_skill:addParam{["type"] = ULib.cmds.PlayersArg}
ulx_set_skill:addParam{["type"] = ULib.cmds.StringArg, ["hint"] = "skill", ["completes"] = table.Copy(ulx_completes_skills)}
ulx_set_skill:addParam{["type"] = ULib.cmds.NumArg, ["min"] = 0, ["max"] = 15, ["default"] = 0, ["hint"] = "level", ULib.cmds.optional, ULib.cmds.round}
ulx_set_skill:defaultAccess(ULib.ACCESS_SUPERADMIN)

