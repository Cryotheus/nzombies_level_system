print("Menus loaded")

local register_font = include("nzombies_level_system/fn_font.lua")

--locals
local browsing = false
local menu_order = {}
local menus = {}
local pi = math.pi
local skills = NZLS.skills
local tau = pi * 2

----render params
	local circle_mat = Material("gui/nzombies_level_system/circle_256.png")
	local content_h
	local content_w
	local content_x
	local content_y
	local current_menu
	local derma_create_time
	local frame_h
	local frame_header = 24
	local frame_margin = 80
	local frame_w
	local frame_x
	local frame_y
	local scr_h
	local scr_w
	local sidebar_margin = 4
	local sidebar_w
	local sidebar_y
	local skill_icon_size = 96
	local skill_info_h
	local skill_info_button_margin = 4
	local skill_info_button_h
	local skill_info_button_w
	local skill_info_button_x
	local skill_info_button_y
	local skill_info_label_font
	local skill_info_label_h
	local skill_info_label_margin = 4
	local skill_info_label_margin_size
	local skill_info_label_w
	local skill_info_margin = 8
	local skill_info_rich_text_margin = 8
	local skill_info_rich_text_w
	local skill_info_rich_text_x
	local skill_info_rich_text_y
	local skill_info_rich_text_h
	local skill_info_w
	local skill_info_x
	local skill_info_y

----cached functions
	local fl_Color = Color
	local fl_math_sin = math.sin
	local fl_RealTime = RealTime
	local fl_surf_DrawRect = surface.DrawRect
	local fl_surf_DrawTexturedRect = surface.DrawTexturedRect
	local fl_surf_DrawTexturedRectUV = surface.DrawTexturedRectUV
	local fl_surf_SetDrawColor = surface.SetDrawColor
	local fl_surf_SetMaterial = surface.SetMaterial

----colors
	local color_bg = fl_Color(144, 56, 56)
	local color_bright_white = fl_Color(240, 240, 240)
	local color_bright_white_select = fl_Color(232, 232, 232)
	local color_bright_white_select_loud = fl_Color(216, 216, 216)
	local color_dark_white = fl_Color(208, 208, 208)
	local color_frame_white = fl_Color(224, 224, 224)
	local color_gold = fl_Color(227, 178, 27)
	local color_gold_select = fl_Color(218, 165, 32)
	local color_nazi = fl_Color(131, 41, 41)
	local color_nazi_select = fl_Color(115, 32, 32)
	local color_yellow = fl_Color(255, 255, 128)

----color sets
	skill_icon_colors = {
		nil,
		color_bright_white,
		color_nazi,
		color_gold,
	}

	skill_icon_colors_bg = {
		color_nazi,
		color_nazi,
		color_bright_white,
		color_nazi
	}

	skill_icon_colors_hover = {
		color_bright_white_select_loud,
		color_bright_white_select,
		color_nazi_select,
		color_gold_select
	}

--convars
local nz_ls_progress_bar_scale = GetConVar("nz_ls_progress_bar_scale")

--local functions
local function calc_vars()
	scr_h = ScrH()
	scr_w = ScrW()
	
	frame_h = scr_h - frame_margin * 2
	frame_w = scr_w - frame_margin * 2
	frame_x = frame_margin
	frame_y = frame_margin
	
	sidebar_w = frame_w * 0.1
	
	content_h = frame_h - frame_header
	content_w = frame_w - sidebar_w
	content_x = sidebar_w
	content_y = frame_header
	
	skill_info_h = content_h - skill_info_margin * 2
	skill_info_w = content_w * 0.2 - skill_info_margin
	skill_info_x = content_w * 0.8
	skill_info_y = content_y - skill_info_margin
	
	skill_info_label_font = register_font(30, 500, "Tahoma")
	skill_info_label_margin_size = skill_info_label_margin * 2
	
	skill_info_label_h = 0.1 * skill_info_h - skill_info_label_margin_size
	skill_info_label_w = skill_info_w - skill_info_label_margin_size
	
	skill_info_image_size = math.min(skill_info_w * 0.5, 256)
	skill_info_image_x = skill_info_image_size * 0.5
	skill_info_image_y = skill_info_label_h + skill_info_label_margin_size
	
	skill_info_button_h = skill_info_h * 0.08
	skill_info_button_w = skill_info_w - skill_info_button_margin * 2
	skill_info_button_x = skill_info_button_margin
	skill_info_button_y = skill_info_h - skill_info_button_h - skill_info_button_margin
	
	skill_info_rich_text_w = skill_info_w - skill_info_rich_text_margin * 2
	skill_info_rich_text_x = skill_info_rich_text_margin
	skill_info_rich_text_y = skill_info_image_y + skill_info_image_size + skill_info_rich_text_margin
	
	skill_info_rich_text_h = skill_info_h - skill_info_rich_text_y - skill_info_rich_text_margin - skill_info_button_h - skill_info_button_margin
	
end

local function create_sidebar(frame)
	local scroll = vgui.Create("DScrollPanel", frame)
	local scroll_bar = scroll:GetVBar()
	local scroll_bar_margin = 0 --5 if we need a scroll bar
	
	scroll:Dock(FILL)
	scroll:DockMargin(0, 0, content_w, 0)
	scroll_bar:SetHideButtons(true)
	
	for index, text in pairs(menu_order) do
		local button = scroll:Add("DButton")
		
		button:Dock(TOP)
		button:DockMargin(0, 0, scroll_bar_margin, 5)
		button:SetSize(frame_w - scroll_bar_margin - 5, frame_h * 0.06)
		button:SetText(text)
		button:SetTextColor(color_nazi)
		
		if text == current_menu then button:SetEnabled(false) end
		
		button.DoClick = function()
			--cheap enough that we shouldn't have to check
			--checking or creating an alternate DoClick function is not worth the effort
			NZLSUpdateSkillMenu = nil
			
			button:SetTextColor(color_bright_white)
			frame:Close()
			menus[text]()
		end
	end
end

local function positively_below(num, max) return num >= 0 and num <= max end
local function get_mouse_x() return math.Clamp(gui.MouseX(), 1, scr_w - 1) end
local function get_mouse_y() return math.Clamp(gui.MouseY(), 1, scr_h - 1) end
local function in_range(num, min, max) return num >= min and num <= max end

local function open_board_menu()
	current_menu = "Board"
	
	local frame = vgui.Create("DFrame")
	local frame_paint = frame.Paint
	
	frame:SetDraggable(false)
	frame:SetPos(frame_x, frame_y)
	frame:SetSize(frame_w, frame_h)
	frame:SetSkin("BloodyNazis")
	frame:SetTitle(current_menu)
	
	frame.btnMinim:SetVisible(false)
	frame.btnMaxim:SetVisible(false)
	
	local bg_follower = vgui.Create("NZLSBackgroundFollower", frame)
	
	bg_follower:SetPos(content_x, content_y)
	bg_follower:SetSize(content_w, content_h)
	
	frame.Paint = function(self, w, h)
		Derma_DrawBackgroundBlur(frame, derma_create_time)
		frame_paint(self, w, h)
		
		bg_follower:SetBackgroundX(get_mouse_x() - frame_margin)
		bg_follower:SetBackgroundY(get_mouse_y() - frame_margin)
	end
	
	--local rich_text_info = vgui.Create("RichText", frame)
	
	create_sidebar(frame)
	
	frame:MakePopup()
end

local function open_settings_menu()
	current_menu = "Settings"
	
	local frame = vgui.Create("DFrame")
	local frame_paint = frame.Paint
	
	frame:SetDraggable(false)
	frame:SetPos(frame_x, frame_y)
	frame:SetSize(frame_w, frame_h)
	frame:SetSkin("BloodyNazis")
	frame:SetTitle(current_menu)
	
	frame.btnMinim:SetVisible(false)
	frame.btnMaxim:SetVisible(false)
	
	local bg_follower = vgui.Create("NZLSBackgroundFollower", frame)
	
	bg_follower:SetPos(content_x, content_y)
	bg_follower:SetSize(content_w, content_h)
	
	frame.Paint = function(self, w, h)
		Derma_DrawBackgroundBlur(frame, derma_create_time)
		frame_paint(self, w, h)
		
		bg_follower:SetBackgroundX(get_mouse_x() - frame_margin)
		bg_follower:SetBackgroundY(get_mouse_y() - frame_margin)
	end
	
	do --progress bar settings
		local form = vgui.Create("DForm", bg_follower)
		
		form:SetExpanded(false)
		form:SetName("Progress Bar")
		form:Dock(TOP)
		
		local check_box = form:CheckBox("Low quality mode", "nz_ls_progress_bar_low_perf")
		
		check_box:SetTextColor(color_bright_white)
		
		local num_slider = form:NumSlider("Scale", "nz_ls_progress_bar_scale", nz_ls_progress_bar_scale:GetMin(), nz_ls_progress_bar_scale:GetMax(), 2)
		num_slider.LineColor = color_bright_white
		
		num_slider.Label:SetTextColor(color_bright_white)
		num_slider.TextArea:SetTextColor(color_bright_white)
		
		form:Help("More settings to come"):SetTextColor(color_bright_white)
	end
	
	do --credits form
		local form = vgui.Create("DForm", bg_follower)
		
		form:SetExpanded(false)
		form:SetName("Credits")
		form:Dock(TOP)
		
		--this is gonna be weird
		local avatar_creator = vgui.Create("AvatarImage", form)
		local avatar_size = 64
		
		avatar_creator:SetSize(avatar_size, avatar_size)
		avatar_creator:SetSteamID("76561198106179251", avatar_size)
		
		avatar_creator.DoClick = function() gui.OpenURL("http://steamcommunity.com/profiles/76561198106179251") end
		
		form:AddItem(avatar_creator)
		
		avatar_creator:Dock(LEFT)
		
		--the dform makes a parent (DSizeToContents) which is literally satan to deal with if you don't know about it
		local avatar_parent = avatar_creator:GetParent()
		
		avatar_parent:SetTall(avatar_size + 10)
		avatar_creator:SetSize(avatar_size, avatar_size)
		
		--then we make the label next to it
		local button_main_credits = vgui.Create("DButton", avatar_parent)
		
		button_main_credits:DockMargin(8, 0, 8, 8)
		button_main_credits:SetDark(true)
		button_main_credits:SetWide(0)
		button_main_credits:SetText("Made by Cryotheum!")
		
		button_main_credits.DoClick = function() gui.OpenURL("http://steamcommunity.com/profiles/76561198106179251") end
		
		--don't you love having to use 0 second timers? it really makes me feel like I just had an aneurysm
		timer.Simple(0, function()
			local avatar_creator_x, avatar_creator_y, avatar_creator_w, avatar_creator_h = avatar_creator:GetBounds()
			
			button_main_credits:SetPos(avatar_creator_x + avatar_creator_w + 8, avatar_creator_y)
			button_main_credits:SetSize(avatar_parent:GetWide() * 0.2, avatar_creator_h)
			form:SetExpanded(false)
		end)
	end
	
	create_sidebar(frame)
	
	frame:MakePopup()
end

local function open_skills_menu()
	current_menu = "Skills"
	
	local color_bright_white_flash = color_bright_white --defined here so we don't do it on every button's paint function
	local frame = vgui.Create("DFrame")
	local frame_on_mouse_press = frame.OnMousePressed
	local frame_on_mouse_release = frame.OnMousePressed
	local frame_paint = frame.Paint
	local frame_think = frame.Think
	local hovered_skill
	local skill_buttons = {}
	local skill_selected
	local x_final = scr_w * 0.5 - frame_margin - skill_icon_size * 0.5 - content_x
	local x_traget = x_final - frame_margin
	local y_final = scr_h * 0.5 - frame_margin - skill_icon_size * 0.5 - content_y
	local y_traget = y_final - frame_margin
	
	--NOTE, we can take hovered_skill in frame.Paint and use that in frame.OnMousePressed to do stuff, yeah.
	--this way we don't have to itterate over the skills twice
	
	frame:SetDraggable(false)
	frame:SetMouseInputEnabled(false)
	frame:SetPos(frame_x, frame_y)
	frame:SetSize(frame_w, frame_h)
	frame:SetSkin("BloodyNazis")
	frame:SetTitle(current_menu)
	
	frame.btnMinim:SetVisible(false)
	frame.btnMaxim:SetVisible(false)
	
	local bg_follower = vgui.Create("NZLSBackgroundFollower", frame)
	local bg_follower_on_mouse_press = bg_follower.OnMousePressed
	local bg_follower_on_mouse_release = bg_follower.OnMousePressed
	local bg_follower_think = bg_follower.Think
	
	bg_follower:SetMouseInputEnabled(true)
	bg_follower:SetPos(content_x, content_y)
	bg_follower:SetSize(content_w, content_h)
	
	----main side panel, holds all the info about a skill
		local panel_skill_info = vgui.Create("DPanel", bg_follower)
		
		panel_skill_info:SetPos(skill_info_x, skill_info_y)
		panel_skill_info:SetSize(skill_info_w, skill_info_h)
		panel_skill_info:SetVisible(false)
		
		panel_skill_info.Paint = function(self, w, h)
			fl_surf_SetDrawColor(Color(0, 0, 0, 192))
			fl_surf_DrawRect(0, 0, w, h)
		end
		
		--skill name
		local label_skill_info = vgui.Create("DLabel", panel_skill_info)
		
		label_skill_info:SetContentAlignment(5)
		label_skill_info:SetFont(skill_info_label_font)
		label_skill_info:SetPos(skill_info_label_margin, skill_info_label_margin)
		label_skill_info:SetSize(skill_info_label_w, skill_info_label_h)
		
		--icon of skill
		local image_skill_info = vgui.Create("DImage", panel_skill_info)
		
		image_skill_info:SetPos(skill_info_image_x, skill_info_image_y)
		image_skill_info:SetSize(skill_info_image_size, skill_info_image_size)
		
		--description, and bulk of actual information
		local rich_text_skill_info_description = vgui.Create("RichText", panel_skill_info)
		
		rich_text_skill_info_description:SetPos(skill_info_rich_text_x, skill_info_rich_text_y)
		rich_text_skill_info_description:SetSize(skill_info_rich_text_w, skill_info_rich_text_h)
		rich_text_skill_info_description:SetVerticalScrollbarEnabled(false)
		rich_text_skill_info_description:SetWrap(true)
		
		local button_purchase = vgui.Create("DButton", panel_skill_info)
		
		button_purchase:SetPos(skill_info_button_x, skill_info_button_y)
		button_purchase:SetSize(skill_info_button_w, skill_info_button_h)
		button_purchase:SetText("Wow you broke it, congrats.")
		
		button_purchase.DoClick = function()
			if skill_selected then LocalPlayer():ConCommand("nz_ls_purchase " .. skill_selected)
			else LocalPlayer():PrintMessage(HUD_PRINTTALK, "Wow you broke it congrats, you earn nothing more than the right to message me on discord and explain how. Cryotheum#4096") end
		end
	----
	
	function NZLSUpdateSkillMenu()
		for skill, skill_button in pairs(skill_buttons) do skill_button:Remove() end
		
		skill_buttons = {}
		
		for skill, data in pairs(skills) do
			local visibility = NZLSSkillVisibility[skill]
			
			if visibility then
				local icon = data.Icon
				local icon_color = skill_icon_colors[visibility]
				local icon_name = data.PrintName
				local icon_x, icon_y = x_final + data.X, y_final + data.Y
				local skill_button = vgui.Create("DButton", bg_follower)
				local skill_max_level = data.MaxLevel
				local skill_max_level_prestiege = data.MaxLevelPrestige
				
				local desc_affordable
				local desc_cost
				local desc_level
				local desc_prestiege_bonus
				local ply_skill = NZLSData.skills[skill] or {}
				local ply_skill_level = ply_skill.level or 0
				local ply_skill_level_prestiege = ply_skill.level_prestiege or 0
				local ply_skill_prestiege_ready = ply_skill_level >= skill_max_level and skill_max_level_prestiege
				
				if ply_skill_prestiege_ready then
					local cost = math.floor(data.CostPrestiege(ply_skill_level_prestiege + 1))
					
					desc_affordable = NZLSData.points_prestiege - NZLSData.points_prestiege_used >= cost
					desc_cost = cost .. (cost == 1 and " prestiege point" or " prestiege points")
					desc_level = ply_skill_level + ply_skill_level_prestiege .. " of " .. skill_max_level + skill_max_level_prestiege
					desc_prestiege_bonus = " prestieged\n\n"
				else
					local cost = math.floor(data.Cost(ply_skill_level + 1))
					
					desc_affordable = NZLSData.points - NZLSData.points_used >= cost
					desc_cost = cost .. (cost == 1 and " point" or " points")
					desc_level = ply_skill_level .. " of " .. skill_max_level
					desc_prestiege_bonus = ply_skill_level_prestiege > 0 and " (+ " .. ply_skill_level_prestiege .. " )\n\n" or "\n\n"
				end
				
				skill_button:SetPos(icon_x, icon_y)
				skill_button:SetSize(skill_icon_size, skill_icon_size)
				skill_button:SetText("")
				skill_button:SetTooltipPanelOverride("NZLSToolTip")
				skill_button:SetTooltip(icon_name)
				
				skill_button.Paint = function(self, w, h)
					if skill == skill_selected then
						fl_surf_SetDrawColor(skill_icon_colors_bg[visibility])
						fl_surf_SetMaterial(circle_mat)
						fl_surf_DrawTexturedRect(0, 0, w, h)
					end
					
					fl_surf_SetDrawColor(skill_button.Hovered and skill_icon_colors_hover[visibility] or icon_color or color_bright_white_flash)
					fl_surf_SetMaterial(icon)
					fl_surf_DrawTexturedRect(0, 0, w, h)
				end
				
				skill_button.DoClick = function()
					if skill_selected == skill then
						skill_selected = nil
						
						panel_skill_info:SetVisible(false)
					else
						skill_selected = skill
						
						button_purchase:SetText("Upgrade " .. string.lower(icon_name) .. " skill for " .. desc_cost)
						button_purchase:SetVisible(desc_affordable)
						image_skill_info:SetMaterial(icon)
						label_skill_info:SetText(icon_name)
						
						rich_text_skill_info_description:SetText("")
						rich_text_skill_info_description:InsertColorChange(240, 240, 240, 255)
						rich_text_skill_info_description:AppendText("Costs ")
						rich_text_skill_info_description:InsertColorChange(255, 255, 128, 255)
						rich_text_skill_info_description:AppendText(desc_cost)
						rich_text_skill_info_description:InsertColorChange(240, 240, 240, 255)
						rich_text_skill_info_description:AppendText(" for next level\nLevel ")
						rich_text_skill_info_description:InsertColorChange(131, 41, 41, 255)
						rich_text_skill_info_description:AppendText(desc_level)
						
						if ply_skill_prestiege_ready then rich_text_skill_info_description:InsertColorChange(192, 192, 192, 255)
						else rich_text_skill_info_description:InsertColorChange(240, 240, 240, 255) end
						
						rich_text_skill_info_description:AppendText(desc_prestiege_bonus)
						rich_text_skill_info_description:InsertColorChange(240, 240, 240, 255)
						rich_text_skill_info_description:AppendText(data.Description)
						
						panel_skill_info:SetVisible(true)
					end
				end
				
				skill_buttons[skill] = skill_button
			end
		end
		
		if skill_selected then
			print("Emulating icon click")
			
			local skill_selected_old = skill_selected
			skill_selected = nil
			
			skill_buttons[skill_selected_old]:DoClick()
		end
	end
	
	NZLSUpdateSkillMenu()
	
	bg_follower.OnMousePressed = function(self, mouse_button)
		bg_follower_on_mouse_press(self, mouse_button)
		
		if mouse_button == MOUSE_RIGHT then
			browsing = true
			local x_off = x_final
			local x_start = get_mouse_x() - frame_margin
			local y_off = y_final
			local y_start = get_mouse_y() - frame_margin
			
			--we need to do this in case they stop dragging and their cursor is off of the panel
			bg_follower:MouseCapture(true)
			
			--use a detour of the bg_follower's think to do dragging of the icons
			bg_follower.Think = function(self)
				bg_follower_think(self)
				
				local x = get_mouse_x()
				local y = get_mouse_y()
				
				x_final = x_off + x - frame_margin - x_start
				x_traget = x - frame_margin
				y_final = y_off + y - frame_margin - y_start
				y_traget = y - frame_margin
				
				bg_follower:SetBackgroundX(x_final - sidebar_w)
				bg_follower:SetBackgroundY(y_final - frame_header)
				
				for skill, skill_button in pairs(skill_buttons) do
					local data = skills[skill]
					local icon_x, icon_y = x_final + data.X, y_final + data.Y
					
					skill_button:SetPos(icon_x, icon_y)
				end
			end
		end
	end
	
	bg_follower.OnMouseReleased = function(self, mouse_button)
		bg_follower_on_mouse_release(self, mouse_button)
		
		if mouse_button == MOUSE_RIGHT then
			--make it do normal think functions again
			--we need to do this in case they stop dragging and their cursor is off of the panel
			bg_follower:MouseCapture(false)
			
			browsing = false
			bg_follower.Think = bg_follower_think
		end
	end
	
	frame.OnClose = function(self) NZLSUpdateSkillMenu = nil end
	
	frame.Paint = function(self, w, h)
		local brightness = fl_math_sin(fl_RealTime() * pi % tau) * 72 + 168
		color_bright_white_flash = fl_Color(brightness, brightness, brightness)
		
		Derma_DrawBackgroundBlur(frame, derma_create_time)
		frame_paint(self, w, h)
	end
	
	create_sidebar(frame)
	
	frame:MakePopup()
end

local function setup_menu()
	--only use this when the menu is first opened, not when going between menus
	calc_vars() --just for now
	derma_create_time = SysTime()
end

--post function setup
--we have to do this after the functions are declared because they are not global
--I may change how the odering is done later
menus = {
	["Board"] = open_board_menu,
	["Skills"] = open_skills_menu,
	["Settings"] = open_settings_menu
}

menu_order = {"Board", "Skills", "Settings"}

--commands
concommand.Add("nz_ls_debug_derma_test", function()
	setup_menu()
	
	local frame = vgui.Create("DFrame")
	
	frame:SetDraggable(false)
	frame:SetMouseInputEnabled(false)
	frame:SetPos(frame_x, frame_y)
	frame:SetSize(frame_w, frame_h)
	frame:SetSkin("BloodyNazis")
	frame:SetTitle("Skin Debug Menu")
	
	local form = vgui.Create("DForm", frame)
	form:Dock(FILL)
	form:SetName("Test form, nice eh?")
	
	--form contents
	form:Button("Does it look good?", "")
	form:CheckBox("Allow skin testing", "")
	form:ComboBox("test", ""):AddChoice("Entry")
	form:ControlHelp("Info here maties. This is a very long string of text I am just writing out so that the text wraps. I mean, it should wrap but I am unsure if it will. By now this should be long enough to wrap. So it turns out this string was not actually long enough. What I had assumed in the normal help label was wrong, but this help text is indented a little bit from the left. That's why I am writing this here, because I want to make sure that wrapping works well on both of these. Not that it really matters for making a skin, but I still want to see text wrapping. Normal flat one liners won't suffice for me. I actually am feeling ambitious enough to make this wrap so far it reaches three lines. What do you think? Not that you can tell me though, I'm just an image or video depending on whether or not I upload this on youtube or send a pic of the test derma on discord in dev logs. Wow, this is so long it might even reach four lines! Well, we will have to see.")
	form:Help("This is also some long text but this time it isn't as eye catching. This one should also wrap, but it is more likely to. I may actually have to make this one longer as I think that ControlHelp is bold or a larger font size or something. Well I guess the best way to tell is to check in game, so we can check that in a bit. Hey guys, scarce here. What's goin on bros my name is SUCK A DONK. I don't actually care for monetization, ads suck. I hope to find other ways to make money.")
	form:NumberWang("Number wang!?!", "", 0, 69, 1)
	form:NumSlider("A slider, useful", "", 0, 420, 0)
	form:TextEntry("Text entry here", "")
	
	frame:MakePopup()
end, nil, "Debug the skin panel, shows all the panels I feel like editing.")

concommand.Add("nz_ls_gui", function() setup_menu() open_board_menu() end, nil, "Opens the GUI to purchase and upgrade skills.")
concommand.Add("nz_ls_gui_board", function() setup_menu() open_board_menu() end, nil, "Opens the GUI to view information about your progress.")
concommand.Add("nz_ls_gui_skills", function() setup_menu() open_skills_menu() end, nil, "Opens the GUI to purchase and upgrade skills.")
concommand.Add("nz_ls_gui_settings", function() setup_menu() open_settings_menu() end, nil, "Opens the GUI to purchase and upgrade skills.")

--hooks
hook.Add("OnScreenSizeChanged", "nzls_gui_screen_res_changed_hook", function() calc_vars() end)