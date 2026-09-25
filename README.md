# 🎮 X-Plane 12: Xbox Controller Advanced (MSFS Layout & Flight HUD)

Custom **FlyWithLua** profile for the **Xbox One / Series Controller (Bluetooth)** on **macOS**, featuring **Microsoft Flight Simulator (MSFS) style controls**, proportional rudder & toe braking, and an integrated, compact **Flight HUD**.

---

## ✈️ Features

- 🎮 **MSFS-Style Control Scheme:** Intuitive flight controls optimized for gamepads.
- 🛞 **Proportional Rudder & Differential Brakes:**
  - `LT` / `RT` control proportional left/right rudder in flight.
  - On the ground, pressing both triggers activates proportional differential toe brakes.
- 📊 **Dynamic Flight HUD:**
  - Displays airspeed (IAS), AOA, stall margin, slip indicator, pitch & heading.
  - Automatically adapts between internal and external chase views.
- ⚙️ **Engine & Propeller Assistance:** Toggleable automated mixture/propeller assistance with full manual override layers (`RB + A/B`).
- 👁️ **Fluid Camera Controls:** Smooth right-stick panning with instant center reset (`Y` or `R3`).
- ⚡ **Performance Optimized:** Clean event polling with negligible CPU overhead.

---

# Xbox Advanced for X-Plane 12

MSFS-style controls and a compact flight HUD for Daniel's Xbox One Bluetooth
controller (045e:02fd) on macOS. This is a custom layout, not a complete copy
of an MSFS profile or its cockpit cursor mode.

## Controls

Hold the modifier before pressing the action button. Single actions fire once
per press; continuous controls stop when their inputs are released.

| Input | Action |
|---|---|
| Left stick | Roll and pitch using the existing calibration |
| Right stick | Look around; vertical direction unchanged |
| Y or R3 | Center the view |
| Hold A / B | Increase / decrease throttle |
| Hold X | Wheel brakes |
| LT / RT | Proportional rudder: LT left, RT right |
| LT + RT | On the ground, proportional left/right wheel brakes as well as rudder |
| LB / RB | On the ground, full left/right wheel brake |
| D-pad up / down | Retract / extend flaps one step |
| D-pad left / right | Zoom out / in |
| LB + A | Extend speedbrakes one step |
| LB + B | Retract speedbrakes one step |
| LB + X | Toggle parking brake |
| LB + Y | Toggle landing gear |
| LB + right stick up / down | Pitch trim |
| LB + D-pad left / right | Rudder trim |
| RB + X | Toggle autopilot servos |
| RB + Y | Toggle Auto Mix / Prop assistance |
| Hold RB + A, then D-pad up / down | Prop fine / coarse (higher / lower selected RPM) |
| Hold RB + B, then D-pad up / down | Richer / leaner mixture |
| RB + right stick up / down | Zoom in / out, including in manual engine layers |
| RB + D-pad up / down, without A/B | Cockpit / chase view |
| RB + D-pad left / right, without A/B | Previous / next view within the current group |
| View (two rectangles) | Toggle cockpit / chase view |
| Menu | Pause |
| LB + Menu | Show / hide controller legend |
| RB + Menu | Show / hide flight HUD |

Speedbrakes are now on LB + A/B. RB + A/B selects the manual prop and mixture
layers. X remains the normal brake button. RB + X toggles the autopilot.

### Brakes

Trigger braking requires BOTH triggers to exceed 12% travel. Each trigger then
sets its own wheel brake independently: 40% LT and 80% RT means 40% left brake
and 80% right brake. One trigger alone only controls rudder. Letting either
trigger return to the deadzone releases both trigger-operated brakes.
LB/RB retain their individual full-brake priority. Trigger and shoulder braking
is disabled while airborne. Parking brake and X remain separate controls.

### Camera and manual engine layers

Inside the cockpit, RB + D-pad left/right cycles saved 3D cockpit Quick Looks
(slots 1–20) from the current aircraft's `_prefs.txt` file. Empty slots and saved
external views are skipped. Newly saved positions become available once
X-Plane writes them to that file. With no saved cockpit positions, the view
stays put. The last chosen cockpit slot is remembered while visiting outside.

Outside, the same inputs cycle chase, circle and runway views without entering
the cockpit. RB + up/down explicitly chooses cockpit/chase.

While RB + A or RB + B is held, D-pad up/down operates the selected engine
control instead of the camera; D-pad left/right has no camera action in these
layers. Up means fine/higher RPM for prop, or richer for mixture. Down means
coarse/lower RPM for prop, or leaner for mixture. Holding both A and B cancels
engine input. RS remains available for zoom. The legend shows the active layer.

Manual engine inputs use X-Plane's standard all-engine commands. At the first
manual input, the assistant releases that control while leaving the other
assisted control active. Standard simulator controls/animations follow the
command; add-ons with their own engine logic can behave differently.

Heading Sync no longer has a controller shortcut. RB + X uses X-Plane's standard
autopilot servo toggle; aircraft with custom autopilot commands may require an
aircraft-specific mapping.

## HUD and legend

The HUD appears near the bottom center, with no shared background panel.
It is hidden in the cockpit and returns in external views if enabled.
It starts off after a script reload. The legend starts on, is independent of
the HUD and shows the applicable LB/RB/manual-engine controls.

- IAS: continuously scrolling speed tape with a fixed center pointer, normally
  ±30 kt or ±60 kt when aircraft Vne exceeds 300 kt. White is the separate flap
  range, green the normal range, yellow the caution range and red starts at Vne.
  Missing limits are not invented. V/S and AoA do not change the speed limits.
  Vx/Vy are not estimated from other aircraft.
- GS: groundspeed in knots below IAS.
- ALT: barometric altitude in feet. A smaller muted AGL line underneath shows
  height above ground; flaps are below that, clear of the V/S arrow.
- V/S: feet per minute, with a green climb arrow, red descent arrow and a neutral
  mark within ±50 ft/min.
- FLAPS: actual and requested position in percent. Green/white shows actual
  movement; the yellow target marker responds immediately to a new request.
- Engine rings: E1–E16, with N1 for turbines or RPM for piston/electric engines.
  The yellow index and THR value show throttle position, not measured power.
  Compact PROP and MIX values below each applicable ring show actual lever
  positions, even when assistance is off. Fixed-pitch props say PROP FIXED;
  turbine engines omit MIX, and helicopter collective is not labelled PROP.
- TRIM: corrected display direction, with a cyan position marker and the
  aircraft's generic gold takeoff reference. No estimated takeoff range.
- AOA: separate vertical tape at the right. If the aircraft does not supply a
  stall-warning angle, its fallback scale is not an aircraft-specific limit.
- Turn/slip: small damped turn indicator and shaded ball above the HUD.
  This uses the instrument signals, not just aircraft bank angle.
- AP: a small green light with AP text appears when X-Plane reports engaged
  autopilot servos. Flight Director alone does not light it.
- AUTO MIX / AUTO PROP: shown only while the relevant assistant is active.
  AUTO THR appears only if the aircraft's own autothrottle is actually working.
  The Xbox engine assistant does not operate the throttle.

Multiple engine rows are used when needed. Text shadows improve contrast.
The controller legend highlights button presses for at least 0.22 seconds,
shows analog stick/trigger movement and updates its instructions with modifiers.

## Engine assistance

RB + Y enables/disables the convenience assistant for compatible engines.

Auto Mix moves the actual mixture levers in running, manually controlled,
naturally aspirated piston engines using a conservative air-density cruise
schedule. This is not EGT-peak, rich-of-peak or lean-of-peak optimization.
On the ground, below 1,000 ft AGL, with flaps requested or at 75% throttle and
above, it enriches toward full rich. This does not replace an aircraft-specific
mixture procedure, particularly for high-elevation airports. Turbocharged
engines are excluded from this mixture approximation.

Auto Prop gently schedules constant-speed prop levers, including supported
turboprops: full forward on the ground, below 1,000 ft AGL, with flaps requested
or at 80% throttle and above; otherwise 85% lever. This is a general convenience
curve, not a guaranteed optimal or handbook cruise RPM.

Fixed-pitch props, helicopters, jets, recognized native engine automation,
the Robin DR401 and Diamond DA50, stopped engines and active plugin overrides
are excluded as appropriate. Unrecognized custom add-on engine logic may not
be compatible. A FADEC switch state by itself is not proof of installed FADEC:
the standard Baron reports it on despite having manual engine controls.

A manual lever change releases that control. Feather/reverse are not cancelled.
Disabling the assistant, disconnecting the controller or reloading scripts leaves
the current lever positions in place for manual handover. The native optimum-
mixture setting is not changed. If assistance for one control is still active,
RB + Y first switches the remaining assistance off; press it again to re-enable
both eligible controls.

## Loading and configuration

Right-stick cockpit look has a 12% deadzone and a quadratic response curve.
Camera speed and cockpit Y inversion are configured in `cfg` at the top of
the main script. External look uses X-Plane's camera commands.

The script activates when the expected controller and native flight axes are
detected. It also accepts axis slots cleared by its own previous session.
Plugins → FlyWithLua → FlyWithLua Macros → Xbox Advanced: Controls toggles
the controller script and restores its original assignments when disabled.
After a disconnect, re-enable the macro or reload the scripts. USB connections
or another controller slot require a mapping change.

The optional Xbox_Performance_Optimizer.lua helper can hide/show the HUD based
on sustained low/high FPS; it is normally paused in this installation. It is
separate from aircraft graphics settings and can be toggled in FlyWithLua Macros.

## Installation, backups and verification

Main script:
`/Users/daniel/Library/Application Support/Steam/steamapps/common/X-Plane 12/Resources/plugins/FlyWithLua/Scripts/Xbox_MSFS_Advanced.lua`

Engine assistant:
`/Users/daniel/Library/Application Support/Steam/steamapps/common/X-Plane 12/Resources/plugins/FlyWithLua/Modules/daniel_engine_assist.lua`

Original joystick settings:
`/Users/daniel/XPlane-Controller/backup-2026-09-12/X-Plane Joystick Settings.prf`

Snapshot before this UI/layout update:
`/Users/daniel/XPlane-Controller/ui-update-2026-09-13-fCUQgi/`

Earlier performance work renamed the incompatible BetterPushback and Xchecklist
Mac binaries out of the load path and lowered several graphics preference
values. Its backups are under `backup-2026-09-12/performance-optimization/`.
Those graphics preferences were edited while X-Plane was running; persistence
depends on whether X-Plane subsequently overwrote them. Removing binaries that
were already unable to load is not a measured FPS improvement.

The earlier experimental controller `.joy` template is in the backup folder to
avoid conflicting device defaults.

To uninstall, disable Xbox Advanced: Controls, quit X-Plane, then move the main
script out of Scripts. Restore the original joystick preference backup only
while X-Plane is closed; this also reverses later joystick setting changes.

Local automated checks:
`/opt/homebrew/bin/luajit /Users/daniel/XPlane-Controller/test_controller.lua`
`/opt/homebrew/bin/luajit /Users/daniel/XPlane-Controller/test_engine_assist.lua`

These cover routing, release, pause, reload, rudder/brakes, views, HUD state and
engine-assistance handover. They do not prove compatibility with every add-on.


---

## 🛠️ Installation

1. Make sure you have **[FlyWithLua Next Generation (XP12)](https://forums.x-plane.org/index.php?/files/file/82888-flywithlua-ng-next-generation-edition-for-x-plane-12-win-lin-mac/)** installed.
2. Copy `Scripts/Xbox_MSFS_Advanced.lua` into:
   ```
   X-Plane 12/Resources/plugins/FlyWithLua/Scripts/
   ```
3. *(Optional)* Copy `Modules/daniel_engine_assist.lua` into:
   ```
   X-Plane 12/Resources/plugins/FlyWithLua/Modules/
   ```
4. Start X-Plane 12, connect your Xbox Controller via Bluetooth, and start flying!

---

## 📝 License & Author
Created by **Daniel Panczyk** ([@d4nnyp73](https://github.com/d4nnyp73)).  
Feel free to contribute or adapt for other controller configurations!
