local SKILL = {}

SKILL.Cost = function(level) return level * 0.5 + 0.5 end
SKILL.CostPrestiege = function(level) return 1 end
SKILL.Mult = 7.5
SKILL.MaxLevel = 3
SKILL.MaxLevelPrestiege = 1
SKILL.Requirements = {}

return SKILL