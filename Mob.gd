extends RigidBody3D

@export var playerPath: NodePath

@onready var player = get_node(playerPath)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var dx = player.global_position.x - global_position.x
	var dz = player.global_position.z - global_position.z
	
	var distSq=dx*dx+dz*dz

	if distSq>1:
		var direction = Vector3(dx, 0, dz).normalized()*2

		linear_velocity = direction

	#global_position.x += dx * delta
	#global_position.z += dz * delta
	
	pass
