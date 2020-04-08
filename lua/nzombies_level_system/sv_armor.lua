print("Armor loaded (server realm)")

local ply_armor = {}
local ply_meta = FindMetaTable("Player")
local max_armor = 255 --hardcoded value in two places in the source engine :(

local fl_Armor = ply_meta.Armor
local fl_SetArmor = ply_meta.SetArmor

local function get_armor(ply)
	--get the player's armor including the extra in ply_armor
	local armor = ply_armor[ply:UserID()]
	
	return armor and armor ~= 0 and armor + fl_Armor(ply) or fl_Armor(ply)
end

local function set_armor(ply, amount)
	--set the player's armor, and store the extra in ply_armor
	fl_SetArmor(ply, math.min(max_armor, amount))
	
	ply_armor[ply:UserID()] = math.max(0, amount - max_armor)
end

local function update_armor(ply)
	--use the extra armor to replenish the player's lost armor
	print("updating armor on player", ply)
	
	local armor = fl_Armor(ply)
	local extra_armor = ply_armor[ply:UserID()]
	local missing = max_armor - armor
	local replenish = math.min(missing, extra_armor)
	
	fl_SetArmor(ply, armor + replenish)
	
	ply_armor[ply:UserID()] = extra_armor - replenish
end

--globals

function ply_meta:AddArmor(amount, max)
	--add amount to armor, supports an optional maximum
	if self:Alive() then
		if max then
			local armor = get_armor(self)
			
			set_armor(self, armor + math.Clamp(max - armor, 0, amount))
		else set_armor(self, get_armor(self) + amount) end
	end
end

function ply_meta:Armor() return get_armor(self) end
function ply_meta:SetArmor(amount) if self:Alive() then set_armor(self, amount) end end

--hooks

hook.Add("PlayerDisconnected", "nz_level_system_disconnect_hook", function(ply) ply_armor[ply:UserID()] = nil end)
hook.Add("PlayerInitialSpawn", "nz_level_system_ply_init_hook", function(ply) ply_armor[ply:UserID()] = 0 end)
hook.Add("PostEntityTakeDamage", "nz_level_system_damage_hook", function(ply, dmginfo, took) if took and ply and ply:IsPlayer() then update_armor(ply) end end)
hook.Add("PostPlayerDeath", "nz_level_system_ply_init_hook", function(ply) ply_armor[ply:UserID()] = 0 end)