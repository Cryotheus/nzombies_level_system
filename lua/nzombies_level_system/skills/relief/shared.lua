local SKILL = {}

SKILL.Cost = function(level) return level * 5 end
SKILL.CostPrestiege = function(level) return level * 5 end
SKILL.Mult = 5
SKILL.MaxLevel = 4
SKILL.MaxLevelPrestiege = 2
SKILL.Requirements = {
	Level = 10,
	Skills = {
		motivation = 2
	}
}

return SKILL