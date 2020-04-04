print("Core loaded (client realm)")

--shared functions

local calc_exp, calc_level = include("fn_core.lua")

--not shared stuff

local current_level = 0
local exp = 0
local exp_passed = 0
local exp_required = 0
local local_player = nil
local percent = 0

local scr_h = 0
local scr_w = 0

local bar_bg_corner = 0
local bar_bg_h = 0
local bar_bg_w = 0
local bar_bg_x = 0
local bar_bg_y = 0
local bar_corner = 0
local bar_h = 0
local bar_level_text = "level 0"
local bar_level_text_font = ""
local bar_level_text_x = 0
local bar_level_text_y = 0
local bar_scale = 1
local bar_w = 0
local bar_x = 0
local bar_y = 0
local color_blood = Color(128, 32, 32)
local percent_bar_w = 0

--I have a table for this specific font I use in my progress bar addon. This will keep me from making duplicvate fonts
--I may make the functions themself global, but for now I'll have it like this
CryotheumDynamicFontData = CryotheumDynamicFontData or {}

local function calc_vars()
	scr_h = ScrH()
	scr_w = ScrW()
	
	bar_bg_corner = 8 * bar_scale
	bar_bg_h = 16 * bar_scale
	bar_bg_w = 388 * bar_scale
	bar_bg_x = (scr_w - bar_bg_w) / 2
	bar_bg_y = scr_h - bar_bg_h - bar_scale * 4
	bar_corner = 4 * bar_scale
	bar_h = 8 * bar_scale
	bar_level_text_x = scr_w / 2
	bar_level_text_y = scr_h - bar_h - bar_scale * 12
	bar_w = 380 * bar_scale
	bar_x = (scr_w - bar_w) / 2
	bar_y = scr_h - bar_h - bar_scale * 8
end

local function create_font(size, weight)
	surface.CreateFont("pbgenfont" .. size .. "." .. weight, {
		font = "DK Umbilical Noose",
		size = size,
		weight = weight,
		antialias = true,
	})
end

local function register_font(size, weight)
	if CryotheumDynamicFontData[size] then
		if CryotheumDynamicFontData[size][weight] then return
		else
			CryotheumDynamicFontData[size][weight] = true
			
			create_font(size, weight)
		end
	else
		CryotheumDynamicFontData[size] = {[weight] = true}
		
		create_font(size, weight)
	end
end

local function set_font(size, weight)
	bar_level_text_font = "pbgenfont" .. size .. "." .. weight
	
	register_font(size, weight)
end

calc_vars()
set_font(16 * bar_scale, 150)

if not local_player then
	--make sure local_player is not nil, yes this can happen and I don't know what causes it
	--also it seems that if we define local_player as LocalPlayer() in the init it doesn't work with GetNWInt
	print("[nZ LS] Local player was invalid! Attempting to obtain the local player...")
	
	timer.Create("nz_level_system_local_player_timer", 20.0, 0, function()
		local_player = LocalPlayer()
		
		if local_player then
			calc_vars()
			print("[nZ LS] Obtained local player.")
			
			hook.Add("Think", "nz_level_system_think_hook", function()
				--
				local fetch = local_player:GetNWInt("nz_ls_exp")
				
				if fetch ~= exp then
					current_level = calc_level(fetch)
					exp = fetch
					exp_passed = calc_exp(current_level)
					exp_required = calc_exp(current_level + 1)
					percent = (exp - exp_passed) / exp_required
					percent_bar_w = percent * bar_w
					
					--we cache the text so it isn't created every frame
					bar_level_text = "level " .. tostring(current_level)
				end
			end)
			
			timer.Remove("nz_level_system_local_player_timer")
		end
	end)
end

hook.Add("OnScreenSizeChanged", "nz_ls_screen_res_changed_hook", function()
	calc_vars()
	set_font(16 * bar_scale, 150)
end)

local fl_draw_DrawText = draw.DrawText
local fl_draw_RoundedBox = draw.RoundedBox

hook.Add("HUDPaint", "nz_level_system_hud_paint_hook", function()
	if GetConVar("cl_drawhud"):GetBool() then
		--TODO possibly add stencil animations with custom textures?
		fl_draw_RoundedBox(bar_bg_corner, bar_bg_x, bar_bg_y, bar_bg_w, bar_bg_h, color_black)
		fl_draw_RoundedBox(bar_corner, bar_x, bar_y, percent_bar_w, bar_h, color_blood)
		
		--I may make it more descriptive later
		fl_draw_DrawText(bar_level_text, bar_level_text_font, bar_level_text_x, bar_level_text_y, color_white, TEXT_ALIGN_CENTER)
	end
end)