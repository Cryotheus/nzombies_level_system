local SKILL = include("shared.lua")

SKILL.Description = "You stay alive while down for an extra " .. SKILL.Mult .. " seconds per point invested."
SKILL.PrintName = "Persistent"
SKILL.Icon = Material("gui/nzombies_level_system/skillicons/wip.png")
SKILL.X = -300
SKILL.Y = 100

return SKILL