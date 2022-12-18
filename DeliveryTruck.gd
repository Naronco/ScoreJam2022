extends VehicleBody3D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

@export var gearChangeSpeed: float = 0.5
@export var gearChangeTimeout: float = 0.4
@export var gearTimeoutRemaining: float = 0.0
@export var steeringSpeedPercent: float = 0.95
@export var acceleration: float = 1300.0
@export var reverseAcceleration: float = 1000.0
@export var brakeForce: float = 80.0
@export var idleBreak: float = 5.0
@export var maxSteeringAngleFast: float = 15.0
@export var maxSteeringAngleSlow: float = 43.0

var gear = 0
var targetGear = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func interact(player):
	player.unmount()
	self.engine_force = 0
	setBrake(idleBreak)

func get_mount_off_point(_player):
	return $MountOffPoint.global_position

func process_mounted(delta):
	var maxSteeringAngle = maxSteeringAngleFast \
		+ (maxSteeringAngleSlow - maxSteeringAngleFast) \
		* smoothstep(1.0, 0.0, self.linear_velocity.length() / 25.0);
	var x = (Input.get_action_strength("left") - Input.get_action_strength("right")) * deg_to_rad(maxSteeringAngle)
	var accel = Input.get_action_strength("accelerate")
	var back = Input.get_action_strength("reverse")
	
	gearTimeoutRemaining -= delta
	self.steering = (self.steering - x) * pow(1 - steeringSpeedPercent, delta) + x;

	if gearTimeoutRemaining <= 0:
		if gear == 0:
			if accel > 0.01:
				setEngineForce(acceleration * accel)
			else:
				setEngineForce(0)

			if back > 0.01:
				setBrake(brakeForce * back)
				if abs(accel) < 0.1:
					nextGear(-1)
			else:
				setBrake(0)
		elif gear == -1:
			if back > 0.01:
				setEngineForce(reverseAcceleration * -back)
			else:
				setEngineForce(0)

			if accel > 0.01:
				setBrake(brakeForce * accel)
				if abs(back) < 0.1:
					nextGear(0)
			else:
				setBrake(0)
		else:
			nextGear(0)
	else:
		setBrake(0)
		setEngineForce(0)

func nextGear(newGear):
	if self.linear_velocity.length_squared() < gearChangeSpeed * gearChangeSpeed:
		if targetGear != newGear:
			gearTimeoutRemaining = gearChangeTimeout
			targetGear = newGear
		if gearTimeoutRemaining <= 0:
			gear = newGear
			setBrake(0)
			setEngineForce(0)

func setBrake(v):
	if v != 0:
		v *= max(0.8, self.linear_velocity.length() / 5.0)
	
	$WheelFL.brake = v
	if v != 0:
		$WheelFL.engine_force = 0
	$WheelFR.brake = v
	if v != 0:
		$WheelFR.engine_force = 0

func setEngineForce(v):
	$WheelFL.engine_force = v
	$WheelFR.engine_force = v
	$WheelBL.engine_force = v
	$WheelBR.engine_force = v
