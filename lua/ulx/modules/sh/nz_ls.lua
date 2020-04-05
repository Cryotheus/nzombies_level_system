local CATEGORY_NAME = "nZombies Level System"

local ulx_completes_skills = {}
--lua_run local ulx_completes_skills for skill in pairs(NZLS.skills) do table.insert(ulx_completes_skills, skill) end PrintTable(ulx_completes_skills)
if NZLS and NZLS.skills then for skill, data in pairs(NZLS.skills) do table.insert(ulx_completes_skills, skill) end
else ulx_completes_skills = {"armor", "jump", "sprint"} end

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

--usage: ulx nzlssetskill skill level 
--function ulx.command(category, command, fn, say_cmd, hide_say, nospace, unsafe)
--local ulx_set_skill = ulx.command(CATEGORY_NAME, "ulx nzlssetskill", ulx.nzlssetskill, _, false, false, true)
local ulx_set_skill = ulx.command(CATEGORY_NAME, "ulx nzlssetskill", ulx.nzlssetskill)

ulx_set_skill:addParam{["type"] = ULib.cmds.PlayersArg}
ulx_set_skill:addParam{["type"] = ULib.cmds.StringArg, hint = "skill", completes = table.Copy(ulx_completes_skills)}
ulx_set_skill:addParam{["type"] = ULib.cmds.NumArg, min = 0, max = 15, default = 0, hint = "level", ULib.cmds.optional, ULib.cmds.round}
ulx_set_skill:defaultAccess(ULib.ACCESS_SUPERADMIN)
