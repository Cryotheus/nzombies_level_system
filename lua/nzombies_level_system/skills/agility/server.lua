local SKILL = include("shared.lua")

local current_run_speed = 300 --used to hold the run speed of the player when updating the level
local ply_meta = FindMetaTable("Player")
local fl_ply_meta_GetRunSpeed = ply_meta.GetRunSpeed
local fl_ply_meta_SetRunSpeed = ply_meta.SetRunSpeed

local function calc_mult(ply)
	if not ply or not ply:NZLSHasData() then return 1 end
	
	return ply:NZLSGetSkillLevelSum("agility") * SKILL.Mult + 1
end

function ply_meta:GetRunSpeed() return fl_ply_meta_GetRunSpeed(self) / calc_mult(self) end

function ply_meta:SetRunSpeed(speed) fl_ply_meta_SetRunSpeed(self, speed * calc_mult(self)) end

function SKILL.OnLevelChangedPre(ply, old_level, level)
	--[[DOCS: 	Runs before the skill is changed
				GetSkillLevel will return the same as old_level if run here]]
	--get the run speed before the change
	current_run_speed = ply:GetRunSpeed()
end

function SKILL.OnLevelChangedPost(ply, old_level, level)
	--[[DOCS: 	Runs after the skill is changed
				GetSkillLevel will return the same as level if run here]]
	--set the run speed with the proper speed
	ply:SetRunSpeed(current_run_speed)
end

return SKILL