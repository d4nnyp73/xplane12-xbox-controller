local root='/Users/daniel/Library/Application Support/Steam/steamapps/common/X-Plane 12/'
SYSTEM_DIRECTORY=root
SCREEN_WIDTH=1440; SCREEN_HIGHT=900
local values,buttons,active,events={},{},{},{}
local assignments={}
function dataref_table(name)
    if not values[name] then values[name]=setmetatable({}, {__index=function() return 0 end}) end
    return values[name]
end
create_dataref_table=dataref_table
function button(i) return buttons[i]==true end
function set_button_assignment(i,cmd) assignments[i]=cmd end
function command_begin(cmd) assert(not active[cmd],cmd); active[cmd]=true end
function command_end(cmd) assert(active[cmd],cmd); active[cmd]=nil end
function command_once(cmd) events[#events+1]=cmd end
function logMsg(s) print(s) end
function get(name)
    if name=='sim/aircraft/view/acf_relative_path' then
        return '/Users/daniel/XPlane-Controller/fixtures/views.acf'
    end
end
function add_macro() end
function create_command() end
function do_every_frame() end
function do_every_draw() end
function do_on_exit() end
local axes=dataref_table('sim/joystick/joystick_axis_values')
for i=0,3 do axes[i]=0.5 end
local a=dataref_table('sim/joystick/joystick_axis_assignments')
a[0],a[1],a[2],a[3],a[4],a[5]=2,1,41,42,74,75
dataref_table('sim/operation/misc/frame_rate_period')[0]=1/60
dofile(root..'Resources/plugins/FlyWithLua/Scripts/Xbox_MSFS_Advanced.lua')
daniel_xbox_enable()
assert(a[2]==0 and a[3]==0 and a[4]==0 and a[5]==0)
local h=dataref_table('sim/graphics/view/pilots_head_psi')
-- Simulate a fresh script load after X-Plane saved its cleared axis slots.
daniel_xbox_disable()
for i=2,5 do a[i]=0 end
dofile(root..'Resources/plugins/FlyWithLua/Scripts/Xbox_MSFS_Advanced.lua')
daniel_xbox_enable()
assert(dataref_table('daniel/xbox/active')[0]==1,'restart with saved cleared axes')
daniel_xbox_disable()
assert(a[2]==41 and a[3]==42 and a[4]==74 and a[5]==75,'restore correct native axes after restart')
a[4]=3
daniel_xbox_enable()
assert(dataref_table('daniel/xbox/active')[0]==0,'reject conflicting trigger assignment')
a[4]=74
daniel_xbox_enable()
print('PASS: restart with cleared axes, native restoration, conflicting assignment rejection')
axes[2]=1; daniel_xbox_frame(); assert(h[0]>0)
axes[2]=0.51; local last=h[0]; daniel_xbox_frame(); assert(h[0]==last,'view must stay put')
buttons[14]=true; buttons[8]=true; daniel_xbox_frame()
assert(events[#events]=='sim/flight_controls/speed_brakes_down_one','LB+A extends speedbrakes')
local speedbrake_press_count=#events
daniel_xbox_frame(); assert(#events==speedbrake_press_count,'holding LB+A must not repeatedly extend speedbrakes')
buttons[14]=false; daniel_xbox_frame()
assert(not active['sim/engines/throttle_up'],'modifier release must not become throttle')
buttons[8]=false; daniel_xbox_frame()
buttons[8]=true; daniel_xbox_frame(); assert(active['sim/engines/throttle_up'])
buttons[8]=false; daniel_xbox_frame(); assert(not next(active))
buttons[11]=true; daniel_xbox_frame(); assert(active['sim/flight_controls/brakes_regular'])
dataref_table('sim/time/paused')[0]=1; daniel_xbox_frame(); assert(not next(active))
dataref_table('sim/time/paused')[0]=0; buttons[11]=false
buttons[14]=true; axes[3]=0; daniel_xbox_frame()
assert(active['sim/flight_controls/pitch_trim_down'])
axes[3]=1; daniel_xbox_frame()
assert(active['sim/flight_controls/pitch_trim_up'])
assert(not active['sim/flight_controls/pitch_trim_down'])
assert(dataref_table('sim/graphics/view/pilots_head_the')[0]==0,'trim must not move camera')
buttons[14]=false; axes[3]=0.5; daniel_xbox_frame(); assert(not next(active))
buttons[0]=true; daniel_xbox_frame()
assert(events[#events]=='sim/flight_controls/flaps_up','D-pad up retracts flaps')
local flap_press_count=#events
daniel_xbox_frame(); assert(#events==flap_press_count,'holding D-pad must not repeat flaps')
assert(not active['sim/flight_controls/pitch_trim_down'],'D-pad no longer trims')
buttons[0]=false; buttons[4]=true; daniel_xbox_frame()
assert(events[#events]=='sim/flight_controls/flaps_down','D-pad down extends flaps')
buttons[4]=false; buttons[14]=true; buttons[9]=true; daniel_xbox_frame()
assert(events[#events]=='sim/flight_controls/speed_brakes_up_one','LB+B retracts speedbrakes')
buttons[9]=false; buttons[14]=false
assert(not active['sim/flight_controls/pitch_trim_up'],'D-pad down no longer trims')
axes[0]=-1; daniel_xbox_frame(); assert(not next(active))
assert(a[2]==41 and a[3]==42,'restore axes on disconnect')
assert(assignments[8]=='sim/engines/throttle_up','restore buttons')
assert(dataref_table('daniel/xbox/active')[0]==0)
print('PASS: camera/deadzone, combination latching, hold/release, pause, trim, disconnect, restore')
axes[0]=0.5; buttons={}; daniel_xbox_enable()
buttons[0]=true; daniel_xbox_frame(); buttons[0]=false; daniel_xbox_frame()
buttons[18]=true; daniel_xbox_frame()
assert(events[#events]=='sim/view/chase')
assert(not next(active),'view cycle must not zoom')
local count=#events; daniel_xbox_frame(); assert(#events==count,'one view per press')
buttons[18]=false; daniel_xbox_frame(); dataref_table('sim/graphics/view/view_is_external')[0]=1
buttons[18]=true; daniel_xbox_frame()
assert(events[#events]=='sim/view/3d_cockpit_cmnd_look')
buttons[18]=false; daniel_xbox_frame(); dataref_table('sim/graphics/view/view_is_external')[0]=0
buttons[18]=true; daniel_xbox_frame()
assert(events[#events]=='sim/view/chase' and not next(active))
buttons={}; daniel_xbox_frame()
dataref_table('sim/graphics/view/view_is_external')[0]=0
local draws=0
function glColor4f() end
function XPLMSetGraphicsState() end
function glBegin_TRIANGLE_FAN() end
function glEnd() end
function glVertex2f(x,y) assert(x>=18 and x<=558 and y>=18 and y<=270) end
function glRectf(x,y,x2,y2) assert(x>=18 and y>=18 and x2<=558 and y2<=270) end
function draw_string_Helvetica_12(x,y,s) assert(type(s)=='string'); draws=draws+1 end
buttons={}; daniel_xbox_help()
buttons[14]=true; daniel_xbox_help()
buttons[14]=false; buttons[15]=true; daniel_xbox_help()
assert(draws>40)
daniel_xbox_toggle_help(); local before=draws; daniel_xbox_help(); assert(draws==before)
daniel_xbox_disable()
print('PASS: direct View key toggle, no zoom/trim collision, overlay modes, panel bounds, visibility toggle')
buttons={}; daniel_xbox_enable(); dataref_table('sim/graphics/view/view_is_external')[0]=0
buttons[15]=true; buttons[2]=true; daniel_xbox_frame()
assert(events[#events]=='sim/view/quick_look_0','RB+D-pad right selects cockpit quick look')
local one_press=#events; daniel_xbox_frame(); assert(#events==one_press,'held D-pad must not repeat')
daniel_xbox_cycle_view(1); assert(events[#events]=='sim/view/quick_look_5','skip empty and external quick looks')
daniel_xbox_cycle_view(1); assert(events[#events]=='sim/view/quick_look_12')
daniel_xbox_cycle_view(1); assert(events[#events]=='sim/view/quick_look_0','cockpit wrap')
daniel_xbox_cycle_view(-1); assert(events[#events]=='sim/view/quick_look_12','cockpit reverse wrap')
assert(not active['sim/general/zoom_in'] and not active['sim/flight_controls/flaps_down'])
buttons[2]=false; buttons[0]=true; daniel_xbox_frame()
assert(events[#events]=='sim/view/3d_cockpit_cmnd_look','RB+D-pad up cockpit')
buttons[0]=false; dataref_table('sim/graphics/view/view_is_external')[0]=1
daniel_xbox_cycle_view(1); assert(events[#events]=='sim/view/circle')
daniel_xbox_cycle_view(1); assert(events[#events]=='sim/view/runway')
daniel_xbox_cycle_view(1); assert(events[#events]=='sim/view/chase','exterior cycle never enters cockpit')
dataref_table('sim/graphics/view/view_is_external')[0]=0
daniel_xbox_cycle_view(-1); assert(events[#events]=='sim/view/quick_look_5','cockpit selection survives exterior switch')
dataref_table('sim/graphics/view/view_is_external')[0]=1
axes[3]=1; daniel_xbox_frame(); assert(active['sim/general/zoom_out'],'RB+RS zoom')
buttons={}; axes[3]=0.5; daniel_xbox_frame(); daniel_xbox_disable()
print('PASS: RB D-pad view cycling and RB right-stick zoom separation')
daniel_xbox_enable()
dataref_table('sim/flightmodel/failures/onground_any')[0]=1
axes[4],axes[5]=0.8,0.4; buttons[14],buttons[15]=true,true; daniel_xbox_frame()
assert(dataref_table('sim/cockpit2/controls/left_brake_ratio')[0]==1)
assert(dataref_table('sim/cockpit2/controls/right_brake_ratio')[0]==1)
assert(dataref_table('sim/joystick/yoke_heading_ratio')[0]==-0.4)
buttons[15]=false; daniel_xbox_frame()
assert(dataref_table('sim/cockpit2/controls/left_brake_ratio')[0]==1)
assert(dataref_table('sim/joystick/yoke_heading_ratio')[0]==-0.4)
dataref_table('sim/flightmodel/failures/onground_any')[0]=0; axes[4],axes[5]=1,1; daniel_xbox_frame()
assert(dataref_table('sim/cockpit2/controls/left_brake_ratio')[0]==0)
daniel_xbox_disable()
assert(dataref_table('sim/operation/override/override_toe_brakes')[0]==0)
print('PASS: dual-trigger proportional ground braking')
buttons={}; daniel_xbox_enable()
dataref_table('sim/flightmodel/failures/onground_any')[0]=1
local left_wheel=dataref_table('sim/cockpit2/controls/left_brake_ratio')
local right_wheel=dataref_table('sim/cockpit2/controls/right_brake_ratio')
for _,case in ipairs({{1,0,0,0},{0,1,0,0},{0.5,0.5,0.5,0.5},
    {0.4,0.8,0.4,0.8},{0.8,0.4,0.8,0.4},{1,1,1,1},
    {0.04,1,0,0},{0.1,1,0,0},{1,0.1,0,0},{0.12,1,0,0},
    {1,0.12,0,0},{0,0.8,0,0}}) do
    axes[4],axes[5]=case[1],case[2]; daniel_xbox_frame()
    assert(left_wheel[0]==case[3] and right_wheel[0]==case[4],'independent gated trigger brakes')
    assert(math.abs(dataref_table('sim/joystick/yoke_heading_ratio')[0]-(case[2]-case[1]))<1e-6)
end
axes[4],axes[5]=0.4,0.8; buttons[14]=true; daniel_xbox_frame()
assert(left_wheel[0]==1 and right_wheel[0]==0.8,'LB overrides only its wheel')
dataref_table('sim/flightmodel/failures/onground_any')[0]=0
daniel_xbox_frame(); assert(left_wheel[0]==0 and right_wheel[0]==0,'no braking airborne')
daniel_xbox_disable(); buttons={}
print('PASS: single/dual trigger gating, proportional differential brakes, rudder, LB priority, airborne release')
buttons={}; daniel_xbox_enable(); daniel_xbox_frame()
dataref_table('sim/graphics/view/view_is_external')[0]=0
buttons[18]=true; daniel_xbox_frame(); assert(events[#events]=='sim/view/chase','View key to exterior')
buttons[18]=false; daniel_xbox_frame(); dataref_table('sim/graphics/view/view_is_external')[0]=1
buttons[18]=true; daniel_xbox_frame(); assert(events[#events]=='sim/view/3d_cockpit_cmnd_look','View key to cockpit')
buttons[18]=false; daniel_xbox_frame()
SCREEN_WIDTH=1440; SCREEN_HIGHT=900
local hud_text={}
function glRectf() end
function glVertex2f(x,y) assert(x==x and y==y,'finite HUD geometry') end
function draw_string_Helvetica_12(x,y,s) hud_text[#hud_text+1]=s end
draw_string_Helvetica_18=draw_string_Helvetica_12
draw_string_Helvetica_10=draw_string_Helvetica_12
dataref_table('sim/aircraft/engine/acf_num_engines')[0]=2
dataref_table('sim/aircraft/prop/acf_en_type')[0]=7
dataref_table('sim/aircraft/prop/acf_en_type')[1]=7
buttons[15]=true; buttons[19]=true; local count=#events; daniel_xbox_frame()
assert(#events==count,'HUD combo must not pause')
daniel_xbox_hud(); assert(table.concat(hud_text,' '):find('N1'),'jet indication')
buttons[19]=false; daniel_xbox_frame(); buttons[19]=true; daniel_xbox_frame()
local count=#hud_text; daniel_xbox_hud(); assert(#hud_text==count,'HUD toggle off')
daniel_xbox_toggle_hud(); dataref_table('sim/aircraft/prop/acf_en_type')[0]=0
daniel_xbox_hud(); assert(table.concat(hud_text,' '):find('RPM'),'piston indication')
daniel_xbox_disable()
print('PASS: HUD toggle, no pause collision, jet/piston indications')
buttons={}; daniel_xbox_enable()
dataref_table('sim/aircraft/engine/acf_num_engines')[0]=3
hud_text={}; daniel_xbox_hud()
assert(table.concat(hud_text,' '):find('E3'),'third engine must be rendered')
for _,count in ipairs({0,1,4,16}) do
    dataref_table('sim/aircraft/engine/acf_num_engines')[0]=count
    daniel_xbox_hud()
end
daniel_xbox_disable()
print('PASS: dynamic engine counts 0/1/3/4/16 and throttle marker geometry')
daniel_xbox_enable()
dataref_table('sim/flightmodel/position/groundspeed')[0]=100
dataref_table('sim/flightmodel/controls/flaprat')[0]=0.5
local colors={}
function glColor4f(r,g,b,a) colors[r..','..g..','..b]=true end
hud_text={}
dataref_table('sim/cockpit2/gauges/indicators/vvi_fpm_pilot')[0]=500
daniel_xbox_hud()
assert(colors['0.25,0.95,0.45'],'climb arrow green')
assert(table.concat(hud_text,' '):find('GS 194 kt'),'m/s to knots')
assert(table.concat(hud_text,' '):find('FLAPS 50%%'),'actual flap position')
colors={}; dataref_table('sim/cockpit2/gauges/indicators/vvi_fpm_pilot')[0]=-500
daniel_xbox_hud(); assert(colors['1,0.25,0.25'],'descent arrow red')
daniel_xbox_disable()
print('PASS: GS conversion, actual flaps, climb/descent colors')
dataref_table('sim/flightmodel/controls/flaprat')[0]=0.1
dataref_table('sim/flightmodel/controls/flaprqst')[0]=0.75
hud_text={}; daniel_xbox_enable(); daniel_xbox_hud()
assert(table.concat(hud_text,' '):find('FLAPS 10%%  > 75%%'),'actual and target flaps visible')
daniel_xbox_disable()
print('PASS: actual/requested flap indication')
dataref_table('sim/aircraft/view/acf_Vso')[0]=80
dataref_table('sim/aircraft/view/acf_Vs')[0]=95
dataref_table('sim/aircraft/view/acf_Vfe')[0]=120
dataref_table('sim/aircraft/view/acf_Vno')[0]=180
dataref_table('sim/aircraft/view/acf_Vne')[0]=220
dataref_table('sim/cockpit2/gauges/indicators/airspeed_kts_pilot')[0]=150
daniel_xbox_enable(); daniel_xbox_hud(); daniel_xbox_disable()
print('PASS: IAS Vso/Vs/Vno/Vne speed envelope')
dataref_table('sim/cockpit2/gauges/indicators/airspeed_kts_pilot')[0]=150
daniel_xbox_enable(); daniel_xbox_hud(); daniel_xbox_disable()
print('PASS: vertical IAS tape left of data')
-- All instrument triangles use the same winding as X-Plane's visible rings.
local vertices,faces={},0
function glBegin_TRIANGLE_FAN() vertices={} end
function glVertex2f(x,y) vertices[#vertices+1]={x,y} end
function glEnd()
    if #vertices>=3 then
        local a,b,c=vertices[1],vertices[2],vertices[3]
        local cross=(b[1]-a[1])*(c[2]-a[2])-(b[2]-a[2])*(c[1]-a[1])
        assert(cross<=0.00001,'HUD face must be clockwise: arrow/marker would be culled')
        faces=faces+1
    end
end
daniel_xbox_enable()
dataref_table('sim/aircraft/engine/acf_num_engines')[0]=2
for _,vs in ipairs({-500,500}) do
    dataref_table('sim/cockpit2/gauges/indicators/vvi_fpm_pilot')[0]=vs
    for _,gas in ipairs({0,0.5,1}) do
        dataref_table('sim/cockpit2/engine/actuators/throttle_ratio')[0]=gas
        daniel_xbox_hud()
    end
end
assert(faces>0); daniel_xbox_disable()
print('PASS: arrow and gas-marker winding at idle/half/full throttle')
-- Compare actual IAS tape geometry while climb rate and AoA change.
daniel_xbox_enable()
local tape_rects={}
local origin=(SCREEN_WIDTH-(680+240))/2
function glRectf(x1,y1,x2,y2)
    if x1<origin and x2<=origin+3 then
        tape_rects[#tape_rects+1]=string.format('%.4f,%.4f,%.4f,%.4f',x1,y1,x2,y2)
    end
end
local function tape_snapshot()
    tape_rects={}; daniel_xbox_hud()
    assert(#tape_rects>0,'IAS tape must be rendered')
    return table.concat(tape_rects,';')
end
local reference=tape_snapshot()
dataref_table('sim/cockpit2/gauges/indicators/vvi_fpm_pilot')[0]=-1700
dataref_table('sim/flightmodel/position/alpha')[0]=14
assert(tape_snapshot()==reference,'V/S and AoA must not alter IAS tape')
dataref_table('sim/cockpit2/gauges/indicators/airspeed_kts_pilot')[0]=151
assert(tape_snapshot()~=reference,'IAS must move tape continuously')
daniel_xbox_disable()
print('PASS: IAS tape independent of V/S and AoA; responds to IAS')
buttons={}; axes[0]=0.5; axes[2]=0.5
dataref_table('sim/aircraft/engine/acf_num_engines')[0]=1
dataref_table('sim/aircraft/prop/acf_en_type')[0]=1
dataref_table('sim/flightmodel/engine/ENGN_running')[0]=1
dataref_table('sim/cockpit2/engine/actuators/mixture_ratio')[0]=1
local native_mix=dataref_table('sim/aircraft/overflow/acf_drive_by_wire')
native_mix[0]=0
dataref_table('sim/weather/sigma')[0]=0.7
dataref_table('sim/flightmodel/position/y_agl')[0]=1000
dataref_table('sim/flightmodel/failures/onground_any')[0]=0
dataref_table('sim/flightmodel/controls/flaprqst')[0]=0
dataref_table('sim/cockpit2/engine/actuators/throttle_ratio')[0]=0.6
daniel_xbox_enable()
buttons[15]=true; buttons[12]=true
local before_events=#events
daniel_xbox_frame()
assert(native_mix[0]==0 and #events==before_events,'RB+Y must not force native automix or center view')
for i=1,120 do daniel_xbox_frame() end
local lever=dataref_table('sim/cockpit2/engine/actuators/mixture_ratio')
assert(lever[0]<1,'held combination must keep lever automation active')
buttons[12]=false; daniel_xbox_frame()
buttons[12]=true; daniel_xbox_frame()
local stopped_mix=lever[0]
for i=1,120 do daniel_xbox_frame() end
assert(lever[0]==stopped_mix,'second press disables lever automation')
buttons[12]=false; daniel_xbox_frame()
buttons[12]=true; daniel_xbox_frame()
daniel_xbox_disable(); assert(native_mix[0]==0,'native automix must remain untouched')
print('PASS: RB+Y routing, press latching, second press, disconnect restoration')

-- Manual engine layers must not invoke views, flaps or the old speedbrakes.
buttons={}; axes[3]=0.5; daniel_xbox_enable()
buttons[15]=true; buttons[8]=true; buttons[0]=true
local manual_events=#events
daniel_xbox_frame()
assert(active['sim/engines/prop_up'] and #events==manual_events)
assert(not active['sim/general/zoom_in'] and not active['sim/engines/throttle_up'])
buttons[0]=false; buttons[4]=true; daniel_xbox_frame()
assert(active['sim/engines/prop_down'] and not active['sim/engines/prop_up'])
buttons[4]=false; daniel_xbox_frame(); assert(not next(active))
buttons[8]=false; buttons[9]=true; buttons[0]=true; daniel_xbox_frame()
assert(active['sim/engines/mixture_up'] and #events==manual_events)
buttons[0]=false; buttons[4]=true; daniel_xbox_frame()
assert(active['sim/engines/mixture_down'] and not active['sim/engines/mixture_up'])
axes[3]=1; daniel_xbox_frame()
assert(active['sim/general/zoom_out'] and active['sim/engines/mixture_down'],'RS zoom independent of manual mixture')
axes[3]=0.5; buttons[8]=true; daniel_xbox_frame(); assert(not next(active),'A+B cancels engine input')
buttons[8]=false; daniel_xbox_frame()
dataref_table('sim/time/paused')[0]=1; daniel_xbox_frame(); assert(not next(active),'pause releases mixture')
dataref_table('sim/time/paused')[0]=0
buttons[15]=false; daniel_xbox_frame()
assert(not active['sim/engines/throttle_down'],'releasing RB must not make held B a throttle command')
assert(not active['sim/engines/mixture_down'])
buttons={}; daniel_xbox_frame()
buttons[15]=true; buttons[11]=true; daniel_xbox_frame()
assert(events[#events]=='sim/autopilot/servos_toggle','RB+X is AP toggle')
local toggle_events=#events; daniel_xbox_frame(); assert(#events==toggle_events)
buttons={}; daniel_xbox_frame()
buttons[11]=true; daniel_xbox_frame()
assert(active['sim/flight_controls/brakes_regular'],'unmodified X remains brakes')
buttons={}; daniel_xbox_frame(); daniel_xbox_disable()
print('PASS: manual prop/mixture, layer isolation, cancellation, release, pause, AP toggle, X brakes')

-- Readouts show actual per-engine controls, regardless of assist state.
daniel_xbox_enable(); dataref_table('sim/graphics/view/view_is_external')[0]=1
dataref_table('sim/aircraft/engine/acf_num_engines')[0]=2
local engine_types=dataref_table('sim/aircraft/prop/acf_en_type')
local prop_types=dataref_table('sim/aircraft/prop/acf_prop_type')
local prop_positions=dataref_table('sim/cockpit2/engine/actuators/prop_ratio')
local mix_positions=dataref_table('sim/cockpit2/engine/actuators/mixture_ratio')
engine_types[0],engine_types[1]=1,1; prop_types[0],prop_types[1]=1,1
prop_positions[0],prop_positions[1]=0.73,0.84
mix_positions[0],mix_positions[1]=0.91,0.62
hud_text={}; daniel_xbox_hud()
local text_set={}; for _,s in ipairs(hud_text) do text_set[s]=true end
assert(text_set['PROP 73%  MIX 91%'] and text_set['PROP 84%  MIX 62%'])
assert(text_set['ALT  ft BARO'] and not text_set['HOEHE  ft BARO'])
local servos=dataref_table('sim/cockpit2/autopilot/servos_on')
dataref_table('sim/cockpit2/autopilot/flight_director_mode')[0]=1
servos[0]=0; hud_text={}; daniel_xbox_hud()
for _,s in ipairs(hud_text) do assert(s~='AP','flight director alone must not display AP') end
servos[0]=1; hud_text={}; daniel_xbox_hud()
local has_ap=false; for _,s in ipairs(hud_text) do if s=='AP' then has_ap=true end end
assert(has_ap,'active servos display AP')
servos[0]=0; hud_text={}; daniel_xbox_hud()
for _,s in ipairs(hud_text) do assert(s~='AP','AP indicator disappears on disengagement') end
prop_types[0]=0; engine_types[1]=7; hud_text={}; daniel_xbox_hud()
local joined=table.concat(hud_text,';')
assert(joined:find('PROP FIXED',1,true) and not joined:find('MIX 62%',1,true),'fixed prop/jet labels are honest')
dataref_table('sim/aircraft2/metadata/is_helicopter')[0]=1
hud_text={}; daniel_xbox_hud()
assert(not table.concat(hud_text,';'):find('PROP ',1,true),'collective must not be labelled PROP')
dataref_table('sim/aircraft2/metadata/is_helicopter')[0]=0
daniel_xbox_disable()
print('PASS: independent PROP/MIX readouts, AP actual state, English labels, fixed prop/jet/helicopter handling')
