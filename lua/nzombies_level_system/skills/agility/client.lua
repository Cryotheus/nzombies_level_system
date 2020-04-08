local SKILL = include("shared.lua")

SKILL.Description = "Increase your run speed by " .. SKILL.Mult * 100 .. "% per point."
SKILL.PrintName = "Agility"
SKILL.Icon = Material("gui/nzombies_level_system/skillicons/agility.png")
SKILL.X = 100
SKILL.Y = 100

return SKILL