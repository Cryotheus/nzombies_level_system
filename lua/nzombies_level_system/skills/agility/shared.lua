local SKILL = {}

SKILL.Cost = function(level) return level * 2 + 1 end
SKILL.CostPrestige = function(level) return level + 1 end
SKILL.Mult = 0.05
SKILL.MaxLevel = 12
SKILL.MaxLevelPrestige = 3
SKILL.Requirements = {Level = 5}

return SKILL