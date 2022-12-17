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
@export var packetMovementPenalty: float = 3.0
@export var jump_force: float = 30.0
@export var feet_height: float = 0

@export var zoom_regular: float = 25
@export var zoom_mounted: float = 70

@onready var camera = get_node(cameraPath)

var num_areas = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	camera.set_target(self, zoom_regular)

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
		var y = Input.get_action_strength("forward") - Input.get_action_strength("backward")
		var force = movementForce
		force -= packetMovementPenalty * Global.equippedPackages
		var direction = Vector3(x, 0, -y).normalized() * delta * force
		direction = direction.rotated(Vector3(0, 1, 0), camera.global_rotation.y);
		apply_impulse(direction, Vector3(0, 1, 0))

		RenderingServer.global_shader_parameter_set("player_pos", global_position)
		RenderingServer.global_shader_parameter_set("circle_scale", 1.0)

	if Input.is_action_just_pressed("jump"):
		if mount == null:
			var space_state = get_world_3d().direct_space_state
			var pos = global_position
			var query = PhysicsRayQueryParameters3D.create(pos, pos - Vector3(0, feet_height, 0))
			var result = space_state.intersect_ray(query)
			print(result)
			if result:
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
	visible = false

func unmount():
	visible = true
	global_position = mount.get_mount_off_point(self)
	linear_velocity = mount.linear_velocity
	mount = null
	camera.set_target(self, zoom_regular)


func _on_InteractArea_area_entered(area):
	num_areas += 1
	Global.canInteract = true

func _on_InteractArea_area_exited(area):
	num_areas -= 1
	if num_areas == 0:
		Global.canInteract = false
