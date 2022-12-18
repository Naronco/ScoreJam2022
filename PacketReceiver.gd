extends Area3D

var needs = false

# Called when the node enters the scene tree for the first time.
func _ready():
	self.connect("body_entered", on_body_entered)

func on_body_entered(body: PhysicsBody3D):
	if needs && (body.collision_mask & 0b1000) != 0:
		body.collision_mask &= ~0b1000
		Global.gotPacket()
		needs = false
		print("unhighlight", self)

func set_goal():
	print("highlight", self)
	needs = true

func needs_packet():
	needs = false
