extends RigidBody3D

@export var playerPath: NodePath

@onready var player = get_node(playerPath)

var followPlayer = false


# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):

	followPlayer = true

	var space_state = get_world_3d().direct_space_state
	# use global coordinates, not local to node

	var params = PhysicsRayQueryParameters3D.new()
	params.from = global_transform.origin + Vector3.UP
	params.to = player.global_transform.origin + Vector3.UP
	params.exclude = [self, player]

	var result = space_state.intersect_ray(params)
	if result:
		# there is something between player and mob, so we assume the mob can't see the player and stops following
		followPlayer = false

	var dx = player.get_effective_position().x - global_position.x
	var dz = player.get_effective_position().z - global_position.z
	
	var distSq=dx*dx+dz*dz

	if distSq<1 or distSq>5*5:
		# stop following player if too far away or too close by 
		followPlayer = false
	

	if followPlayer:
		var direction = Vector3(dx, 0, dz).normalized()*2

		linear_velocity = direction
	
	pass
