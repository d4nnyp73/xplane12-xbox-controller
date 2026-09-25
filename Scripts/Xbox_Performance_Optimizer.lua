-- Xbox HUD adaptive performance helper for X-Plane 12 / FlyWithLua.
-- It only manages the optional overlay; it does not alter flight physics,
-- rendering settings, aircraft systems, or controller input.

local frame_period = dataref_table('sim/operation/misc/frame_rate_period')
local paused = dataref_table('sim/time/paused')
local active = dataref_table('daniel/xbox/active')
local enabled, hud_was_on = true, false
local filtered_fps = 60
local low_frames, good_frames = 0, 0
local low_limit, restore_limit = 28, 35

local function toggle_hud()
    command_once('daniel/xbox/toggle_hud')
    hud_was_on = not hud_was_on
end

function daniel_xbox_perf_toggle()
    enabled = not enabled
    if not enabled then
        low_frames, good_frames = 0, 0
        if hud_was_on and active[0] == 1 then toggle_hud() end
        logMsg('[Xbox Performance] Adaptive HUD paused.')
    else
        logMsg('[Xbox Performance] Adaptive HUD active: hide below '..low_limit..' FPS, restore above '..restore_limit..' FPS.')
    end
end

function daniel_xbox_perf_frame()
    if not enabled or active[0] ~= 1 or paused[0] == 1 then return end
    local dt = frame_period[0]
    if dt <= 0 or dt > 0.25 then return end
    local fps = 1 / dt
    filtered_fps = filtered_fps * 0.94 + fps * 0.06
    if filtered_fps < low_limit then
        low_frames = low_frames + 1; good_frames = 0
    elseif filtered_fps > restore_limit then
        good_frames = good_frames + 1; low_frames = 0
    else
        low_frames = math.max(0, low_frames-1)
        good_frames = math.max(0, good_frames-1)
    end
    -- Require sustained conditions to prevent visible on/off oscillation.
    if low_frames >= 90 and not hud_was_on then
        toggle_hud()
        logMsg(string.format('[Xbox Performance] HUD hidden at %.0f FPS.',filtered_fps))
        low_frames=0
    elseif good_frames >= 180 and hud_was_on then
        toggle_hud()
        logMsg(string.format('[Xbox Performance] HUD restored at %.0f FPS.',filtered_fps))
        good_frames=0
    end
end

create_command('daniel/xbox/performance_toggle','Toggle adaptive HUD performance mode','daniel_xbox_perf_toggle()','','')
add_macro('Xbox Performance Optimizer','daniel_xbox_perf_toggle()','daniel_xbox_perf_toggle()','activate')
do_every_frame('daniel_xbox_perf_frame()')
do_on_exit('if hud_was_on and active[0] == 1 then command_once("daniel/xbox/toggle_hud") end')
