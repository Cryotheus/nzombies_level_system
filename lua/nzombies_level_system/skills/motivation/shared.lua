local SKILL = {}

SKILL.Cost = function(level) return level * 4.5 end
SKILL.CostPrestige = function(level) return 5 end
SKILL.Mult = 100
SKILL.MaxLevel = 4
SKILL.MaxLevelPrestige = 2
SKILL.Requirements = {Level = 4}

return SKILL