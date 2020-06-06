local SKILL = {}

SKILL.Cost = function(level) return level + 1 end
--SKILL.CostPrestiege is not required
SKILL.Mult = 0.1
SKILL.MaxLevel = 10
--SKILL.MaxLevelPrestiege is not required
SKILL.Requirements = {Level = 3}

return SKILL