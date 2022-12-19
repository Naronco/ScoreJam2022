extends Area3D

var needs = false

# Called when the node enters the scene tree for the first time.
func _ready():
	self.connect("body_entered", on_body_entered)

func on_body_entered(body: PhysicsBody3D):
	if needs:
		Global.gotPacket()
		needs = false
		body.get_parent().remove_child(body)

func set_goal():
	needs = true

func needs_packet():
	return needs
