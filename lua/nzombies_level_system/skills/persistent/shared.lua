local SKILL = {}

SKILL.Cost = function(level) return level * 0.5 + 0.5 end
SKILL.CostPrestige = function(level) return 1 end
SKILL.Mult = 7.5
SKILL.MaxLevel = 3
SKILL.MaxLevelPrestige = 1
SKILL.Requirements = {}

return SKILL