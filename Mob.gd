extends RigidBody3D

@export var playerPath: NodePath

@onready var player = get_node(playerPath)

var elapsedTime = 0.0
var rng = RandomNumberGenerator.new()
var nextActionTime = 0.0
var followPlayer = false


# Called when the node enters the scene tree for the first time.
func _ready():
	rng.randomize()
	nextActionTime = rng.randf_range(1.0, 5.0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var dx = player.get_effective_position().x - global_position.x
	var dz = player.get_effective_position().z - global_position.z
	
	var distSq=dx*dx+dz*dz

	if distSq<5*5:
		# always follow player if he is nearby
		do_something(0)
	

	if followPlayer:
		var direction = Vector3(dx, 0, dz).normalized()*2

		linear_velocity = direction

	elapsedTime += delta
	if elapsedTime >= nextActionTime:
		# do something
		var opt = rng.randi() % 3
		do_something(opt)
	


	#global_position.x += dx * delta
	#global_position.z += dz * delta
	
	pass

func do_something(opt):
	followPlayer = false

	if opt == 0:
		# follow player
		followPlayer = true
	else:
		# do nothing
		pass

	nextActionTime = rng.randf_range(1.0, 5.0)
	elapsedTime = 0.0
