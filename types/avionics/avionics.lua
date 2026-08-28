---@meta
-- LuaCATS definitions for Create: Avionics peripherals.
-- Editor/LSP use only — never deploy this to a computer.
-- Drop in types/avionics/ and reference via workspace.library in .luarc.json.
--
-- Generated against the Avionics docs (last updated 2026-07-25):
--   https://solastrius.github.io/CreateAvionics/
-- Covered: altitude_sensor, gas_provider, gimbal_sensor, velocity_sensor,
--          navigation_table, throttle_lever
-- Not yet covered (add as needed, same pattern): propeller, propeller_bearing,
--   gyroscopic_propeller_bearing, portable_engine, steering_wheel,
--   analog_transmission, rope_winch, laser_pointer/sensor, physics_assembler,
--   linked_typewriter, mounted_potato_cannon, torsion_spring, wheel_mount,
--   directional_gearshift, swivel_bearing, Create_* passthroughs.
--
-- Usage at a call site:
--   ---@type altitude_sensor|nil
--   local alt = peripheral.find("altitude_sensor")

---A three-element numeric list {x, y, z}.
---@alias avionics.vec3 number[]

---A two-element numeric list.
---@alias avionics.vec2 number[]

--------------------------------------------------------------------------------
-- altitude_sensor
--------------------------------------------------------------------------------

---Reports world altitude, local air pressure, and vertical speed.
---Altitude is the world-frame Y of the block (projected out of any sub-level),
---so a sensor on a flying contraption reads the same as a stationary block at
---the same global position.
---@class altitude_sensor
local altitude_sensor = {}

---Current world altitude.
---@return number y World-frame Y coordinate in blocks (= meters).
function altitude_sensor.getHeight() end

---Local air pressure as a fraction of sea-level pressure.
---1.0 = sea level, 0.0 = vacuum at top of build height. Overworld default
---curve: exp(-0.004 * (y - seaLevel)) above sea level (1/e drop per ~250
---blocks), clamped to 1.5 below sea level. Per-dimension override possible
---via Sable physics config.
---@return number pressure Atmosphere fraction.
function altitude_sensor.getAirPressure() end

---Vertical speed, finite-differenced from getHeight at server tick rate
---(dHeight * 20). One tick of lag. Server-side only — returns 0 client-side
---or before the second tick after placement.
---@return number vspeed m/s, positive = ascending.
function altitude_sensor.getVerticalSpeed() end

--------------------------------------------------------------------------------
-- gas_provider (burners, vents — anything that fills balloons)
--------------------------------------------------------------------------------

---Shared peripheral for gas-output blocks (burners, vents) that fill balloons.
---The shared type lets scripts target every heater regardless of block kind.
---@class gas_provider
local gas_provider = {}

---Current gas output rate.
---Output = target * signal/15 (burner) or target * efficiency * signal/15
---(vent). Added to the attached balloon's target volume every game tick.
---@return number rate m^3 per tick (multiply by 20 for m^3/s).
function gas_provider.getGasOutput() end

---Whether the provider can currently output gas.
---@return boolean active
function gas_provider.isActive() end

---Redstone signal strength driving output.
---@return number signal 0..15.
function gas_provider.getSignalStrength() end

---Id of the gas produced. Stock types return stable lowercase ids
---("steam", "default"); third-party gases fall through to class simple name.
---@return string gasType
function gas_provider.getGasType() end

---Configured target gas amount (the scroll-value on the block).
---@return number target
function gas_provider.getTargetAmount() end

---Set the target gas amount. Clamped internally to the scroll-value's
---min/max. YIELDS until the next server tick.
---@param amount number New target amount.
function gas_provider.setTargetAmount(amount) end

---Boiler efficiency in [0, 1]. Burners are always 1.0; vents track boiler heat.
---@return number efficiency
function gas_provider.getBoilerEfficiency() end

---Whether a balloon is currently attached.
---@return boolean present
function gas_provider.hasBalloon() end

---Attached balloon's capacity, or 0 if none.
---@return number capacity
function gas_provider.getBalloonCapacity() end

---Balloon's currently filled volume, or 0 if no server-side balloon.
---@return number volume
function gas_provider.getBalloonFilledVolume() end

---Balloon's target volume, or 0 if no server-side balloon.
---@return number volume
function gas_provider.getBalloonTargetVolume() end

---Per-tick signed volume change of the balloon, or 0 if no server-side balloon.
---@return number delta
function gas_provider.getBalloonVolumeChange() end

---Balloon's lift force, or 0 if no server-side balloon.
---@return number lift
function gas_provider.getBalloonLift() end

---Balloon's height, or 0 if no balloon.
---@return number height
function gas_provider.getBalloonHeight() end

---Balloon's gas mix as a list of {type=..., amount=...} entries.
---@return {type: string, amount: number}[] mix
function gas_provider.getBalloonGasMix() end

--------------------------------------------------------------------------------
-- gimbal_sensor (IMU)
--------------------------------------------------------------------------------

---Inertial measurement in the body frame (the host contraption's frame, not
---the block's). At identity orientation body axes equal world axes
---(+X east, +Y up, +Z south). Mounting orientation of the block itself does
---not affect readings.
---@class gimbal_sensor
local gimbal_sensor = {}

---Pitch and roll in degrees, derived from where world-down points in the
---body frame. Yaw is not measurable from gravity — use
---navigation_table.getHeading() for yaw.
---@return avionics.vec2 angles {pitch, roll} in degrees.
function gimbal_sensor.getAngles() end

---Pitch and roll in radians. Same conventions as getAngles.
---@return avionics.vec2 angles {pitch, roll} in radians.
function gimbal_sensor.getAnglesRad() end

---Angular velocity in body frame: {wx=pitch rate, wy=yaw rate, wz=roll rate}.
---From Sable's rigid-body engine.
---@return avionics.vec3 rates {wx, wy, wz} in degrees/sec.
function gimbal_sensor.getAngularRates() end

---Angular velocity in body frame, radians/sec. Same conventions as
---getAngularRates.
---@return avionics.vec3 rates {wx, wy, wz} in radians/sec.
function gimbal_sensor.getAngularRatesRad() end

---Local gravity vector expressed in body frame. Sable stock default is
---(0, -11.0, 0) m/s^2 in every dimension unless overridden by dimension
---physics config. Useful for attitude estimation:
---atan2(g.x, -g.y) ~ roll, atan2(g.z, -g.y) ~ pitch.
---@return avionics.vec3 g {gx, gy, gz} in m/s^2.
function gimbal_sensor.getGravity() end

---Proper acceleration in body frame — what an onboard accelerometer reads.
---(dv * 20) - gravity_body, one tick of lag. Stationary reads -getGravity();
---free fall reads zero; add getGravity() to recover inertial acceleration.
---@return avionics.vec3 a {ax, ay, az} in m/s^2.
function gimbal_sensor.getLinearAcceleration() end

--------------------------------------------------------------------------------
-- velocity_sensor
--------------------------------------------------------------------------------

---Directional velocity sensor: reports the host contraption's linear velocity
---component along the body-frame axis the block was mounted on (fixed at
---place-time). Three orthogonally-mounted sensors reconstruct body-frame
---velocity {vx, vy, vz}.
---@class velocity_sensor
local velocity_sensor = {}

---Velocity component along the mounted axis. Positive = moving along the
---axis-positive direction. Deadband: returns 0 below 0.05 m/s magnitude,
---and 0 when the host is not on a sub-level (stationary ground).
---@return number v Signed velocity in m/s.
function velocity_sensor.getVelocity() end

---The body-frame axis this sensor measures along ("x", "y", or "z"),
---fixed at place-time. Lets a script tell orthogonal sensors apart.
---@return "x"|"y"|"z" axis
function velocity_sensor.getAxis() end

--------------------------------------------------------------------------------
-- navigation_table
--------------------------------------------------------------------------------

---Reports the resolved nav target's bearing/distance/closure and the host
---sub-level's orientation and heading.
---@class navigation_table
local navigation_table = {}

---Whether the table has resolved a live target. Note: getTargetType /
---getTargetMetadata describe the held item and can be populated even when
---no target is locked, so false here does not imply getTargetType() == nil.
---@return boolean hasTarget
function navigation_table.hasTarget() end

---Registry id of the held nav-table item type (e.g. "simulated:compass",
---"simulated:map"), or nil if no item is held.
---@return string|nil targetType
function navigation_table.getTargetType() end

---Item-specific metadata for the held nav item. Schema depends entirely on
---the item type — branch on getTargetType() before reading keys. Returns {}
---(empty map, never nil) when no item held or no metadata.
---Built-ins: "simulated:compass" -> {kind: "lodestone"|"spawn", sublevel_id?},
---"simulated:recovery_compass" -> {placer_uuid?},
---"simulated:map" -> {map_id?}, "simulated:magnet" -> {}.
---@return table<string, any> metadata
function navigation_table.getTargetMetadata() end

---Raw relative angle to the target, degrees. (Prefer getBearing for control.)
---@return number angle
function navigation_table.getRelativeAngle() end

---Raw relative angle to the target, radians.
---@return number angle
function navigation_table.getRelativeAngleRad() end

---Forward-error bearing: 0 = target dead ahead of the block's arrow,
---+90 = right, -90 = left, +-180 = behind. Wrapped to [-180, 180].
---@return number bearing Degrees.
function navigation_table.getBearing() end

---Forward-error bearing in radians.
---@return number bearing
function navigation_table.getBearingRad() end

---Distance to the resolved target, world frame.
---@return number distance Blocks (= meters).
function navigation_table.getDistanceToTarget() end

---Closure rate toward the target. Distance is sampled every 11 ticks
---(0.55 s), so short-window jitter is dominated by sampling granularity.
---@return number rate Blocks/sec, positive = approaching.
function navigation_table.getClosureRate() end

---Signed altitude difference target.y - self.y, world frame, regardless of
---contraption orientation.
---@return number dy Blocks.
function navigation_table.getVerticalOffsetToTarget() end

---Host sub-level orientation as a quaternion in {x, y, z, w} order (JOML
---constructor order; matches CC quaternion libs like Advanced-Math).
---@return number[] q Four-element list {x, y, z, w}.
function navigation_table.getOrientation() end

---Host sub-level heading in degrees. 0 = facing world +Z (south), matching
---player-yaw convention. This is your yaw source (gimbal_sensor can't
---measure yaw from gravity).
---@return number heading
function navigation_table.getHeading() end

---Host sub-level heading in radians.
---@return number heading
function navigation_table.getHeadingRad() end

--------------------------------------------------------------------------------
-- throttle_lever
--------------------------------------------------------------------------------

---A 16-position physical lever. State is the analog redstone signal it emits
---(before block-state inversion); writing updates the lever and plays the
---click sound. A player can still move it afterwards — no external-control
---lock.
---@class throttle_lever
local throttle_lever = {}

---Current lever state.
---@return number state 0..15.
function throttle_lever.getState() end

---Drive the lever to a new state, clamped to 0..15.
---YIELDS until the next server tick.
---@param signal number Target state.
function throttle_lever.setSignal(signal) end
