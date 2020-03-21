local SKILL = include("shared.lua")

local current_jump_power = 0
local ply_meta = FindMetaTable("Player")
local fl_ply_meta_GetJumpPower = ply_meta.GetJumpPower
local fl_ply_meta_SetJumpPower = ply_meta.SetJumpPower

local function calc_mult(ply, level)
	--calculate how much of a bonus they get
	--if the level parameter is not specified, then fetch the level
	if level then return level * SKILL.Mult + 1 end
	
	return ply:NZLSGetSkillLevel("jump") * SKILL.Mult + 1
end

function ply_meta:GetJumpPower()
	--make a detour for both of these, so they always have the jump bonus
	return fl_ply_meta_GetJumpPower(self) / calc_mult(self)
end

function ply_meta:SetJumpPower(power)
	--make a detour for both of these, so they always have the jump bonus
	fl_ply_meta_SetJumpPower(self, power * calc_mult(self))
end

function SKILL.OnLevelChangedPre(ply, old_level, level)
	--[[DOCS: 	Runs before the skill is changed
				GetSkillLevel will return the same as old_level if run here]]
	--get the jump power before the change
	current_jump_power = ply:GetJumpPower()
end

function SKILL.OnLevelChangedPost(ply, old_level, level)
	--[[DOCS: 	Runs after the skill is changed
				GetSkillLevel will return the same as level if run here]]
	--set the jump power with the proper power
	ply:SetJumpPower(current_jump_power)
end

return SKILL