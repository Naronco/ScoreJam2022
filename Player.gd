extends RigidBody3D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# mount interface:
#   mount.process_mounted(delta)
#   mount.interact(self)
#   mount.get_mount_off_point(self) -> Vector3
var mount = null

@export var cameraPath: NodePath
@export var movementForce: float = 100.0
@export var airMovementForce: float = 30.0
@export var packetMovementPenalty: float = 3.0
@export var jump_force: float = 30.0
@export var feet_height: float = 0

@export var walljump_scan_length: float = 0.8
@export var walljump_up_force: float = 60.0
@export var walljump_force: float = 30.0

@export var zoom_regular: float = 25
@export var zoom_mounted: float = 70

@onready var camera = get_node(cameraPath)

var num_areas = 0
var previous_collision_layer = 0
var previous_collision_mask = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	camera.set_target(self, zoom_regular)
	RenderingServer.global_shader_parameter_set("in_editor", false)
	RenderingServer.global_shader_parameter_set("player_outside", true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if Input.is_action_just_pressed("interact"):
		if mount != null:
			mount.interact(self)
		else:
			interact()

		return

	if mount != null:
		mount.process_mounted(delta)
		RenderingServer.global_shader_parameter_set("player_pos", mount.global_position)
		RenderingServer.global_shader_parameter_set("circle_scale", 2.5)
	else:
		var x = Input.get_action_strength("right") - Input.get_action_strength("left")
		var y = Input.get_action_strength("backward") - Input.get_action_strength("forward")

		var space_state = get_world_3d().direct_space_state
		var pos = global_position
		var query = PhysicsRayQueryParameters3D.create(pos, pos - Vector3(0, feet_height, 0))
		var on_ground = space_state.intersect_ray(query) != {}

		var force = movementForce
		if !on_ground:
			force = airMovementForce
		force -= packetMovementPenalty * Global.equippedPackages
		var direction = Vector3(x, 0, y).normalized() * delta * force
		direction = direction.rotated(Vector3(0, 1, 0), camera.global_rotation.y);
		apply_impulse(direction, Vector3(0, 1, 0))

		RenderingServer.global_shader_parameter_set("player_pos", global_position)
		RenderingServer.global_shader_parameter_set("circle_scale", 1.0)

		if Input.is_action_just_pressed("jump"):
			if on_ground:
				apply_impulse(Vector3(0, jump_force, 0), Vector3(0, 1, 0))

func interact():
	var interacts = $InteractArea.get_overlapping_areas()
	var pos = global_position

	var minDist = INF
	var minArea = null
	for area in interacts:
		var dist = area.global_position.distance_squared_to(pos)
		if dist < minDist:
			minDist = dist
			minArea = area

	if minArea != null:
		interactWith(minArea)

func interactWith(area):
	area.interact(self)

func setMount(node):
	mount = node
	camera.set_target(node, zoom_mounted)
	previous_collision_mask = collision_mask
	previous_collision_layer = collision_layer
	collision_mask = 0
	collision_layer = 0
	axis_lock_linear_x = true
	axis_lock_linear_y = true
	axis_lock_linear_z = true
	visible = false

func unmount():
	visible = true
	global_position = mount.get_mount_off_point(self)
	linear_velocity = mount.linear_velocity
	mount = null
	camera.set_target(self, zoom_regular)
	collision_mask = previous_collision_mask
	collision_layer = previous_collision_layer
	axis_lock_linear_x = false
	axis_lock_linear_y = false
	axis_lock_linear_z = false

func _on_InteractArea_area_entered(area):
	num_areas += 1
	Global.canInteract = true

func _on_InteractArea_area_exited(area):
	num_areas -= 1
	if num_areas == 0:
		Global.canInteract = false


func _on_InsideAreas_enter(body):
	RenderingServer.global_shader_parameter_set("player_outside", false)

func _on_InsideAreas_leave(body):
	RenderingServer.global_shader_parameter_set("player_outside", true)

func get_effective_position():
	if mount == null:
		return global_position
	else:
		return mount.global_position
