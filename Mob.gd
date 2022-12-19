extends RigidBody3D

@export var playerPath: NodePath

@onready var player = get_node(playerPath)

var bullet = preload("res://Bullet.tscn")

var followPlayer = false


var shootTimer = 0.0
var shootCooldown = 0.1

# Called when the node enters the scene tree for the first time.
func _ready():
	shootTimer = shootCooldown

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

	var playerDir = Vector3(dx, 0, dz).normalized()
	
	var distSq=dx*dx+dz*dz

	if distSq>10*10:
		# stop following player if too far away or too close by 
		followPlayer = false
	

	if followPlayer and distSq>1:
		linear_velocity = playerDir*2.0
	
	# shoot?
	if followPlayer:
		shootTimer -= delta
		$ShootingBullet.play()
		
		if shootTimer < 0.0:
			var inst = bullet.instantiate()
			get_parent().add_child(inst)

			inst.global_position = global_position + Vector3(0, 1.2, 0) + playerDir*0.8
			inst.linear_velocity = playerDir*25.0

			shootTimer = shootCooldown

	pass
