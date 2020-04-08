local SKILL = {}

SKILL.Cost = function(level) return math.floor(level * 4.5) end
SKILL.CostPrestige = function(level) return 5 end
SKILL.Mult = 100
SKILL.MaxLevel = 5
SKILL.MaxLevelPrestige = 6
SKILL.Requirements = {["Level"] = 5}

return SKILL