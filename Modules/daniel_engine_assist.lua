-- Optional standard-X-Plane engine assistance, explicitly enabled by RB+Y.
-- Mixture uses a conservative density-based cruise lever schedule for
-- naturally aspirated pistons; this is not an EGT-peak / POH lean procedure.
-- Prop automation is a convenience lever schedule, not a POH RPM schedule.
local M = {}
local function ref(name) return dataref_table(name) end
local count=ref('sim/aircraft/engine/acf_num_engines')
local types=ref('sim/aircraft/prop/acf_en_type')
local props=ref('sim/aircraft/prop/acf_prop_type')
local heli=ref('sim/aircraft2/metadata/is_helicopter')
local auto_mix=ref('sim/aircraft/overflow/acf_drive_by_wire')
local sigma=ref('sim/weather/sigma')
local critical_altitude=ref('sim/aircraft/engine/acf_critalt')
local mix_override=ref('sim/operation/override/override_mixture')
local prop_override=ref('sim/operation/override/override_prop_pitch')
local running=ref('sim/flightmodel/engine/ENGN_running')
local mixture=ref('sim/cockpit2/engine/actuators/mixture_ratio')
local prop=ref('sim/cockpit2/engine/actuators/prop_ratio')
local mode=ref('sim/cockpit2/engine/actuators/prop_mode')
local throttle=ref('sim/cockpit2/engine/actuators/throttle_ratio')
local agl=ref('sim/flightmodel/position/y_agl')
local ground=ref('sim/flightmodel/failures/onground_any')
local flaps=ref('sim/flightmodel/controls/flaprqst')
local paused=ref('sim/time/paused')
local replay=ref('sim/time/is_in_replay')
local active=false
local controlled_mix,last_mix={},{}
local controlled,last_prop={},{}
local accumulator=0
local message='ENGINE ASSIST OFF'
local function piston(t) return t==0 or t==1 end
local function prop_engine(t) return piston(t) or t==9 or t==10 end
local function engine_count() return math.max(0,math.min(16,math.floor(count[0]))) end
local function built_in()
    -- This add-on manages both controls directly every physics frame.
    local path=(AIRCRAFT_PATH or '')..(AIRCRAFT_FILENAME or '')..(PLANE_FILENAME or '')
    path=path:lower()
    return path:find('dr401',1,true)~=nil or path:find('da50',1,true)~=nil
end
local function manual_engine(i)
    -- fadec_on is a switch state, NOT proof of installed engine automation:
    -- the stock Baron reports 1 with completely manual mixture/prop controls.
    return running[i]==1 and mixture[i]>0.05
end
local function can_mix(i)
    return mix_override[0]==0 and auto_mix[0]==0 and critical_altitude[0]<=0
        and piston(types[i]) and manual_engine(i)
end
local function update_message()
    local has_prop=next(controlled)~=nil
    local has_mix=next(controlled_mix)~=nil
    message=has_mix and (has_prop and 'AUTO MIX + PROP' or 'AUTO MIX')
        or (has_prop and 'AUTO PROP' or 'ENGINE ASSIST OFF')
    if not has_mix and not has_prop then active=false end
end
function M.stop()
    -- Retain both current lever positions for a smooth manual handover.
    controlled_mix={}; last_mix={}
    active=false; controlled={}; last_prop={}; accumulator=0
    message='ENGINE ASSIST OFF'
end
function M.status() return message end
function M.release_mixture()
    controlled_mix={}; last_mix={}
    update_message()
end
function M.release_prop()
    controlled={}; last_prop={}
    update_message()
end
function M.hud_status()
    local parts={}
    if active and next(controlled_mix) then parts[#parts+1]='AUTO MIX' end
    if active and next(controlled) then parts[#parts+1]='AUTO PROP' end
    return table.concat(parts,'  |  ')
end
function M.toggle()
    if paused[0]~=0 or replay[0]~=0 then return end
    if active then M.stop(); return end
    M.stop()
    if heli[0]~=0 then message='AUTO: HELICOPTER NOT SUPPORTED'; return end
    if built_in() or auto_mix[0]~=0 then
        message='AUTO: BUILT-IN ENGINE CONTROL'; return
    end
    for i=0,engine_count()-1 do
        if can_mix(i) then controlled_mix[i]=true; last_mix[i]=mixture[i] end
    end
    if prop_override[0]==0 then
        for i=0,engine_count()-1 do
            if prop_engine(types[i]) and props[i]==1 and manual_engine(i) and mode[i]==1 then
                controlled[i]=true; last_prop[i]=prop[i]
            end
        end
    end
    active=next(controlled_mix)~=nil or next(controlled)~=nil
    update_message()
    if not active then
        message=auto_mix[0]~=0 and 'AUTO: BUILT-IN ENGINE CONTROL' or 'AUTO: NO ELIGIBLE ENGINE'
    end
    logMsg('[Xbox Engine Assist] '..message)
end
function M.step(dt)
    if not active or paused[0]~=0 or replay[0]~=0 then return end
    if heli[0]~=0 or built_in() then M.stop(); return end
    accumulator=accumulator+math.max(0,math.min(dt,0.1))
    if accumulator<0.2 then return end
    local elapsed=accumulator; accumulator=0
    for i in pairs(controlled_mix) do
        if i>=engine_count() or not can_mix(i) or math.abs(mixture[i]-last_mix[i])>0.025 then
            controlled_mix[i]=nil; last_mix[i]=nil
        else
            local high=ground[0]==1 or agl[0]<305 or flaps[0]>0.05 or throttle[i]>=0.75
            local density=sigma[0]
            -- Missing/invalid atmosphere input must not command a guessed lean.
            local valid=density==density and density>=0.2 and density<=1.5
            local target=1
            if valid and not high then
                target=math.max(0.65,math.min(1,math.sqrt(density)+0.05))
            end
            local max_step=elapsed*(target>mixture[i] and 0.3 or 0.015)
            mixture[i]=mixture[i]+math.max(-max_step,math.min(max_step,target-mixture[i]))
            last_mix[i]=mixture[i]
        end
    end
    for i in pairs(controlled) do
        -- A manual lever change, feather/reverse, cutoff or another plugin's
        -- override immediately returns this engine's prop to manual control.
        if i>=engine_count() or not prop_engine(types[i]) or props[i]~=1
            or not manual_engine(i) or mode[i]~=1 or prop_override[0]~=0
            or math.abs(prop[i]-last_prop[i])>0.025 then
            controlled[i]=nil; last_prop[i]=nil
        else
            local high=ground[0]==1 or agl[0]<305 or flaps[0]>0.05 or throttle[i]>=0.8
            local target=high and 1 or 0.85
            local max_step=elapsed*(high and 0.6 or 0.08)
            prop[i]=prop[i]+math.max(-max_step,math.min(max_step,target-prop[i]))
            last_prop[i]=prop[i]
        end
    end
    update_message()
end
return M
