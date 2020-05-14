print("Core loaded (client realm)")

local calc_exp, calc_level = include("fn_core.lua")

--locals
local bar_scale = 1
local bubbles = {}
local current_level = 0
local exp = 0
local exp_passed = 0
local exp_required = 0
local local_player
local pi = math.pi

--additional math constants
local half_pi = math.pi * 0.5
local tau = pi * 2

--indented to make my editor create a code folder
----render parameters
	local bar_h
	local bar_high_bg_c
	local bar_high_bg_h
	local bar_high_bg_w
	local bar_high_bg_x
	local bar_high_bg_y
	local bar_high_fg_c
	local bar_high_fg_h
	local bar_high_fg_w
	local bar_high_fg_x
	local bar_high_fg_y
	local bar_level_text = "level 0"
	local bar_level_text_font
	local bar_level_text_x
	local bar_level_text_y
	local bar_magin_y = 0
	local bar_mat = Material("gui/nzombies_level_system/progress_bar.png")
	local bar_mat_bg = Material("gui/nzombies_level_system/progress_bar_composite.png")
	local bar_w
	local bar_x
	local bar_y
	local bubble_max_delay = 0.01
	local bubble_max_time = 3.0
	local bubble_max_size
	local bubble_max_x
	local bubble_max_y
	local bubble_min_delay = 0.05
	local bubble_min_time = 2.0
	local bubble_min_size
	local bubble_min_x
	local bubble_min_y
	local bubble_speed
	local circle_mat = Material("gui/nzombies_level_system/circle.png")
	local percent = 0
	local percent_mask_w = 0
	local scr_h
	local scr_w

--colors
local color_blood = Color(255, 7, 7)
local color_blood_bg = Color(128, 32, 32)

--convar defs
local nz_ls_progress_bar_low_perf = CreateClientConVar("nz_ls_progress_bar_low_perf", "0", true, "Should the nZ LS progress bar be in low performance mode.")

--convar values
local hud_high = not nz_ls_progress_bar_low_perf:GetBool()

--caching for quicker access
----cached functions
	local fl_draw_DrawText = draw.DrawText
	local fl_draw_RoundedBox = draw.RoundedBox
	local fl_math_cos = math.cos
	local fl_math_rand = math.Rand
	local fl_math_random = math.random
	local fl_math_sin = math.sin
	local fl_render_ClearStencil = render.ClearStencil
	local fl_render_SetStencilCompareFunction = render.SetStencilCompareFunction
	local fl_render_SetStencilEnable = render.SetStencilEnable
	local fl_render_SetStencilFailOperation = render.SetStencilFailOperation
	local fl_render_SetStencilPassOperation = render.SetStencilPassOperation
	local fl_render_SetStencilReferenceValue = render.SetStencilReferenceValue
	local fl_render_SetStencilTestMask = render.SetStencilTestMask
	local fl_render_SetStencilWriteMask = render.SetStencilWriteMask
	local fl_render_SetStencilZFailOperation = render.SetStencilZFailOperation
	local fl_surface_DrawPoly = surface.DrawPoly
	local fl_surface_DrawRect = surface.DrawRect
	local fl_surface_DrawTexturedRect = surface.DrawTexturedRect
	local fl_surface_DrawTexturedRectUV = surface.DrawTexturedRectUV
	local fl_surface_SetDrawColor = surface.SetDrawColor
	local fl_surface_SetMaterial = surface.SetMaterial
	local fl_surface_SetMaterial_White = draw.NoTexture

--globals
--I have a table for this specific font I use in my progress bar addon. This will keep me from making duplicate fonts
--I may make the functions themself global, but for now I'll have it like this
CryotheumDynamicFontData = CryotheumDynamicFontData or {}
NZLSData = {}
NZLSSkillVisibility = {}

--local functions
local function calc_bubble_size(cur_time, start_time, life_time, size) return fl_math_sin((cur_time - start_time) / life_time * tau) * size end

local function calc_vars()
	--TODO reuse the low def variables with high def values when using high quality bar
	scr_h = ScrH()
	scr_w = ScrW()
	
	--turns out some peeps play with verticle resolutions, so we can't assume scr_h is smaller than scr_w
	local scr_min = math.min(scr_w, scr_h)
	
	--low quality bar
	bar_h = 48 * bar_scale
	bar_w = 384 * bar_scale
	bar_x = (scr_w - bar_w) * 0.5
	bar_y = scr_h - bar_h - bar_magin_y
	
	bar_level_text_x = scr_w * 0.5 --bar_x + bar_w * 0.5 --basically just 
	bar_level_text_y = bar_y + bar_h * 0.5
	
	--high quality bar
	bar_high_bg_c = math.floor(21 * bar_scale * 0.5)
	bar_high_bg_h = 21 * bar_scale
	bar_high_bg_w = 372 * bar_scale
	bar_high_bg_x = bar_x + 6 * bar_scale
	bar_high_bg_y = bar_y + 14 * bar_scale
	bar_high_fg_c = math.floor(15 * bar_scale * 0.5)
	bar_high_fg_h = 15 * bar_scale
	bar_high_fg_w = 366 * bar_scale
	bar_high_fg_x = bar_x + 9 * bar_scale
	bar_high_fg_y = bar_y + 17 * bar_scale
	
	local bubble_size = scr_min * 0.015 * bar_scale
	
	bubble_max_size = bubble_size * 1.2
	bubble_max_x = bar_high_bg_x + bar_high_bg_w
	bubble_max_y = bar_high_bg_y + bar_high_bg_h
	bubble_min_size = bubble_size * 0.8
	bubble_min_x = bar_high_bg_x
	bubble_min_y = bar_high_bg_y
	bubble_speed = scr_min * 0.0025 * bar_scale
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

local function spawn_bubble()-- 2 - 1 = 1 and -1
	if gui.IsGameUIVisible() then
		bubbles = {}
		
		return
	end
	
	local velocity_angle = fl_math_rand(0, half_pi) - half_pi * 1.5 + (fl_math_random(0, 1) * pi)
	
	table.insert(bubbles, {
		life = fl_math_rand(bubble_min_time, bubble_max_time),
		time = CurTime(),
		size = fl_math_rand(bubble_min_size, bubble_max_size),
		vel_x = fl_math_cos(velocity_angle) * bubble_speed,
		vel_y = fl_math_sin(velocity_angle) * bubble_speed,
		x = fl_math_rand(bubble_min_x, bubble_max_x),
		y = fl_math_rand(bubble_min_y, bubble_max_y)
	})
end

local function spawn_bubbles()
	if hud_high then
		--check if we are still using the high res hud
		spawn_bubble()
		
		timer.Create("nzls_bubble_spawn", math.random(bubble_min_delay, bubble_max_delay), 1, spawn_bubbles)
	end
end

--post function set up
calc_vars()
set_font(16 * bar_scale, 150)

--hook functions
local function draw_hud_bubbles()
	fl_surface_SetMaterial(circle_mat)
	
	for _, bubble in pairs(bubbles) do
		if bubble.off_x then
			local size = bubble.cur_size
			
			fl_surface_DrawTexturedRect(bubble.x + bubble.off_x, bubble.y + bubble.off_y, size, size)
		end
	end
end

local function draw_hud_bubbles_bg()
	--we also set up variables for the future bubbles here
	local cur_time = CurTime()
	
	fl_surface_SetMaterial(circle_mat)
	
	for index, bubble in pairs(bubbles) do
		local size = calc_bubble_size(cur_time, bubble.time, bubble.life, bubble.size)
		
		if size > -6 then
			local diff_time = cur_time - bubble.time
			local size_bg = size + 6
			local size_half = size * 0.5
			local size_half_bg = size_bg * 0.5
			
			local off_x = bubble_speed * bubble.vel_x * diff_time
			local off_y = bubble_speed * bubble.vel_y * diff_time
			
			bubbles[index].cur_size = size
			bubbles[index].off_x = off_x - size_half
			bubbles[index].off_y = off_y - size_half
			
			fl_surface_DrawTexturedRect(bubble.x + off_x - size_half_bg, bubble.y + off_y - size_half_bg, size_bg, size_bg)
		else table.remove(bubbles, index) end --remove them if they are donezo
	end
end

local function draw_hud_high()
	fl_draw_RoundedBox(bar_high_bg_c, bar_high_bg_x, bar_high_bg_y, bar_high_bg_w, bar_high_bg_h, color_black)
	draw_hud_bubbles_bg()
	
	fl_draw_RoundedBox(bar_high_fg_c, bar_high_fg_x, bar_high_fg_y, bar_high_fg_w, bar_high_fg_h, color_blood_bg)
	fl_surface_SetDrawColor(color_blood_bg)
	draw_hud_bubbles()
	
	fl_render_ClearStencil()
	fl_render_SetStencilEnable(true)
	fl_render_SetStencilCompareFunction(STENCIL_NEVER)
	fl_render_SetStencilPassOperation(STENCIL_KEEP)
	fl_render_SetStencilFailOperation(STENCIL_REPLACE)
	fl_render_SetStencilZFailOperation(STENCIL_KEEP)
	fl_render_SetStencilWriteMask(0xFF)
	fl_render_SetStencilTestMask(0xFF)
	fl_render_SetStencilReferenceValue(1)
	
	--mask
	fl_surface_DrawRect(0, 0, percent_mask_w, scr_h)
	
	--swtich
	--I swap the pass and fail operation so we write 1, to prevent problems with overlapping
	fl_render_SetStencilPassOperation(STENCIL_REPLACE) 
	fl_render_SetStencilFailOperation(STENCIL_KEEP)
	fl_render_SetStencilCompareFunction(STENCIL_EQUAL)
	
	--rendered
	fl_draw_RoundedBox(bar_high_fg_c, bar_high_fg_x, bar_high_fg_y, bar_high_fg_w, bar_high_fg_h, color_blood)
	draw_hud_bubbles()
	
	fl_render_SetStencilEnable(false)
end

local function draw_hud_low()
	--for lower performance peeps
	fl_surface_SetDrawColor(color_blood_bg)
	fl_surface_SetMaterial(bar_mat_bg)
	fl_surface_DrawTexturedRect(bar_x, bar_y, bar_w, bar_h)
	
	fl_render_ClearStencil()
	fl_render_SetStencilEnable(true)
	fl_render_SetStencilCompareFunction(STENCIL_NEVER)
	fl_render_SetStencilPassOperation(STENCIL_KEEP)
	fl_render_SetStencilFailOperation(STENCIL_REPLACE)
	fl_render_SetStencilZFailOperation(STENCIL_KEEP)
	fl_render_SetStencilWriteMask(0xFF)
	fl_render_SetStencilTestMask(0xFF)
	fl_render_SetStencilReferenceValue(1)
	
	--mask
	--because we only are making one rendering call below, we can save on using functions to swap the pass and fail operation
	fl_surface_DrawRect(bar_x, bar_y, percent_mask_w, bar_h)
	
	fl_render_SetStencilCompareFunction(STENCIL_EQUAL)
	
	--rendered
	fl_surface_SetDrawColor(color_blood) 
	fl_surface_SetMaterial(bar_mat)
	fl_surface_DrawTexturedRect(bar_x, bar_y, bar_w, bar_h)
	
	fl_render_SetStencilEnable(false)
end

--post hook function setup
local draw_hud_pre = hud_high and draw_hud_high or draw_hud_low

--cvars
cvars.AddChangeCallback("nz_ls_progress_bar_low_perf", function()
	hud_high = not nz_ls_progress_bar_low_perf:GetBool()
	draw_hud_pre = hud_high and draw_hud_high or draw_hud_low
	
	if hud_high then timer.Create("nzls_bubble_spawn", 0.1, 1, spawn_bubbles)
	else bubbles = {} end
end)

--hooks
hook.Add("HUDPaint", "nzls_hud_paint_hook", function()
	draw_hud_pre()
	
	surface.SetFont(bar_level_text_font)
	
	local text_w, text_h = surface.GetTextSize(bar_level_text)
	
	surface.SetTextColor(color_white)
	surface.SetTextPos(bar_level_text_x - text_w * 0.5, bar_level_text_y - text_h * 0.5) 
	surface.DrawText(bar_level_text)
end)

hook.Add("InitPostEntity", "nzls_entity_init_hook", function()
	--local player is null until this hook is called
	local_player = LocalPlayer()
	
	calc_vars()
	
	hook.Add("Think", "nzls_think_hook", function()
		local fetch = local_player:GetNWInt("nz_ls_exp")
		
		if fetch ~= exp then
			current_level = calc_level(fetch)
			exp = fetch
			exp_passed = calc_exp(current_level)
			exp_required = calc_exp(current_level + 1)
			percent = (exp - exp_passed) / exp_required
			percent_mask_w = percent * bar_w  + (hud_high and bar_high_bg_x or 0)
			
			--we cache the text so it isn't created every frame
			bar_level_text = "level " .. tostring(current_level)
		end
	end)
	
	if hud_high then timer.Create("nzls_bubble_spawn", 1, 1, spawn_bubbles) end
end)

hook.Add("OnScreenSizeChanged", "nzls_screen_res_changed_hook", function()
	calc_vars()
	set_font(16 * bar_scale, 150)
end)

--net
net.Receive("nzls_data", function(size, ply)
	local length = net.ReadUInt(32)
	local ply_bit_data = net.ReadData(length)
	local ply_data = util.Decompress(ply_bit_data)
	
	print("Receieved a player data update with a summed length of " .. size .. " and a data length of " .. length .. ".")
	
	NZLSData = util.JSONToTable(ply_data)
	NZLSSkillVisibility = {}
	
	--move to cl_menu
	
	local ply_skills = NZLSData.skills
	local points = NZLSData.points
	
	for skill, skill_data in pairs(NZLS.skills) do
		local ply_skill = ply_skills[skill]
		
		if ply_skill then
			print("skill data for skill", ply_skill)
			PrintTable(ply_skills[skill], 1)
			
			NZLSSkillVisibility[skill] = 2
		else
			--[[
			local requirements = skill_data.Requirements
			local requirements_met = true
			
			if requirements.Skills then
				for skill_name, level in pairs(requirements.Skills) do
					local skill_data = ply_skills[skill_name] and ply_skills[skill_name].level or 0
					
					if skill_data >= level then continue end
					
					print("Did not meet " .. skill_name .. " skill level requirement of " .. skill_data .. " for skill " .. skill .. ".")
					
					requirements_met = false
					
					break
				end
			end
			]]
		end
	end
end)