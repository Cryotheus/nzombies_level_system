print("Armor loaded (server realm)")

local ply_armor = {}
local ply_meta = FindMetaTable("Player")
local max_armor = 255 --hardcoded value in two places in the source engine :(

local fl_Armor = ply_meta:Armor
local fl_SetArmor = ply_meta:SetArmor

local function get_armor(ply) return
	local armor = ply_armor[self:UserID()]
	
	return armor and armor ~= 0 and armor + fl_Armor(ply) or fl_Armor(ply)
end

local function set_armor(ply, amount)
	fl_SetArmor(ply, math.min(max_armor, amount))
	
	ply_armor[self:UserID()] = math.max(0, amount - max_armor)
end

--globals

function ply_meta:AddArmor(amount, max)
	--add amount to armor, supports an optional maximum
	if max then
		local armor = get_armor(self)
		
		set_armor(self, armor + math.Clamp(max - armor, 0, amount))
	else set_armor(self, get_armor(self) + amount) end
end

function ply_meta:Armor() return get_armor(self) end

function ply_meta:SetArmor(amount)
	--
	set_armor(self, amount)
end