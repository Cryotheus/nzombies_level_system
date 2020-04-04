print("***** GUI Reloaded")

local background = Material("gui/background.png", "noclamp")
local bg_size = 256
local bg_size_paralax = bg_size * -2.5
local browsing = false
local close_button_x = Material("gui/close_32.vtf")
local frame_header = 24
local frame_margin = 80
local last_hovering = true
local menus = {}
local skills = nz_level_system.skills
local skill_icon_size = 96

local bg_h
local bg_w
local derma_create_time
local frame_close_button_margin
local frame_h
local frame_w
local frame_x
local frame_y
local scr_h
local scr_w
local sidebar_h
local sidebar_w
local sidebar_x
local sidebar_y
local sidebutton_h
local sidebutton_w
local sidebutton_x
local sidebutton_y
local skill_icon_boundary_x
local skill_icon_boundary_y
local x_final
local y_final

local color_bg = Color(144, 56, 56)
local color_bright_white = Color(240, 240, 240)
local color_bright_white_select = Color(232, 232, 232)
local color_bright_white_select_loud = Color(216, 216, 216)
local color_dark_white = Color(208, 208, 208)
local color_frame_white = Color(224, 224, 224)
local color_nazi = Color(131, 41, 41)
local color_nazi_select = Color(115, 32, 32)

local fl_surf_DrawRect = surface.DrawRect
local fl_surf_DrawTexturedRect = surface.DrawTexturedRect
local fl_surf_DrawTexturedRectUV = surface.DrawTexturedRectUV
local fl_surf_SetDrawColor = surface.SetDrawColor
local fl_surf_SetMaterial = surface.SetMaterial

local function calc_vars()
	scr_h = ScrH()
	scr_w = ScrW()
	
	frame_close_button_margin = 4
	frame_h = scr_h - frame_margin * 2
	frame_w = scr_w - frame_margin * 2
	frame_x = frame_margin
	frame_y = frame_margin
	x_final = scr_w * 0.5 - frame_margin - skill_icon_size * 0.5
	y_final = scr_h * 0.5 - frame_margin - skill_icon_size * 0.5
	sidebar_h = frame_h - frame_header
	sidebar_margin = 4
	sidebar_w = frame_w * 0.1
	sidebar_x = 0
	sidebar_y = frame_header
	sidebutton_h = frame_h * 0.1 - sidebar_margin
	sidebutton_w = sidebar_w - sidebar_margin * 2
	sidebutton_x = sidebar_margin
	sidebutton_y = frame_header + sidebar_margin
	skill_icon_boundary_x_max = frame_w + skill_icon_size
	skill_icon_boundary_x_min = sidebar_w
	skill_icon_boundary_y_max = frame_h + skill_icon_size
	skill_icon_boundary_y_min = frame_header
	skill_menu_x_max = scr_w - frame_margin
	skill_menu_x_min = frame_margin + sidebar_w
	skill_menu_y_max = scr_h - frame_margin
	skill_menu_y_min = frame_margin + frame_header
	
	bg_h = frame_h - frame_header
	bg_w = frame_w
	bg_x_tiles = frame_w / bg_size
	bg_y_tiles = frame_h / bg_size
end

local function create_sidebar(frame)
	local scroll = vgui.Create("DScrollPanel", frame)
	local scroll_bar = scroll:GetVBar()
	
	scroll:Dock(FILL)
	scroll:DockMargin(0, frame_header - 24, frame_w - sidebar_w, 0)
	scroll_bar:SetHideButtons(true)
	
	function scroll_bar:Paint(w, h)
		fl_surf_SetDrawColor(color_dark_white)
		fl_surf_DrawRect(0, 0, w, h)
	end
	
	function scroll_bar.btnGrip:Paint(w, h)
		fl_surf_SetDrawColor(color_nazi)
		fl_surf_DrawRect(0, 0, w, h)
	end
	
	local scroll_bar_margin = 0 --5 if we need a scroll bar
	
	for text, func in pairs(menus) do
		local button = scroll:Add("DButton")
		
		button:Dock(TOP)
		button:DockMargin(0, 0, scroll_bar_margin, 5)
		button:SetSize(frame_w - scroll_bar_margin - 5, frame_h * 0.06)
		button:SetText(text)
		
		button.DoClick = function()
			--frame:MouseCapture(false)
			
			frame:Close()
			func()
		end
		
		button.Paint = function(self, w, h) 
			if button:IsHovered() then fl_surf_SetDrawColor(color_bright_white_select)
			else fl_surf_SetDrawColor(color_bright_white) end
			
			fl_surf_DrawRect(0, 0, w, h)
		end
	end
end

local function get_mouse_x() return math.Clamp(gui.MouseX(), 1, scr_w - 1) end
local function get_mouse_y() return math.Clamp(gui.MouseY(), 1, scr_h - 1) end
local function in_range(num, min, max) return num >= min and num <= max end

local function open_settings_menu()
	calc_vars() --just for now
	
	local frame = vgui.Create("DFrame")
	local frame_think = frame.Think
	
	frame:SetBackgroundBlur(true)
	frame:SetDraggable(false)
	frame:SetPos(frame_x, frame_y)
	frame:SetSize(frame_w, frame_h)
	frame:SetTitle("Settings")
	
	frame.Think = function(self)
		frame_think(self)
		 
		x = get_mouse_x() - frame_margin
		y = get_mouse_y() - frame_margin
	end
	
	frame.Paint = function(self, w, h)
		local u_scroll = (x / bg_size_paralax) % 1
		local v_scroll = (y / bg_size_paralax) % 1
		
		Derma_DrawBackgroundBlur(self, derma_create_time)
		
		fl_surf_SetDrawColor(color_bg)
		fl_surf_SetMaterial(background)
		fl_surf_DrawTexturedRectUV(sidebar_w, frame_header, bg_w, bg_h, u_scroll, v_scroll, bg_x_tiles + u_scroll, bg_y_tiles + v_scroll)
		
		fl_surf_SetDrawColor(color_frame_white)
		fl_surf_DrawRect(0, frame_header, sidebar_w, sidebar_h)
		
		fl_surf_SetDrawColor(color_nazi)
		fl_surf_DrawRect(0, 0, w, frame_header)
	end
	
	create_sidebar(frame)
	
	frame:MakePopup()
end

local function open_skills_menu()
	local frame = vgui.Create("DFrame")
	local frame_on_mouse_press = frame.OnMousePressed
	local frame_on_mouse_release = frame.OnMousePressed
	local frame_think = frame.Think
	local skill_buttons = {}
	
	frame:SetBackgroundBlur(true)
	frame:SetDraggable(false)
	frame:SetMouseInputEnabled(false)
	frame:SetPos(frame_x, frame_y)
	frame:SetSize(frame_w, frame_h)
	frame:SetTitle("Skills Menu")
	
	frame.btnMinim:SetVisible(false)
	frame.btnMaxim:SetVisible(false)
	
	frame.OnMousePressed = function(self, mouse_button)
		frame_on_mouse_press(self, mouse_button)
		
		if mouse_button == MOUSE_LEFT and not browsing then
			local x = get_mouse_x()
			local x_traget = x - frame_margin - x_final
			local y = get_mouse_y()
			local y_traget = y - frame_margin - y_final
			
			if in_range(x, skill_menu_x_min, skill_menu_x_max) and in_range(y, skill_menu_y_min, skill_menu_y_max) then
				for skill, data in pairs(skills) do
					local icon_x, icon_y = data.X, data.Y
					
					if in_range(x_traget - icon_x, 0, skill_icon_size) and in_range(y_traget - icon_y, 0, skill_icon_size) then
						print(skill)
						PrintTable(data, 1)
						
						break
					end
				end
			end
		elseif mouse_button == MOUSE_RIGHT then
			browsing = true
			local x_off = x_final
			local x_start = get_mouse_x() - frame_margin
			local y_off = y_final
			local y_start = get_mouse_y() - frame_margin
			
			--we need to do this in case they stop dragging and their cursor is off of the panel
			frame:MouseCapture(true)
			
			--use a detour of the frame's think to do dragging of the icons
			frame.Think = function(self)
				frame_think(self)
				
				local x = get_mouse_x()
				local y = get_mouse_y()
				
				x_final = x_off + get_mouse_x() - frame_margin - x_start
				y_final = y_off + get_mouse_y() - frame_margin - y_start
				
				--[[for skill, data in pairs(nz_level_system.skills) do
					local icon_x, icon_y = x_final + data.X, y_final + data.Y
					local skill_button = skill_buttons[skill]
					
					if in_range(icon_x + skill_icon_size, skill_icon_boundary_x_min, skill_icon_boundary_x_max) and in_range(icon_y + skill_icon_size, skill_icon_boundary_y_min, skill_icon_boundary_y_max) then
						--
						
						skill_button:SetPos(icon_x, icon_y)
					end
				end]]
			end
		end
	end
	
	frame.OnMouseReleased = function(self, mouse_button)
		frame_on_mouse_release(self, mouse_button)
		
		if mouse_button == MOUSE_RIGHT then
			--make it do normal think functions again
			--we need to do this in case they stop dragging and their cursor is off of the panel
			frame:MouseCapture(false)
			--frame:RequestFocus()
			
			browsing = false
			frame.Think = frame_think
		end
	end
	
	frame.Paint = function(self, w, h)
		local hovered_skill
		local not_hovering = true
		local u_scroll = (x_final / bg_size_paralax) % 1
		local v_scroll = (y_final / bg_size_paralax) % 1
		local x = get_mouse_x()
		local x_traget = x - frame_margin-- - x_final
		local y = get_mouse_y()
		local y_traget = y - frame_margin-- - y_final
		
		Derma_DrawBackgroundBlur(self, derma_create_time)
		
		fl_surf_SetDrawColor(color_bg)
		fl_surf_SetMaterial(background)
		fl_surf_DrawTexturedRectUV(sidebar_w, frame_header, bg_w, bg_h, u_scroll, v_scroll, bg_x_tiles + u_scroll, bg_y_tiles + v_scroll)
		
		for skill, data in pairs(skills) do
			local icon_x, icon_y = x_final + data.X, y_final + data.Y
			
			if in_range(icon_x + skill_icon_size, skill_icon_boundary_x_min, skill_icon_boundary_x_max) and in_range(icon_y + skill_icon_size, skill_icon_boundary_y_min, skill_icon_boundary_y_max) then
				if not_hovering and in_range(x_traget - icon_x, 0, skill_icon_size) and in_range(y_traget - icon_y, 0, skill_icon_size) then
					hovered_skill = skill
					not_hovering = false
					
					fl_surf_SetDrawColor(color_bright_white_select_loud)
				else fl_surf_SetDrawColor(color_bright_white) end
				
				fl_surf_SetMaterial(data.Icon)
				fl_surf_DrawTexturedRect(icon_x, icon_y, skill_icon_size, skill_icon_size)
			end
		end
		
		fl_surf_SetDrawColor(color_frame_white)
		fl_surf_DrawRect(0, frame_header, sidebar_w, sidebar_h)
		
		fl_surf_SetDrawColor(color_nazi)
		fl_surf_DrawRect(0, 0, w, frame_header)
		
		--show that you can click icons, we have to do this every frame because on the next frame it resets
		if not not_hovering then frame:SetCursor("hourglass") end
		
		last_hovering = not_hovering
	end
	
	frame.btnClose.Paint = function(self, w, h)
		local close_button_h = h - 2 * frame_close_button_margin
		
		if self:IsHovered() then fl_surf_SetDrawColor(color_bright_white_select_loud)
		else fl_surf_SetDrawColor(color_bright_white) end
		
		fl_surf_DrawRect(0, frame_close_button_margin, w, close_button_h)
		
		fl_surf_SetMaterial(close_button_x)
		fl_surf_DrawTexturedRect((w - close_button_h) * 0.5, frame_close_button_margin, close_button_h, close_button_h)
	end
	
	--[[create the icons as buttons --disabled because of render order ;-;
	for skill, data in pairs(nz_level_system.skills) do
		local icon_x, icon_y = x_final + data.X, y_final + data.Y
		local skill_button = vgui.Create("DButton", frame)
		
		skill_button:SetPos(icon_x, icon_y)
		skill_button:SetSize(skill_icon_size, skill_icon_size)
		skill_button:SetText("") --we dont want text
		
		skill_button.Paint = function(self, w, h)
			if self:IsHovered() then fl_surf_SetDrawColor(color_bright_white_select_loud)
			else fl_surf_SetDrawColor(color_bright_white) end
			
			fl_surf_SetMaterial(data.Icon)
			fl_surf_DrawTexturedRect(0, 0, w, h)
		end
		
		skill_buttons[skill] = skill_button
	end--]]
	
	create_sidebar(frame)
	
	frame:MakePopup()
end

concommand.Add("nz_ls_gui_skills", function()
	calc_vars() --just for now
	derma_create_time = SysTime()
	
	open_skills_menu()
end, _, "Opens the GUI to purchase and upgrade skills.")

hook.Add("OnScreenSizeChanged", "nz_ls_gui_screen_res_changed_hook", function() calc_vars() end)

--we have to do this after the functions are declared because they are not global
--and we have this in the first place so we don't have impossible ordering scenarios
menus = {
	["Settings"] = open_settings_menu,
	["Skills"] = open_skills_menu
}