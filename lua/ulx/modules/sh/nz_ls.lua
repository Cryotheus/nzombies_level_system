local CATEGORY_NAME = "nZombies Level System"

local ulx_completes_skills = {}

if NZLS and NZLS.skills then for skill, data in pairs(NZLS.skills) do table.insert(ulx_completes_skills, skill) end
else ulx_completes_skills = {"armor", "jump", "sprint"} end

function ulx.nzlsaddexp(ply, targets, amount)
	for _, target in pairs(targets) do target:NZLSAddExperience(amount) end
	
	ulx.fancyLogAdmin(ply, true, "#A gave #T " .. amount .. " experience.", targets)
end

function ulx.nzlsaddlevels(ply, targets, levels)
	for _, target in pairs(targets) do
		local amount = NZLSCalcExp(NZLSCalcLevel(target:NZLSGetExperience()) + levels)
		
		target:NZLSSetExperience(amount)
	end
	
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

function ulx.nzlssetlevel(ply, targets, level)
	local amount = NZLSCalcExp(level)
	
	for _, target in pairs(targets) do target:NZLSSetExperience(amount) end
	
	ulx.fancyLogAdmin(ply, true, "#A set the level of #T to " .. level .. ".", targets)
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

--usage: ulx nzlsaddexp T:targets I:exp
local ulx_add_exp = ulx.command(CATEGORY_NAME, "ulx nzlsaddexp", ulx.nzlsaddexp)
ulx_add_exp:addParam{["type"] = ULib.cmds.PlayersArg}
ulx_add_exp:addParam{["type"] = ULib.cmds.NumArg, ["min"] = 1, ["hint"] = "exp", ULib.cmds.round}
ulx_add_exp:defaultAccess(ULib.ACCESS_SUPERADMIN)

--usage: ulx nzlsaddlevels T:targets I:levels
local ulx_add_levels = ulx.command(CATEGORY_NAME, "ulx nzlsaddlevels", ulx.nzlsaddlevels)
ulx_add_levels:addParam{["type"] = ULib.cmds.PlayersArg}
ulx_add_levels:addParam{["type"] = ULib.cmds.NumArg, ["min"] = 1, ["hint"] = "levels", ULib.cmds.round}
ulx_add_levels:defaultAccess(ULib.ACCESS_SUPERADMIN)

--usage: ulx nzlsaddpoints T:targets I:points <B:prestiege?>
local ulx_add_points = ulx.command(CATEGORY_NAME, "ulx nzlsaddpoints", ulx.nzlsaddpoints)
ulx_add_points:addParam{["type"] = ULib.cmds.PlayersArg}
ulx_add_points:addParam{["type"] = ULib.cmds.NumArg, ["min"] = 1, ["hint"] = "points", ULib.cmds.round}
ulx_add_points:addParam{["type"] = ULib.cmds.BoolArg, ULib.cmds.optional, ["hint"] = "prestiege"}
ulx_add_points:defaultAccess(ULib.ACCESS_SUPERADMIN)

--usage: ulx nzlssetexp T:targets I:exp
local ulx_set_exp = ulx.command(CATEGORY_NAME, "ulx nzlssetexp", ulx.nzlssetexp)
ulx_set_exp:addParam{["type"] = ULib.cmds.PlayersArg}
ulx_set_exp:addParam{["type"] = ULib.cmds.NumArg, ["min"] = 0, ["hint"] = "exp", ULib.cmds.round}
ulx_set_exp:defaultAccess(ULib.ACCESS_SUPERADMIN)

--usage: ulx nzlssetlevel T:targets I:level
local ulx_set_level = ulx.command(CATEGORY_NAME, "ulx nzlssetlevel", ulx.nzlssetlevel)
ulx_set_level:addParam{["type"] = ULib.cmds.PlayersArg}
ulx_set_level:addParam{["type"] = ULib.cmds.NumArg, ["min"] = 0, ["hint"] = "level", ULib.cmds.round}
ulx_set_level :defaultAccess(ULib.ACCESS_SUPERADMIN)

--usage: ulx nzlssetpoints T:targets I:amount <B:prestiege?>
local ulx_set_points = ulx.command(CATEGORY_NAME, "ulx nzlssetpoints", ulx.nzlssetpoints)
ulx_set_points:addParam{["type"] = ULib.cmds.PlayersArg}
ulx_set_points:addParam{["type"] = ULib.cmds.NumArg, ["min"] = 0, ["hint"] = "points", ULib.cmds.round}
ulx_set_points:addParam{["type"] = ULib.cmds.BoolArg, ULib.cmds.optional, ["hint"] = "prestiege"}
ulx_set_points:defaultAccess(ULib.ACCESS_SUPERADMIN)

--usage: ulx nzlssetskill T:targets S:skill <I:level=0>
local ulx_set_skill = ulx.command(CATEGORY_NAME, "ulx nzlssetskill", ulx.nzlssetskill)
ulx_set_skill:addParam{["type"] = ULib.cmds.PlayersArg}
ulx_set_skill:addParam{["type"] = ULib.cmds.StringArg, ["hint"] = "skill", ["completes"] = table.Copy(ulx_completes_skills)}
ulx_set_skill:addParam{["type"] = ULib.cmds.NumArg, ["min"] = 0, ["max"] = 15, ["default"] = 0, ["hint"] = "level", ULib.cmds.optional, ULib.cmds.round}
ulx_set_skill:defaultAccess(ULib.ACCESS_SUPERADMIN)
