local PANEL = {}

AccessorFunc(PANEL, "m_Color",					"Color")
AccessorFunc(PANEL, "m_fBackgroundParallax",	"BackgroundParallax")
AccessorFunc(PANEL, "m_fBackgroundSize",		"BackgroundSize")
AccessorFunc(PANEL, "m_fBackgroundX",			"BackgroundX")
AccessorFunc(PANEL, "m_fBackgroundY",			"BackgroundY")
AccessorFunc(PANEL, "m_Material",				"Material")

local fl_surf_DrawTexturedRectUV = surface.DrawTexturedRectUV
local fl_surf_SetDrawColor = surface.SetDrawColor
local fl_surf_SetMaterial = surface.SetMaterial

function PANEL:GenerateExample(class_name, property_sheet, w, h) 
	--example 1, follows mouse, just cosmetic
	do
		local bg_follower = vgui.Create(class_name)
		
		bg_follower:Dock(FILL)
		
		bg_follower.Think = function()
			bg_follower:SetBackgroundX(gui.MouseX())
			bg_follower:SetBackgroundY(gui.MouseY())
		end
		
		property_sheet:AddSheet(class_name .. " - Follows mouse", bg_follower, nil, true, true)
	end
	
	--example 2, explorable, allows you to have an unlimited amount of panels, in a single panel
	do
		local bg_follower = vgui.Create(class_name)
		local button_phrases = {"Right click: drag", "Customizable", "Infinite bounds", "Github", "Used in skill menu", "Made by Cryotheum", "Cryotheum#4096", "GFLClan.com", "Check em out", "They're cool", "We have a discord", "Multiple discords", "16x16 grid here", "256 buttons here", "Add any amount", "Click me!"}
		local buttons = {}
		local x_final = 0
		local y_final = 0
		
		local function update_position(x, y) for index, button_data in pairs(buttons) do button_data[1]:SetPos(button_data[2] + x, button_data[3] + y) end end
		
		local button_functions = {
			["GFLClan.com"] = function() gui.OpenURL("https://gflclan.com/") end,
			["Github"] = function() gui.OpenURL("https://github.com/Cryotheus/nzombies_level_system") end,
			["Multiple discords"] = function() gui.OpenURL("https://discord.gg/MnPD6BG") end,
			["We have a discord"] = function() gui.OpenURL("https://discord.gg/cdPNUkz") end,
			["Click me!"] = function()
				local label = buttons[table.Count(buttons) - 1]
				x_final = -label[2] + 40
				y_final = -label[3] + 40
				
				update_position(x_final, y_final)
			end
		}
		
		bg_follower:Dock(FILL)
		bg_follower:SetSkin("BloodyNazis")
		
		--start tracking mouse, and update children while dragging
		bg_follower.OnMousePressed = function(self, mouse_button)
			if mouse_button == MOUSE_RIGHT then
				local x_off = x_final
				local x_start = gui.MouseX()
				local y_off = y_final
				local y_start = gui.MouseY()
				
				--we need to do this in case they stop dragging and their cursor is off of the panel
				bg_follower:MouseCapture(true)
				
				--use a detour of the bg_follower's think to do dragging of the icons
				bg_follower.Think = function(self)
					local x = gui.MouseX()
					local y = gui.MouseY()
					
					x_final = x_off + x - x_start
					y_final = y_off + y - y_start
					
					bg_follower:SetBackgroundX(x_final)
					bg_follower:SetBackgroundY(y_final)
					
					update_position(x_final, y_final)
				end
			end
		end
		
		--stop tracking mouse, return to normal behavior
		bg_follower.OnMouseReleased = function(self, mouse_button)
			if mouse_button == MOUSE_RIGHT then
				--we need to do this in case they stop dragging and their cursor is off of the panel
				bg_follower:MouseCapture(false)
				
				bg_follower.Think = function(self) end
			end
		end
		
		property_sheet:AddSheet(class_name .. " - Explorable", bg_follower, nil, true, true)
		
		timer.Simple(0, function()
			--we need a 0 second timer if we want to make sure the property sheet's size is correct
			--and we need the size to center the children
			if not property_sheet then return end
			
			local button_h = 80
			local button_w = 120
			local button_x_count = 16
			local button_y_count = 16
			local property_h_half = property_sheet:GetTall() * 0.5
			local property_w_half = property_sheet:GetWide() * 0.5
			
			for index = 0, button_x_count * button_y_count - 1 do
				local button = vgui.Create("DButton", bg_follower)
				local button_phrase = button_phrases[index + 1] or button_phrases[math.random(1, table.Count(button_phrases))]
				local button_x = index % button_x_count * button_w + property_w_half - button_w * button_x_count * 0.5 + math.Rand(-10, 10)
				local button_y = math.floor(index / button_y_count) * button_h + property_h_half - button_h * button_y_count * 0.5 + math.Rand(-10, 10)
				
				button:SetPos(button_x, button_y)
				button:SetSize(100, 50)
				button:SetText(button_phrase)
				
				if button_functions[button_phrase] then button.DoClick = button_functions[button_phrase] end
				
				buttons[index] = {button, button_x, button_y}
			end
			
			local label = vgui.Create("DLabel", bg_follower)
			local label_x = buttons[0][2]
			local label_y = buttons[0][3] - 100
			
			label:SetPos(label_x, label_y)
			label:SetSize(500, 80)
			label:SetText("I use this for the skill menu in my nZombies Level System addon, and you can modify it to do this. This one specifically takes quite a bit of modification, and I may make it its own panel in the future. It also has a few custom functions, which you can use to customize things like the color and background material.")
			label:SetTextColor(color_white)
			label:SetWrap(true)
			
			
			table.insert(buttons, {label, label_x, label_y})
		end)
	end
end

function PANEL:Init()
	self:SetBackgroundSize(256)
	self:SetBackgroundParallax(2.5)
	self:SetBackgroundX(0)
	self:SetBackgroundY(0)
	self:SetColor(Color(144, 56, 56))
	self:SetMaterial(Material("gui/nzombies_level_system/background.png", "noclamp"))
	
	self.BGXTiles = 2
	self.BGYTiles = 2
	
	self:InvalidateLayout()
end

function PANEL:OnMousePressed(mousecode) end
function PANEL:OnMouseReleased(mousecode) end

function PANEL:Paint(w, h)
	local u_scroll = (self.m_fBackgroundX / self.m_fBackgroundParallax) % 1
	local v_scroll = (self.m_fBackgroundY / self.m_fBackgroundParallax) % 1
	
	fl_surf_SetDrawColor(self.m_Color)
	fl_surf_SetMaterial(self.m_Material)
	fl_surf_DrawTexturedRectUV(0, 0, w, h, u_scroll, v_scroll, self.BGXTiles + u_scroll, self.BGYTiles + v_scroll)
	
	return true
end

function PANEL:PerformLayout()
	self.BGXTiles = self:GetWide() / self.m_fBackgroundSize
	self.BGYTiles = self:GetTall() / self.m_fBackgroundSize
end

function PANEL:SetBackgroundParallax(scale) self.m_fBackgroundParallax = self.m_fBackgroundSize * -scale end

function PANEL:SetBackgroundSize(size)
	self.m_fBackgroundSize = size
	
	self:InvalidateLayout()
end

function PANEL:Think() end

derma.DefineControl("NZLSBackgroundFollower", "A panel for making a parallax background.", PANEL, "DPanel")