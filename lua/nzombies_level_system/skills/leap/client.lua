local SKILL = include("shared.lua")

SKILL.Description = "Jump " .. SKILL.Mult * 100 .. "% higher per point invested."
SKILL.PrintName = "Leap"
SKILL.Icon = Material("gui/nzombies_level_system/skillicons/leap.png")
SKILL.X = -100
SKILL.Y = 100

return SKILL