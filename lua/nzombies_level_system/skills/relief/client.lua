local SKILL = include("shared.lua")

SKILL.Description = "At the end of each round, you recover " .. SKILL.Mult .. " armor per point invested. Recovers up to a max of 100."
SKILL.PrintName = "Relief"
SKILL.Icon = Material("gui/nzombies_level_system/skillicons/relief.png")
SKILL.X = 100
SKILL.Y = -100

return SKILL