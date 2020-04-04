local SKILL = {}

SKILL.Cost = function(level) return level * 5 end
SKILL.CostPrestige = function(level) return level * 5 end
SKILL.Mult = 5
SKILL.MaxLevel = 4
SKILL.MaxLevelPrestige = 2
SKILL.Requirements = {["level"] = 20}

return SKILL