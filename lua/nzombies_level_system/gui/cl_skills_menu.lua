local background = Material("gui/background.png", "noclamp")
local frame_h = 0
local frame_margin = 40
local frame_w = 0
local frame_x = 0
local frame_y = 0
local scr_h = 0
local scr_w = 0

local function calc_vars()
	frame_h = scr_h - frame_margin * 2
	frame_w = scr_w - frame_margin * 2
	frame_x = frame_margin
	frame_y = frame_margin
end

local function get_mouse_x() return math.Clamp(gui.MouseX(), 1, scr_w - 1) end
local function get_mouse_y() return math.Clamp(gui.MouseY(), 1, scr_h - 1) end

local function open_menu()
	local frame = vgui.Create("DFrame")
	local frame_paint = frame.Paint
	local frame_think = frame.Think
	
	frame:SetBackgroundBlur(true)
	frame:SetDraggable(false)
	frame:SetPos(frame_x, frame_y)
	frame:SetSize(frame_w, frame_h)
	frame:SetTitle("My new Derma frame")
	frame.btnMaxim:SetVisible(false)
	frame.btnMinim:SetVisible(false)
	
	frame.OnMousePressed = function(mouse_button)
		if mouse_button == MOUSE_LEFT then
			--use a detour of the frame's think to do dragging of the internals
			frame:MouseCapture(true)
			
			local x = 0
			local x_diff = 0
			local x_off = 0
			local x_start = get_mouse_x()
			local y = 0
			local y_diff = 0
			local y_off = 0
			local y_start = get_mouse_y()
			
			frame.Paint = function(self, w, h)
				frame_paint(self, w, h)
				
				surface.SetMaterial(background)
				surface.DrawTexturedRectUV(24, 0, w, h - 24, 0, 0, w / 256, h / 256)
				
				surface.SetMaterial(nz_level_system.skills["sprint"].Icon)
				surface.DrawTexturedRect(x, y, 128, 128)
			end
			
			frame.Think = function(self)
				frame_think(self)
				
				x = get_mouse_x() - frame_margin
				x_diff = x - x_start
				y = get_mouse_y() - frame_margin
				y_diff = y - y_start
			end
		end
	end
	
	frame.OnMouseReleased = function(mouse_button)
		if mouse_button == MOUSE_LEFT then
			--make it do normal think functions again
			frame:MouseCapture(false)
			
			frame.Paint = frame_paint
			frame.Think = frame_think
		end
	end
	
	frame:MakePopup()
end

concommand.Add("nz_ls_gui_skills", function()
	--
	open_menu()
end, _, "Opens the GUI to purchase and upgrade skills.")

hook.Add("OnScreenSizeChanged", "prog_bar_screen_res_changed_hook", function() scr_h, scr_w = ScrH(), ScrW() end)