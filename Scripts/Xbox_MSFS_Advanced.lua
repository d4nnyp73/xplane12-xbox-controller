-- Xbox One S Bluetooth (045e:02fd), macOS, X-Plane 12 / FlyWithLua 2.8.
-- Guide and original settings: /Users/daniel/XPlane-Controller/
-- X-Plane global indices include the eight hat directions before HID buttons.
local cfg = {deadzone=0.12, look_speed=115, invert_y=false}
-- macOS HID order for this Xbox Bluetooth pad: the D-pad is exposed as
-- directions 0..7, then A/B/View/X/Y/Menu/LB/RB/LS/RS as 8..17.
local B = {A=8, B=9, X=11, Y=12, LB=14, RB=15,
           VIEW=10, MENU=13, LS=16, RS=17}
local axes = dataref_table('sim/joystick/joystick_axis_values')
local on_ground = dataref_table('sim/flightmodel/failures/onground_any')
local brake_override = dataref_table('sim/operation/override/override_toe_brakes')
local rudder_override = dataref_table('sim/operation/override/override_joystick_heading')
local rudder = dataref_table('sim/joystick/yoke_heading_ratio')
local left_brake = dataref_table('sim/cockpit2/controls/left_brake_ratio')
local right_brake = dataref_table('sim/cockpit2/controls/right_brake_ratio')
local assignments = dataref_table('sim/joystick/joystick_axis_assignments')
local heading = dataref_table('sim/graphics/view/pilots_head_psi')
local pitch = dataref_table('sim/graphics/view/pilots_head_the')
local external = dataref_table('sim/graphics/view/view_is_external')
local period = dataref_table('sim/operation/misc/frame_rate_period')
local paused = dataref_table('sim/time/paused')
local replay = dataref_table('sim/time/is_in_replay')
local status = create_dataref_table('daniel/xbox/active', 'Int')
local enabled, show_help = false, true
local trim = dataref_table('sim/cockpit2/controls/elevator_trim')
local runtime = dataref_table('sim/time/total_running_time_sec')
local flash_until = {}
local show_hud = false
-- The HUD preference is independent from the current camera.  This lets it
-- disappear automatically in the cockpit while remaining available outside.
local hud_user_enabled = false
local hud_ias = dataref_table('sim/cockpit2/gauges/indicators/airspeed_kts_pilot')
local hud_vso = dataref_table('sim/aircraft/view/acf_Vso')
local hud_stall_speed = dataref_table('sim/aircraft/view/acf_Vs')
local hud_vfe = dataref_table('sim/aircraft/view/acf_Vfe')
local hud_vno = dataref_table('sim/aircraft/view/acf_Vno')
local hud_vne = dataref_table('sim/aircraft/view/acf_Vne')
local hud_aoa = dataref_table('sim/flightmodel/position/alpha')
local hud_slip = dataref_table('sim/cockpit2/gauges/indicators/slip_deg')
local hud_turn = dataref_table('sim/cockpit2/gauges/indicators/turn_rate_heading_deg_pilot')
local hud_turn_filtered = 0
local engine_assist=dofile(SYSTEM_DIRECTORY..'Resources/plugins/FlyWithLua/Modules/daniel_engine_assist.lua')
function daniel_xbox_toggle_engine_assist()
    if enabled then engine_assist.toggle() end
end
local hud_stall_alpha = dataref_table('sim/aircraft/overflow/acf_stall_warn_alpha')
local hud_gs = dataref_table('sim/flightmodel/position/groundspeed')
local hud_flaps = dataref_table('sim/flightmodel/controls/flaprat')
local hud_flap_request = dataref_table('sim/flightmodel/controls/flaprqst')
local hud_alt = dataref_table('sim/cockpit2/gauges/indicators/altitude_ft_pilot')
local hud_autothrottle = dataref_table('sim/cockpit2/autopilot/autothrottle_on')
local hud_ap_servos = dataref_table('sim/cockpit2/autopilot/servos_on')
local hud_agl = dataref_table('sim/flightmodel/position/y_agl')
local hud_vs = dataref_table('sim/cockpit2/gauges/indicators/vvi_fpm_pilot')
local hud_throttle = dataref_table('sim/cockpit2/engine/actuators/throttle_ratio')
local hud_prop = dataref_table('sim/cockpit2/engine/actuators/prop_ratio')
local hud_mixture = dataref_table('sim/cockpit2/engine/actuators/mixture_ratio')
local hud_prop_type = dataref_table('sim/aircraft/prop/acf_prop_type')
local hud_helicopter = dataref_table('sim/aircraft2/metadata/is_helicopter')
local hud_n1 = dataref_table('sim/cockpit2/engine/indicators/N1_percent')
local hud_rpm = dataref_table('sim/cockpit2/engine/indicators/engine_speed_rpm')
local hud_types = dataref_table('sim/aircraft/prop/acf_en_type')
local hud_count = dataref_table('sim/aircraft/engine/acf_num_engines')
local hud_to = dataref_table('sim/aircraft/controls/acf_takeoff_trim')
local hud_redline = dataref_table('sim/aircraft/engine/acf_RSC_redline_eng_per_engine')
function daniel_xbox_toggle_hud()
    hud_user_enabled=not hud_user_enabled
    show_hud=hud_user_enabled
end
local view_index = 1
local views = {'sim/view/3d_cockpit_cmnd_look','sim/view/chase','sim/view/circle','sim/view/runway'}
local exterior_index=2
local cockpit_slot=nil
local function cockpit_slots()
    local path=type(get)=='function' and get('sim/aircraft/view/acf_relative_path') or nil
    if type(path)~='string' or not path:match('%.acf$') then return {} end
    if path:sub(1,1)~='/' then path=SYSTEM_DIRECTORY..path end
    local prefs=io.open(path:gsub('%.acf$','_prefs.txt'),'r')
    local slots={}
    if prefs then
        for line in prefs:lines() do
            local slot,kind=line:match('^_iql_view_type_(%d+)%s+(%S+)')
            slot=tonumber(slot)
            if slot and slot<20 and kind=='v_3dc' then slots[#slots+1]=slot end
        end
        prefs:close()
    end
    table.sort(slots)
    return slots
end
function daniel_xbox_cycle_view(direction)
    if external[0]==0 then
        local slots=cockpit_slots()
        if #slots==0 then
            logMsg('[Xbox Views] No saved cockpit Quick Looks found.')
            return
        end
        local index=nil
        for i,slot in ipairs(slots) do if slot==cockpit_slot then index=i end end
        index=index and ((index-1+direction)%#slots+1) or (direction>0 and 1 or #slots)
        cockpit_slot=slots[index]
        command_once('sim/view/quick_look_'..cockpit_slot)
        logMsg('[Xbox Views] Cockpit Quick Look '..(cockpit_slot+1))
    else
        exterior_index=2+(exterior_index-2+direction)%(#views-1)
        view_index=exterior_index
        command_once(views[exterior_index])
    end
end
function daniel_xbox_toggle_help() show_help=not show_help end
local held, previous, routes = {}, {}, {}
local old_axes, old_buttons = {}, {}
local saved = SYSTEM_DIRECTORY .. 'Output/preferences/X-Plane Joystick Settings.prf'
local valid_device = false
local f = io.open(saved, 'r')
if f then
    for line in f:lines() do
        if line:match('^_joy_unique_id0 VID:1118PID:765%s*$') then valid_device = true end
        local n, cmd = line:match('^_joy_BUTN_use(%d+) (.+)$')
        if n and tonumber(n) <= 22 then old_buttons[tonumber(n)] = cmd end
    end
    f:close()
end
-- Use the durable installation snapshot for restoration, even if X-Plane
-- saves the temporary (empty) button assignments while this script is active.
local baseline=io.open('/Users/daniel/XPlane-Controller/backup-2026-09-12/X-Plane Joystick Settings.prf','r')
if baseline then
    for line in baseline:lines() do
        local n,cmd=line:match('^_joy_BUTN_use(%d+) (.+)$')
        if n and tonumber(n)<=22 then old_buttons[tonumber(n)]=cmd end
    end
    baseline:close()
end

local function clamp(v, a, b) return math.max(a, math.min(b, v)) end
local function stick(i)
    local v = clamp((axes[i] - 0.5) * 2, -1, 1)
    if math.abs(v) <= cfg.deadzone then return 0 end
    local n = (math.abs(v) - cfg.deadzone) / (1-cfg.deadzone)
    return (v < 0 and -1 or 1) * n * n
end
local function release_all()
    for cmd in pairs(held) do command_end(cmd) end
    held = {}
end
local function apply_holds(wanted)
    for cmd in pairs(held) do
        if not wanted[cmd] then command_end(cmd); held[cmd] = nil end
    end
    for cmd in pairs(wanted) do
        if not held[cmd] then command_begin(cmd); held[cmd] = true end
    end
end

function daniel_xbox_disable()
    engine_assist.stop()
    release_all()
    if enabled then
        brake_override[0] = 0
        rudder_override[0] = 0
        left_brake[0], right_brake[0] = 0, 0
        for i=2,5 do assignments[i] = old_axes[i] end
        for i=0,22 do set_button_assignment(i, old_buttons[i] or 'sim/none/none') end
    end
    enabled = false
    status[0] = 0
    previous, routes = {}, {}
end

function daniel_xbox_enable()
    if enabled then return end
    -- Only claim the device/layout observed in Daniel's X-Plane log.
    if not valid_device or axes[0] < 0 or axes[2] < 0 or
       assignments[0] ~= 2 or assignments[1] ~= 1 or
       (assignments[4] ~= 74 and assignments[4] ~= 0) or
       (assignments[5] ~= 75 and assignments[5] ~= 0) then
        logMsg('[Xbox Advanced] Not enabled: connect Xbox Bluetooth in original slot and retain native roll/pitch and split rudder axes.')
        return
    end
    -- X-Plane can save our cleared assignments while the script is active.
    -- Accept those on restart and restore the correct native axis per slot.
    local native_axes = {[2]=41, [3]=42, [4]=74, [5]=75}
    for i=2,5 do
        old_axes[i] = assignments[i] ~= 0 and assignments[i] or native_axes[i]
        assignments[i] = 0
    end
    for i=0,22 do
        set_button_assignment(i, 'sim/none/none')
        previous[i] = button(i)
    end
    enabled = true
    brake_override[0] = 1
    rudder_override[0] = 1
    status[0] = 1
    logMsg('[Xbox Advanced] Active: sticky look, trim, modifier buttons. LB+Menu: help.')
end

local function center_view()
    command_once(external[0] == 1 and 'sim/view/chase' or 'sim/view/3d_cockpit_cmnd_look')
    if external[0] == 0 then heading[0] = 0; pitch[0] = 0 end
end

function daniel_xbox_frame()
    if not enabled then return end
    if paused[0] == 0 then
        -- This dataref is already an instrument deflection, not deg/sec.
        -- Reduce its visual gain and damp it independently of draw frequency.
        local target=clamp(hud_turn[0]*0.35,-30,30)
        local blend=1-math.exp(-clamp(period[0],0,0.1)/0.4)
        hud_turn_filtered=hud_turn_filtered+(target-hud_turn_filtered)*blend
    end
    if axes[0] < 0 or axes[2] < 0 then
        daniel_xbox_disable()
        logMsg('[Xbox Advanced] Controller disconnected; assignments restored.')
        return
    end
    local now, rising = {}, {}
    for i=0,22 do
        now[i] = button(i); rising[i] = now[i] and not previous[i]
        if rising[i] then flash_until[i]=runtime[0]+0.22 end
    end
    local lb, rb = now[B.LB], now[B.RB]
    local wanted = {}
    local flight_ok = paused[0] == 0 and replay[0] == 0
    if flight_ok then engine_assist.step(period[0]) end
    -- Rudder always follows trigger differential. Braking is gated by BOTH
    -- triggers, then each trigger independently controls its own wheel.
    local lt,rt=clamp(axes[4],0,1),clamp(axes[5],0,1)
    -- Trigger differential: RT positive is right rudder, LT positive left.
    rudder[0]=clamp(rt-lt,-1,1)
    if on_ground[0] == 1 then
        local both_triggers=lt>0.12 and rt>0.12
        -- Small activation deadzone rejects trigger rest noise. LB/RB retain
        -- their direct full-brake action on the corresponding wheel.
        left_brake[0] = now[B.LB] and 1 or (both_triggers and lt or 0)
        right_brake[0] = now[B.RB] and 1 or (both_triggers and rt or 0)
    else
        left_brake[0], right_brake[0] = 0, 0
    end
    -- Latch each face-button's action when pressed. Releasing a modifier
    -- while a face button remains held must never turn gear/flaps into throttle.
    for _, i in ipairs({B.A,B.B,B.X,B.Y}) do
        if rising[i] then
            local cmd, continuous
            if lb then
                if i==B.A then cmd='sim/flight_controls/speed_brakes_down_one'
                elseif i==B.B then cmd='sim/flight_controls/speed_brakes_up_one'
                elseif i==B.X then cmd='sim/flight_controls/park_brake_toggle'
                elseif i==B.Y then cmd='sim/flight_controls/landing_gear_toggle' end
            elseif rb then
                -- A/B select manual engine-control layers for the D-pad.
                if i==B.X then cmd='sim/autopilot/servos_toggle'
                elseif i==B.Y and flight_ok then daniel_xbox_toggle_engine_assist() end
            else
                if i==B.A then cmd='sim/engines/throttle_up'; continuous=true
                elseif i==B.B then cmd='sim/engines/throttle_down'; continuous=true
                elseif i==B.X then cmd='sim/flight_controls/brakes_regular'; continuous=true
                elseif i==B.Y then center_view() end
            end
            if cmd and flight_ok then
                if continuous then routes[i]=cmd else command_once(cmd) end
            end
        end
        if not now[i] then routes[i]=nil end
        if flight_ok and routes[i] then wanted[routes[i]]=true end
    end
    if rising[B.VIEW] or rising[18] then
        -- The Xbox View key is a two-window key: use a direct, reliable
        -- cockpit/exterior toggle instead of relying on view-cycle state.
        if external[0] == 0 then
            view_index=2; exterior_index=2; command_once('sim/view/chase')
        else
            view_index=1; command_once('sim/view/3d_cockpit_cmnd_look')
            heading[0]=0; pitch[0]=0
        end
    end
    if rising[B.RS] or rising[22] then center_view() end
    if rising[B.MENU] or rising[19] then
        if lb then daniel_xbox_toggle_help()
        elseif rb then daniel_xbox_toggle_hud()
        else command_once('sim/operation/pause_toggle') end
    end
    local x,y=stick(2),stick(3)
    local up = now[0] or now[1] or now[7]
    local down = now[3] or now[4] or now[5]
    local left = now[5] or now[6] or now[7]
    local right = now[1] or now[2] or now[3]
    if rb and flight_ok then
        -- A/B temporarily replace camera selection with manual engine input.
        -- Holding both cancels input; releasing the D-pad ends the command.
        if now[B.A] or now[B.B] then
            if now[B.A]~=now[B.B] and up~=down then
                if now[B.A] then
                    engine_assist.release_prop()
                    wanted[up and 'sim/engines/prop_up' or 'sim/engines/prop_down']=true
                else
                    engine_assist.release_mixture()
                    wanted[up and 'sim/engines/mixture_up' or 'sim/engines/mixture_down']=true
                end
            end
        elseif rising[0] then view_index=1; command_once(views[1])
        elseif rising[4] then view_index=2; exterior_index=2; command_once(views[2])
        elseif rising[2] then daniel_xbox_cycle_view(1)
        elseif rising[6] then daniel_xbox_cycle_view(-1) end
    elseif not lb and flight_ok then
        if rising[0] then command_once('sim/flight_controls/flaps_up') end
        if rising[4] then command_once('sim/flight_controls/flaps_down') end
    end
    if lb then
        if flight_ok then
            if y < -0.05 then wanted['sim/flight_controls/pitch_trim_down']=true end
            if y > 0.05 then wanted['sim/flight_controls/pitch_trim_up']=true end
        end
    elseif rb then
        if y < -0.05 then wanted['sim/general/zoom_in']=true end
        if y > 0.05 then wanted['sim/general/zoom_out']=true end
    elseif external[0]==0 then
        local dt=clamp(period[0],0,0.05)
        if x~=0 then heading[0]=(heading[0]+x*cfg.look_speed*dt+180)%360-180 end
        if y~=0 then pitch[0]=clamp(pitch[0]+y*(cfg.invert_y and 1 or -1)*cfg.look_speed*dt,-85,85) end
    else
        -- External camera uses the opposite drag convention to the cockpit.
        if x < -0.05 then wanted['sim/general/right']=true end
        if x > 0.05 then wanted['sim/general/left']=true end
        if y < -0.05 then wanted['sim/general/up']=true end
        if y > 0.05 then wanted['sim/general/down']=true end
    end
    if flight_ok and not rb then
        if lb then
            if left and not right then wanted['sim/flight_controls/rudder_trim_left']=true end
            if right and not left then wanted['sim/flight_controls/rudder_trim_right']=true end
        end
    end
    if not lb and not rb then
        if left and not right then wanted['sim/general/zoom_out']=true end
        if right and not left then wanted['sim/general/zoom_in']=true end
    end
    -- Cancel opposing trim inputs rather than starting both commands.
    if wanted['sim/flight_controls/pitch_trim_up'] and wanted['sim/flight_controls/pitch_trim_down'] then
        wanted['sim/flight_controls/pitch_trim_up']=nil
        wanted['sim/flight_controls/pitch_trim_down']=nil
    end
    apply_holds(wanted)
    previous=now
end

function daniel_xbox_help()
    if not enabled or not show_help then return end
    local lb,rb=button(B.LB),button(B.RB)
    local hud_columns=math.max(1,math.min(6,math.floor((SCREEN_WIDTH-48)/112)))
    local hud_rows=math.max(1,math.ceil(clamp(hud_count[0],0,16)/hud_columns))
    local ox,oy=18,show_hud and (170+hud_rows*110) or 18
    local function rect(x,y,w,h,r,g,b)
        glColor4f(r,g,b,0.94); glRectf(ox+x,oy+y,ox+x+w,oy+y+h)
    end
    local function text(x,y,s)
        glColor4f(0.91,0.94,0.97,1); draw_string_Helvetica_12(ox+x,oy+y,s)
    end
    local function disk(x,y,r,red,green,blue)
        glColor4f(red,green,blue,1); glBegin_TRIANGLE_FAN()
        glVertex2f(ox+x,oy+y)
        for i=0,32 do local a=i*math.pi/16; glVertex2f(ox+x+math.cos(a)*r,oy+y+math.sin(a)*r) end
        glEnd()
    end
    local function key(x,y,label,index,r,g,b)
        local pressed=button(index) or runtime[0]<(flash_until[index] or -1)
        disk(x,y-1,11,0.025,0.035,0.045)
        if pressed then disk(x,y,12,0.65,1,0.9)
        else disk(x,y,10,0.32,0.36,0.4) end
        if pressed then
            disk(x,y,9.5,0.2,0.85,0.7); glColor4f(0.015,0.06,0.06,1)
        else
            disk(x,y,8.5,0.07,0.09,0.12); glColor4f(r,g,b,1)
        end
        draw_string_Helvetica_12(ox+x-4,oy+y-4,label)
    end
    XPLMSetGraphicsState(0,0,0,0,1,0,0)
    rect(0,0,540,252,0.035,0.05,0.07)
    rect(0,249,540,3,0.2,0.8,0.75)
    text(14,230,'XBOX  /  '..(lb and 'LB: AIRCRAFT' or rb and 'RB: CAMERA & SYSTEMS' or 'STANDARD'))
    text(330,230,'LB + Menu: show / hide')
    -- Layered shell with tapered grips; sampled contour keeps rendering native.
    local shell={{49,176},{65,180},{85,180},{98,176},{130,176},{143,180},
        {163,180},{179,176},{190,167},{196,153},{201,132},{207,108},
        {210,88},{208,77},{202,71},{194,70},{186,75},{175,88},{163,99},
        {148,105},{80,105},{65,99},{53,88},{42,75},{34,70},{26,71},
        {20,77},{18,88},{21,108},{27,132},{32,153},{38,167}}
    local function body(scale,dy,r,g,b)
        glColor4f(r,g,b,1); glBegin_TRIANGLE_FAN(); glVertex2f(ox+114,oy+137+dy)
        for i=1,#shell+1 do local p=shell[(i-1)%#shell+1]
            glVertex2f(ox+114+(p[1]-114)*scale,oy+137+(p[2]-137)*scale+dy)
        end
        glEnd()
    end
    body(1.025,-3,0.015,0.025,0.035)
    body(1,0,0.36,0.4,0.45)
    body(0.977,0,0.17,0.2,0.24)
    local function pill(x,y,w,h,r,g,b)
        local rad=h/2
        rect(x+rad,y,w-h,h,r,g,b)
        disk(x+rad,y+rad,rad,r,g,b); disk(x+w-rad,y+rad,rad,r,g,b)
    end
    -- Triggers are visible above the shoulders, with live travel indicators.
    pill(43,186,36,12,0.1,0.13,0.17); pill(149,186,36,12,0.1,0.13,0.17)
    rect(48,186,26*clamp(axes[4],0,1),2,0.2,0.8,0.75)
    rect(154,186,26*clamp(axes[5],0,1),2,0.2,0.8,0.75)
    text(54,188,'LT'); text(160,188,'RT')
    pill(38,169,47,13,lb and 0.12 or 0.28,lb and 0.65 or 0.32,lb and 0.59 or 0.37)
    pill(143,169,47,13,rb and 0.12 or 0.28,rb and 0.65 or 0.32,rb and 0.59 or 0.37)
    text(53,172,'LB'); text(158,172,'RB')
    local function thumb(x,y,ax,ay,index,label)
        disk(x,y,18,0.035,0.05,0.07)
        disk(x,y,16.5,0.35,0.4,0.46)
        disk(x,y,15,0.075,0.095,0.12)
        local dx,dy=clamp((axes[ax]-0.5)*2,-1,1)*4,clamp((axes[ay]-0.5)*2,-1,1)*-4
        if button(index) then disk(x+dx,y+dy,12.5,0.2,0.8,0.75)
        else disk(x+dx,y+dy,12.5,0.24,0.28,0.33) end
        disk(x+dx,y+dy,10.5,0.12,0.15,0.19)
        text(x+dx-7,y+dy-4,label)
    end
    thumb(61,145,0,1,B.LS,'LS'); thumb(139,115,2,3,B.RS,'RS')
    disk(78,111,20,0.08,0.1,0.13)
    rect(72,93,12,36,0.34,0.38,0.43); rect(60,105,36,12,0.34,0.38,0.43)
    rect(73,94,10,34,0.17,0.2,0.24); rect(61,106,34,10,0.17,0.2,0.24)
    for i,p in pairs({[0]={78,123},[2]={90,111},[4]={78,99},[6]={66,111}}) do
        if button(i) then disk(p[1],p[2],5,0.2,0.8,0.75) end
    end
    key(176,124,'A',B.A,0.35,0.9,0.48); key(193,142,'B',B.B,1,0.36,0.38)
    key(159,142,'X',B.X,0.35,0.65,1); key(176,160,'Y',B.Y,1,0.83,0.3)
    disk(114,162,8,0.75,0.8,0.85); disk(114,162,6,0.13,0.17,0.21)
    key(99,143,'',B.VIEW,1,1,1); key(125,143,'',B.MENU,1,1,1)
    -- Actual View/Menu symbols instead of ambiguous V/M letters.
    rect(94,142,7,6,0.75,0.8,0.85); rect(95,143,5,4,0.07,0.09,0.12)
    rect(97,139,7,6,0.75,0.8,0.85); rect(98,140,5,4,0.07,0.09,0.12)
    for i=0,2 do rect(121,139+i*3,8,1,0.75,0.8,0.85) end
    local lines
    if lb then lines={'A / B   Speedbrakes extend / retract','X   Parking brake  |  Y   Landing gear',
        'RS up / down   Pitch trim','D-pad left / right   Rudder trim','View   Cockpit / External'}
    elseif rb then
        if button(B.A) and button(B.B) then
            lines={'A + B held: engine input cancelled','Release A or B to choose one control',
                'X   AP on/off | Y   Auto Mix/Prop','RS up/down   Zoom','Release A/B for D-pad camera views'}
        elseif button(B.A) then
            lines={'A held: MANUAL PROP','D-pad up: Fine / higher RPM','D-pad down: Coarse / lower RPM',
                'RS up/down: Zoom | X: AP on/off','Y: Auto Mix/Prop | Release A: Views'}
        elseif button(B.B) then
            lines={'B held: MANUAL MIXTURE','D-pad up: Richer mixture','D-pad down: Leaner mixture',
                'RS up/down: Zoom | X: AP on/off','Y: Auto Mix/Prop | Release B: Views'}
        else
            lines={'Hold A + D-pad up/down: Prop fine/coarse','Hold B + D-pad up/down: Mix rich/lean',
                'X: AP on/off | Y: Auto Mix/Prop | RS: Zoom',
                external[0]==0 and 'D-pad left/right: Cockpit Quick Looks' or 'D-pad left/right: External views',
                'D-pad up/down: Cockpit / Chase'}
        end
    else lines={'A / B   Throttle + / -  |  X   Brakes','Y or R3   Center view',
        'RS   Look around  |  LS   Fly','D-pad up/down   Flaps retract / extend','D-pad left / right   Zoom'} end
    for i,s in ipairs(lines) do text(223,194-i*22,s) end
    text(16,52,string.format('TRIM  %+.1f %%   |   LB + right stick: pitch trim',-trim[0]*100))
    rect(16,36,194,5,0.18,0.22,0.27)
    rect(16+clamp((trim[0]+1)*0.5,0,1)*190,32,4,13,0.2,0.8,0.75)
    text(223,35,rb and engine_assist.status() or 'View: Camera  |  RB+Menu: Flight HUD')
    text(16,14,'LT/RT: Rudder | Both: proportional brakes | LB/RB: extra controls')
end

function daniel_xbox_hud()
    -- Keep the overlay out of the cockpit.  A user-disabled HUD stays off in
    -- exterior views as well; switching views never changes that preference.
    if not enabled or not hud_user_enabled or external[0] == 0 then return end
    local n=math.floor(clamp(hud_count[0],0,16))
    local columns=math.max(1,math.floor((SCREEN_WIDTH-48-590)/120))
    local rows=math.max(1,math.ceil(n/columns))
    local engine_width=math.min(n,columns)*120
    local group_width=680+engine_width
    local x,y=(SCREEN_WIDTH-group_width)/2,22
    XPLMSetGraphicsState(0,0,0,0,1,0,0)
    local function label(dx,dy,s,big,muted,small)
        local font=small and draw_string_Helvetica_10 or (big and draw_string_Helvetica_18 or draw_string_Helvetica_12)
        -- Broad soft text shadow, with no rectangular instrument background.
        glColor4f(0,0.01,0.02,0.24)
        for _,offset in ipairs({{-3,-2},{3,-2},{-2,2},{2,2},{0,-4}}) do
            font(x+dx+offset[1],y+dy+offset[2],s)
        end
        glColor4f(0.015,0.025,0.035,0.95)
        for _,offset in ipairs({{-1,0},{1,0},{0,-1},{0,1}}) do
            font(x+dx+offset[1],y+dy+offset[2],s)
        end
        if muted then glColor4f(0.62,0.7,0.74,0.9)
        else glColor4f(0.93,0.98,1,1) end
        font(x+dx,y+dy,s)
    end
    local function box(dx,dy,bw,bh,r,g,b)
        glColor4f(r,g,b,0.95); glRectf(x+dx,y+dy,x+dx+bw,y+dy+bh)
    end
    local function ring(cx,cy,r,thickness,fraction,red,green,blue)
        local steps=math.ceil(clamp(fraction,0,1)*90)
        glColor4f(red,green,blue,1)
        for j=0,steps-1 do
            local a=math.rad(225-j*270/90)
            local b=math.rad(225-math.min(j+1,fraction*90)*270/90)
            glBegin_TRIANGLE_FAN()
            glVertex2f(x+cx+math.cos(a)*r,y+cy+math.sin(a)*r)
            glVertex2f(x+cx+math.cos(b)*r,y+cy+math.sin(b)*r)
            glVertex2f(x+cx+math.cos(b)*(r-thickness),y+cy+math.sin(b)*(r-thickness))
            glVertex2f(x+cx+math.cos(a)*(r-thickness),y+cy+math.sin(a)*(r-thickness))
            glEnd()
        end
    end
    local data_y=78+(rows-1)*110
    local assist_text=engine_assist.hud_status()
    -- Show real engagement, not just the armed autothrottle switch.
    if hud_autothrottle[0]==1 then
        assist_text=assist_text..(assist_text~='' and '  |  ' or '')..'AUTO THR'
    end
    local status_x=8
    if hud_ap_servos[0]==1 then
        -- A small green lamp and AP text; armed flight director alone is not AP.
        glColor4f(0.35,0.88,0.58,0.95)
        glBegin_TRIANGLE_FAN()
        for j=0,16 do
            local a=-j*2*math.pi/16
            glVertex2f(x+11+2.5*math.cos(a),y+data_y+52+2.5*math.sin(a))
        end
        glEnd()
        label(19,data_y+48,'AP',false)
        status_x=50
    end
    if assist_text~='' then label(status_x,data_y+48,assist_text,false,true) end
    -- Compact turn-and-slip instrument above the HUD. Use the instrument's
    -- ball deflection, not aerodynamic sideslip/AoA.
    local scx,scy=group_width/2,data_y+68
    local function stroke(x1,y1,x2,y2,width,r,g,b)
        local dx,dy=x2-x1,y2-y1
        local length=math.sqrt(dx*dx+dy*dy)
        if length==0 then return end
        local nx,ny=-dy/length*width/2,dx/length*width/2
        glColor4f(r,g,b,0.9)
        glBegin_TRIANGLE_FAN()
        glVertex2f(x+x1+nx,y+y1+ny)
        glVertex2f(x+x2+nx,y+y2+ny)
        glVertex2f(x+x2-nx,y+y2-ny)
        glVertex2f(x+x1-nx,y+y1-ny)
        glEnd()
    end
    for j=-36,35,3 do
        local a,b=scy+j*j/300,scy+(j+3)*(j+3)/300
        -- Slim shaded glass channel with a subtle lower highlight.
        stroke(scx+j,a,scx+j+3,b,10,0.08,0.11,0.13)
        stroke(scx+j,a-5,scx+j+3,b-5,1,0.52,0.61,0.65)
        stroke(scx+j,a+5,scx+j+3,b+5,1,0.32,0.41,0.45)
    end
    box(scx-8,scy-7,1,14,0.76,0.83,0.85)
    box(scx+7,scy-7,1,14,0.76,0.83,0.85)
    -- Reverse X-Plane's instrument sign for the displayed ball:
    -- rudder toward the ball ("step on the ball") recenters it.
    local ball=-clamp(hud_slip[0]/10,-1,1)*30
    local function bead(dx,dy,r,red,green,blue,alpha)
        glColor4f(red,green,blue,alpha)
        glBegin_TRIANGLE_FAN()
        for j=0,24 do
            local a=-j*2*math.pi/24
            glVertex2f(x+scx+ball+dx+r*math.cos(a),y+scy+ball*ball/300+dy+r*math.sin(a))
        end
        glEnd()
    end
    bead(0,-1,5.5,0,0.015,0.02,0.4)
    bead(0,0,4.5,0.43,0.58,0.6,1)
    bead(-0.35,0.5,3.6,0.72,0.83,0.83,1)
    bead(-1.2,1.7,1.2,0.94,0.98,1,0.65)
    local turn_angle=math.rad(hud_turn_filtered)
    local function turn_point(px,py)
        return scx+px*math.cos(turn_angle)+py*math.sin(turn_angle),
               scy+22-px*math.sin(turn_angle)+py*math.cos(turn_angle)
    end
    local ax,ay=turn_point(-27,0)
    local bx,by=turn_point(27,0)
    stroke(ax,ay-1,bx,by-1,4,0.04,0.07,0.09)
    stroke(ax,ay,bx,by,1.8,0.8,0.88,0.9)
    ax,ay=turn_point(0,0); bx,by=turn_point(0,8)
    stroke(ax,ay,bx,by,1.8,0.8,0.88,0.9)
    label(scx-53,scy+17,'L',false)
    label(scx+46,scy+17,'R',false)
    local fields={{'IAS  kt',string.format('%.0f',hud_ias[0]),8,data_y},
        {'ALT  ft BARO',string.format('%.0f',hud_alt[0]),105,data_y},
        {'V/S  ft/min',string.format('%+.0f',hud_vs[0]),248,data_y}}
    for i,f in ipairs(fields) do
        label(f[3],f[4],f[1],false); label(f[3],f[4]-25,f[2],true)
    end
    label(105,data_y-44,string.format('%.0f ft AGL',math.max(0,hud_agl[0])*3.280839895),false,true)
    label(8,data_y-47,string.format('GS %.0f kt',hud_gs[0]*1.943844492),false)
    -- Aircraft-specific IAS speed envelope. X-Plane exposes these limits in
    -- KIAS; Vx/Vy are not universal datarefs and are intentionally omitted.
    local function valid_speed(v)
        return type(v)=='number' and v==v and v>0 and v<1000
    end
    local vso,vs,vfe,vno,vne=hud_vso[0],hud_stall_speed[0],hud_vfe[0],hud_vno[0],hud_vne[0]
    -- Continuous rolling tape: only IAS moves the scale, never V/S or AoA.
    -- Fixed +/-30 kt window, or +/-60 kt for aircraft with Vne above 300 kt.
    local half_span=valid_speed(vne) and vne>300 and 60 or 30
    local ias=math.max(0,hud_ias[0])
    local center=data_y-19
    local bottom,top=center-52,center+52
    local function speed_y(v) return center+(v-ias)*52/half_span end
    local function segment(lo,hi,bx,bw,r,g,b)
        if not valid_speed(lo) or not valid_speed(hi) or hi<=lo then return end
        local y1,y2=math.max(bottom,speed_y(lo)),math.min(top,speed_y(hi))
        if y2>y1 then box(bx,y1,bw,y2-y1,r,g,b) end
    end
    box(-10,bottom,10,104,0.12,0.15,0.18)
    segment(vs,vno,-10,6,0.25,0.78,0.36)
    segment(vno,vne,-10,6,0.92,0.7,0.18)
    -- White flap range is a separate strip so it cannot cover the green arc.
    segment(vso,vfe,-3,3,0.95,0.97,1)
    if valid_speed(vne) then
        local red_bottom=math.max(bottom,speed_y(vne))
        if red_bottom<top then box(-10,red_bottom,10,top-red_bottom,0.85,0.15,0.12) end
    end
    local step=half_span==60 and 20 or 10
    for speed=math.max(0,math.ceil((ias-half_span)/step)*step),ias+half_span,step do
        local sy=speed_y(speed)
        box(-17,sy,5,1,0.85,0.91,0.95)
        if sy>bottom+6 and sy<top-6 then label(-47,sy-4,string.format('%d',speed),false) end
    end
    box(-13,center-1,16,2,0.2,0.95,0.8)
    if not (valid_speed(vs) and valid_speed(vno) and vno>vs) then
        label(8,data_y-65,'V-LIMITS N/A',false)
    end
    -- MSFS-style vertical AoA tape at the far right.
    local aoa_x=group_width-38; local aoa_bottom=data_y-70; local aoa_h=104
    local stall_alpha=hud_stall_alpha[0]>0 and hud_stall_alpha[0] or 15
    local aoa_max=math.max(20,stall_alpha*1.35)
    local aoa_ratio=clamp(hud_aoa[0]/aoa_max,0,1)
    box(aoa_x-4,aoa_bottom-4,28,aoa_h+8,0.18,0.2,0.23)
    label(aoa_x-1,aoa_bottom+aoa_h+13,'AOA',false)
    local usable=aoa_h-12; local safe=clamp(stall_alpha/aoa_max,0,1)
    local green_h=usable*safe*0.68
    local yellow_h=usable*safe*0.32
    box(aoa_x,aoa_bottom,20,green_h,0.08,0.55,0.08)
    box(aoa_x,aoa_bottom+green_h,20,yellow_h,0.72,0.6,0.12)
    box(aoa_x,aoa_bottom+green_h+yellow_h,20,usable-green_h-yellow_h,0.62,0.12,0.12)
    for i=1,5 do box(aoa_x,aoa_bottom+usable*i/6,20,2,0.28,0.3,0.33) end
    local aoa_marker=aoa_bottom+usable*aoa_ratio
    box(aoa_x-8,aoa_marker-2,36,4,0.93,0.98,1)
    box(aoa_x-12,aoa_marker-5,5,10,0.93,0.98,1)
    label(aoa_x-1,aoa_bottom-22,string.format('%+.1f°',hud_aoa[0]),false)
    -- Actual deployed position, not just the commanded lever setting.
    local flap=clamp(hud_flaps[0],0,1)
    local flap_target=clamp(hud_flap_request[0],0,1)
    local flap_y=data_y-20
    label(105,flap_y-47,string.format('FLAPS %.0f%%  > %.0f%%',flap*100,flap_target*100),false)
    box(105,flap_y-57,92,5,0.025,0.04,0.055)
    box(105,flap_y-56,92*flap,3,0.25,0.86,0.72)
    box(104+92*flap,flap_y-60,2,10,0.9,0.98,1)
    -- Yellow target marker: requested detent, while the green bar is actual
    -- movement. A thick marker keeps a quick button tap immediately visible.
    box(104+92*flap_target-2,flap_y-62,4,14,0.015,0.025,0.035)
    box(104+92*flap_target-1,flap_y-61,2,12,1,0.78,0.18)
    -- Draw a vector arrow instead of a font-dependent Unicode glyph.
    local ax,ay=230,data_y-18
    local direction=hud_vs[0]>50 and 1 or hud_vs[0]<-50 and -1 or 0
    box(ax-1,ay-8,3,16,0.015,0.025,0.035)
    if direction==0 then box(ax-5,ay,12,2,0.85,0.95,1)
    else
        local r,g,b=0.25,0.95,0.45
        if direction<0 then r,g,b=1,0.25,0.25 end
        box(ax,ay-7,2,14,r,g,b)
        glColor4f(r,g,b,1); glBegin_TRIANGLE_FAN()
        glVertex2f(x+ax+1,y+ay+direction*12)
        -- Match X-Plane's clockwise front faces for BOTH arrow directions.
        glVertex2f(x+ax+1+direction*6,y+ay+direction*5)
        glVertex2f(x+ax+1-direction*6,y+ay+direction*5); glEnd()
    end
    -- Separate lever position from actual engine indications; never label
    -- throttle or N1 as a measured percentage of available thrust/power.
    for i=0,n-1 do
        local typ=hud_types[i]
        local turbine=typ==5 or typ==7 or typ==9 or typ==10
        local limit=hud_redline[i]*60/(2*math.pi)
        local ratio=turbine and hud_n1[i]/100 or (limit>0 and hud_rpm[i]/limit or 0)
        local row=math.floor(i/columns)
        local in_row=math.min(columns,n-row*columns)
        local cx=350+engine_width/2+(i%columns-(in_row-1)/2)*120
        local cy=62+(rows-1-row)*110
        ring(cx,cy,40,7,1,0.015,0.025,0.035)
        ring(cx,cy,39,5,1,0.17,0.24,0.29)
        ring(cx,cy,39,5,clamp(ratio,0,1),0.25,0.86,0.72)
        -- Throttle index straddles the N1 track (r=34..39), not a second ring.
        local angle=math.rad(225-270*clamp(hud_throttle[i],0,1))
        local function marker(radius,inner,half,r,g,b)
            glColor4f(r,g,b,1); glBegin_TRIANGLE_FAN()
            for _,p in ipairs({{radius,angle+half},{radius,angle-half},{inner,angle-half},{inner,angle+half}}) do
                glVertex2f(x+cx+math.cos(p[2])*p[1],y+cy+math.sin(p[2])*p[1])
            end
            glEnd()
        end
        marker(43,30,math.rad(5),0.015,0.025,0.035)
        marker(42,31,math.rad(3),1,0.86,0.28)
        label(cx-27,cy-50,string.format('THR %.0f%%',hud_throttle[i]*100),false)
        label(cx-22,cy+13,'E'..(i+1)..(turbine and ' N1' or ' RPM'),false)
        label(cx-25,cy-11,turbine and string.format('%.1f',hud_n1[i]) or string.format('%.0f',hud_rpm[i]),true)
        -- Compact actual lever readouts beneath each ring, including when
        -- assistance is off. Do not label a helicopter collective as PROP.
        if hud_helicopter[0]==0 and (typ==0 or typ==1 or typ==3 or typ==9 or typ==10) then
            local prop_text=hud_prop_type[i]==0 and 'PROP FIXED'
                or string.format('PROP %.0f%%',clamp(hud_prop[i],0,1)*100)
            if typ==0 or typ==1 then
                label(cx-52,cy-66,prop_text..string.format('  MIX %.0f%%',clamp(hud_mixture[i],0,1)*100),false,true,true)
            else
                label(cx-26,cy-66,prop_text,false,true,true)
            end
        end
    end
    if n==0 then label(20,80,'No engine',false) end
    -- T/O is the aircraft's published generic reference point, not a
    -- fabricated green operating range or an add-on takeoff approval.
    local tx=group_width-290
    local tw=190
    y=y+30+(rows-1)*110
    label(tx,44,'TRIM',false)
    local trim_display=-trim[0]
    label(tx+tw-80,43,string.format('%+.1f%%',trim_display*100),true)
    box(tx,25,tw,4,0.22,0.3,0.35)
    for i=0,10 do box(tx+tw*i/10,21,1,i==5 and 13 or 8,0.5,0.6,0.66) end
    local to_pos=tx+(clamp(-hud_to[0],-1,1)+1)*tw/2
    box(to_pos-1,13,2,22,0.85,0.69,0.3)
    label(clamp(to_pos-25,tx,tx+tw-50),0,'T/O ref',false)
    local current=tx+(clamp(trim_display,-1,1)+1)*tw/2
    box(current-2,17,4,20,0.25,0.95,0.8)
    box(current-5,37,10,3,0.25,0.95,0.8)
    label(tx,0,'ND -100',false); label(tx+tw-48,0,'NU +100',false)
end

create_command('daniel/xbox/enable','Enable Xbox Advanced controls','daniel_xbox_enable()','','')
create_command('daniel/xbox/disable','Disable Xbox Advanced and restore assignments','daniel_xbox_disable()','','')
create_command('daniel/xbox/toggle_help','Toggle Xbox controller legend','daniel_xbox_toggle_help()','','')
create_command('daniel/xbox/toggle_hud','Toggle Xbox flight HUD','daniel_xbox_toggle_hud()','','')
create_command('daniel/xbox/toggle_engine_assist','Toggle Xbox Auto Mix/Prop','daniel_xbox_toggle_engine_assist()','','')
create_command('daniel/xbox/next_view','Xbox next view in current group','daniel_xbox_cycle_view(1)','','')
create_command('daniel/xbox/previous_view','Xbox previous view in current group','daniel_xbox_cycle_view(-1)','','')
add_macro('Xbox Advanced: Controls','daniel_xbox_enable()','daniel_xbox_disable()','activate')
do_every_frame('daniel_xbox_frame()')
do_every_draw('daniel_xbox_help()')
do_every_draw('daniel_xbox_hud()')
do_on_exit('daniel_xbox_disable()')
