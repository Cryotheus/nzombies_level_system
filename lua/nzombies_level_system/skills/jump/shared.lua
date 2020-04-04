local SKILL = {}

SKILL.Cost = function(level) return level + 1 end
--SKILL.CostPrestige is not required
SKILL.Mult = 0.1
SKILL.MaxLevel = 10
--SKILL.MaxLevelPrestige is not required
SKILL.Requirements = {["level"] = 3}

return SKILL