extends RigidBody3D


var lifetime = 2.0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	lifetime -= delta
	
	if lifetime < 0.0:
		get_parent().remove_child(self)

	pass
