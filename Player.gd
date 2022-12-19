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
@export var boxReceiverContainer: NodePath
@export var boxGenerator: MeshLibrary
@export var movementForce: float = 100.0
@export var airMovementForce: float = 30.0
@export var packetMovementPenalty: float = 3.0
@export var jump_force: float = 30.0
@export var feet_height: float = 0

@export var walljump_scan_length: float = 0.8
@export var walljump_up_force: float = 60.0
@export var walljump_force: float = 30.0

@export var zoom_regular: float = 30
@export var zoom_max_aim: float = 90
@export var zoom_mounted: float = 70

@export var baseThrowVector: Vector3 = Vector3(2.0, 4.0, 0.0)

@onready var camera = get_node(cameraPath)

var num_areas = 0
var previous_collision_layer = 0
var previous_collision_mask = 0

var visible_boxes = 0

var current_goal = null

var aim_drag_position = Vector2(0, 0)

# Called when the node enters the scene tree for the first time.
func _ready():
	camera.set_target(self, zoom_regular)
	RenderingServer.global_shader_parameter_set("in_editor", false)
	RenderingServer.global_shader_parameter_set("player_outside", true)
	
	for receiver in get_node(boxReceiverContainer).get_children():
		receiver.connect("scored", goal_scored)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if Input.is_action_just_pressed("interact"):
		if mount != null:
			mount.interact(self)
		else:
			interact()

		return

	if mount != null:
		global_position = mount.global_position
		mount.process_mounted(delta)
		RenderingServer.global_shader_parameter_set("player_pos", mount.global_position)
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

func _process(delta):
	if visible_boxes != Global.equippedPackages:
		while visible_boxes > Global.equippedPackages:
			get_holding_box(visible_boxes - 1).visible = false
			visible_boxes -= 1

		while visible_boxes < Global.equippedPackages:
			get_holding_box(visible_boxes).visible = true
			get_holding_box(visible_boxes).rotation.y = randf() * deg_to_rad(360)
			visible_boxes += 1

		highlight_goal()

func aim(rot, strength):
	strength = min(strength, 6.0)
	if visible_boxes > 0:
		$Trajectory.visible = true
		$Trajectory.global_rotation.y = rot + PI * 0.5
		var trs = strength * strength / 1.4
		$Trajectory.scale = Vector3(trs, trs, trs)
		$StrengthCompass.global_rotation.y = rot
		$StrengthCompass.visible = true
		$StrengthCompass/Indicator.scale = Vector3(strength, strength, 1.0)
		RenderingServer.global_shader_parameter_set("circle_scale", 1.0)
		#camera.fade_zoom(zoom_regular + (zoom_max_aim - zoom_regular) * pow(strength / 6.0, 0.5))

func unaim():
	$StrengthCompass.visible = false
	$Trajectory.visible = false
	#camera.fade_zoom(zoom_regular)
	if mount != null:
		RenderingServer.global_shader_parameter_set("circle_scale", 2.5)
	else:
		RenderingServer.global_shader_parameter_set("circle_scale", 1.0)
	
	if visible_boxes > 0:
		var strength = $StrengthCompass/Indicator.scale.x
		var rot = $StrengthCompass.global_rotation.y
		if strength > 0.01:
			var box = RigidBody3D.new()
			var colliderBox = CollisionShape3D.new()
			var meshRenderer = MeshInstance3D.new()
			
			var boxes = boxGenerator.get_item_list()
			var boxIndex = boxes[randi_range(0, boxes.size() - 1)]
			var boxMesh = boxGenerator.get_item_mesh(boxIndex);
			meshRenderer.mesh = boxMesh;
			var boxColliders = boxGenerator.get_item_shapes(boxIndex);
			colliderBox.shape = boxColliders[0];
			colliderBox.transform = boxColliders[1]
			
			box.add_child(colliderBox)
			box.add_child(meshRenderer)
			
			box.collision_layer = 0b11000;
			box.collision_mask = 0b11000;
			box.mass = 1;
			
			box.global_position = $CarriedBoxes.global_position
			box.linear_velocity = (baseThrowVector * strength).rotated(Vector3(0, 1, 0), rot + PI)
			box.contact_monitor = true
			box.connect("body_entered", stop_throw_sound)

			get_parent().add_child(box)

			if mount == null:
				Global.dropPackage()
			
			await get_tree().create_timer(1.0 / strength).timeout
			
			box.collision_layer = 0b11001;
			box.collision_mask = 0b11001;
						
			var bodiesInRange = $PickupArea.get_overlapping_bodies()
			for body in bodiesInRange:
				_on_PickupArea_body_entered(body)

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
				aim_drag_position = Vector2(0, 0)
			else:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				unaim()

	elif event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			aim_drag_position += event.relative * Vector2(1.0, 2.0)
			aim(-atan2(aim_drag_position.y, aim_drag_position.x) + deg_to_rad(30.0), max(0, aim_drag_position.length() * 0.01 - 1.0))

func get_holding_box(i):
	return $CarriedBoxes.get_child(i)

func highlight_goal():
	if visible_boxes == 0:
		$PacketCompass.clear_goal()
		return
	
	var boxes = get_node(boxReceiverContainer)
	if current_goal != null && current_goal.needs_packet():
		$PacketCompass.set_goal(current_goal)
		return

	current_goal = boxes.get_child(randi_range(0, boxes.get_child_count() - 1))
	current_goal.set_goal()
	$PacketCompass.set_goal(current_goal)

func goal_scored():
	highlight_goal()
	$PackageIn.play()
	$ThrowSound.stop()

func stop_throw_sound():
	$ThrowSound.stop()

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
	RenderingServer.global_shader_parameter_set("circle_scale", 2.5)
	mount = node
	camera.set_target(node, zoom_mounted)
	previous_collision_mask = collision_mask
	previous_collision_layer = collision_layer
	collision_mask = 0
	collision_layer = 0
	axis_lock_linear_x = true
	axis_lock_linear_y = true
	axis_lock_linear_z = true
	$Visible.visible = false
	$PacketCompass.scale = Vector3(3, 3, 3)
	$PacketCompass/CSGBox3D.position = Vector3(5.0, 0.058, 0.0)
	$StrengthCompass.scale = Vector3(8, 8, 8)
	Global.canInteract = false

func unmount():
	$Visible.visible = true
	global_position = mount.get_mount_off_point(self)
	linear_velocity = mount.linear_velocity
	mount = null
	camera.set_target(self, zoom_regular)
	collision_mask = previous_collision_mask
	collision_layer = previous_collision_layer
	axis_lock_linear_x = false
	axis_lock_linear_y = false
	axis_lock_linear_z = false
	$PacketCompass.scale = Vector3(1, 1, 1)
	$PacketCompass/CSGBox3D.position = Vector3(1.0, 0.058, 0.0)
	$StrengthCompass.scale = Vector3(1, 1, 1)

func _on_InteractArea_area_entered(area):
	num_areas += 1
	Global.canInteract = mount == null

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


func _on_PickupArea_body_entered(body):
	if (body.collision_layer & 0b1) != 0:
		if Global.equipPackage():
			body.get_parent().remove_child(body)
