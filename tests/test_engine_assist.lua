local refs={}
function dataref_table(name)
    refs[name]=refs[name] or setmetatable({}, {__index=function() return 0 end})
    return refs[name]
end
function logMsg() end
local function r(name) return dataref_table(name) end
local root='/Users/daniel/Library/Application Support/Steam/steamapps/common/X-Plane 12/'
local m=dofile(root..'Resources/plugins/FlyWithLua/Modules/daniel_engine_assist.lua')
local count=r('sim/aircraft/engine/acf_num_engines')
local types=r('sim/aircraft/prop/acf_en_type')
local props=r('sim/aircraft/prop/acf_prop_type')
local running=r('sim/flightmodel/engine/ENGN_running')
local mix=r('sim/cockpit2/engine/actuators/mixture_ratio')
local prop=r('sim/cockpit2/engine/actuators/prop_ratio')
local mode=r('sim/cockpit2/engine/actuators/prop_mode')
local throttle=r('sim/cockpit2/engine/actuators/throttle_ratio')
local auto=r('sim/aircraft/overflow/acf_drive_by_wire')
local agl=r('sim/flightmodel/position/y_agl')
local function tick() for j=1,120 do m.step(0.1) end end
count[0]=2; agl[0]=1000
r('sim/weather/sigma')[0]=0.7
for i=0,1 do
    types[i]=1; props[i]=1; running[i]=1; mix[i]=1
    mode[i]=1; prop[i]=1; throttle[i]=0.6
end
m.toggle(); assert(auto[0]==0 and m.status()=='AUTO MIX + PROP')
assert(m.hud_status()=='AUTO MIX  |  AUTO PROP')
tick(); assert(math.abs(prop[0]-0.85)<0.001 and prop[1]==prop[0])
assert(mix[0]<0.95 and mix[0]>0.8 and mix[1]==mix[0],'actual mixture levers must move')
throttle[0]=1; tick(); assert(prop[0]==1 and prop[1]==0.85)
assert(mix[0]==1,'high power enriches actual mixture')
prop[1]=0.65; tick(); assert(prop[1]==0.65,'manual takeover must persist')
mix[0]=0; tick(); assert(auto[0]==0 and mix[0]==0,'cutoff must restore native mixture')
m.stop(); assert(prop[1]==0.65 and auto[0]==0)
assert(m.hud_status()=='','inactive HUD status must be hidden')
print('PASS: twin cruise, high power, manual prop takeover, cutoff, stop')
count[0]=1; mix[0]=1; props[0]=0; prop[0]=0.4
m.toggle(); assert(m.status()=='AUTO MIX'); tick(); assert(prop[0]==0.4)
assert(m.hud_status()=='AUTO MIX','fixed prop must not be advertised as automatic')
m.toggle(); assert(auto[0]==0)
print('PASS: fixed pitch only enables mixture; toggle restores native setting')
AIRCRAFT_PATH='Aircraft/Robin DR401/'
m.toggle(); assert(auto[0]==0 and m.status()=='AUTO: BUILT-IN ENGINE CONTROL')
AIRCRAFT_PATH=''
r('sim/aircraft2/metadata/is_helicopter')[0]=1
m.toggle(); assert(auto[0]==0); tick(); assert(prop[0]==0.4)
r('sim/aircraft2/metadata/is_helicopter')[0]=0
r('sim/cockpit2/engine/actuators/fadec_on')[0]=1
m.toggle(); assert(m.status()=='AUTO MIX','Baron default FADEC switch must not block manual controls')
m.stop()
r('sim/cockpit2/engine/actuators/fadec_on')[0]=0
types[0]=5; m.toggle(); assert(auto[0]==0); tick(); assert(prop[0]==0.4)
print('PASS: Robin/helicopter/jets skipped; Baron FADEC switch permits manual assist')
types[0]=9; props[0]=1; prop[0]=1; throttle[0]=0.6
m.toggle(); assert(m.status()=='AUTO PROP' and auto[0]==0)
r('sim/time/paused')[0]=1; tick(); assert(prop[0]==1)
r('sim/time/paused')[0]=0
r('sim/time/is_in_replay')[0]=1; tick(); assert(prop[0]==1)
r('sim/time/is_in_replay')[0]=0
tick(); assert(prop[0]==0.85)
mode[0]=0; prop[0]=0; tick(); assert(prop[0]==0,'never unfeather')
m.stop()
print('PASS: turboprop prop only, pause, replay, feather exclusion')
types[0]=1; mode[0]=1; auto[0]=1; prop[0]=1
m.toggle(); assert(m.status()=='AUTO: BUILT-IN ENGINE CONTROL'); m.stop(); assert(auto[0]==1)
auto[0]=0; running[0]=0
m.toggle(); assert(auto[0]==0); tick(); assert(prop[0]==1)
running[0]=1
r('sim/operation/override/override_mixture')[0]=1
r('sim/operation/override/override_prop_pitch')[0]=1
m.toggle(); assert(auto[0]==0); tick(); assert(prop[0]==1)
print('PASS: native automix preserved, stopped engine and plugin overrides skipped')
r('sim/operation/override/override_mixture')[0]=0
r('sim/operation/override/override_prop_pitch')[0]=0
props[0]=0; mix[0]=1; throttle[0]=0.6
m.toggle(); tick(); assert(mix[0]<1)
mix[0]=0.75; tick(); assert(mix[0]==0.75,'manual mixture takeover')
m.stop(); assert(mix[0]==0.75,'stop preserves current mixture')
mix[0]=1; r('sim/weather/sigma')[0]=0
m.toggle(); tick(); assert(mix[0]==1,'invalid density stays rich'); m.stop()
r('sim/weather/sigma')[0]=0.7
r('sim/aircraft/engine/acf_critalt')[0]=2000
m.toggle(); tick(); assert(mix[0]==1,'density schedule must not lean turbo engines'); m.stop()
print('PASS: mixture movement, enrichment, manual takeover, invalid density, turbo exclusion')
r('sim/aircraft/engine/acf_critalt')[0]=0
props[0]=1; prop[0]=1; mix[0]=1
m.toggle(); assert(m.hud_status()=='AUTO MIX  |  AUTO PROP')
m.release_mixture(); assert(m.hud_status()=='AUTO PROP')
tick(); assert(mix[0]==1 and prop[0]<1,'manual mixture handover leaves auto prop active')
m.stop(); prop[0]=1
m.toggle(); m.release_prop(); assert(m.hud_status()=='AUTO MIX')
tick(); assert(prop[0]==1 and mix[0]<1,'manual prop handover leaves auto mixture active')
m.stop()
print('PASS: explicit manual handover releases only the chosen control')
