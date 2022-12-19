extends Area3D

var needs = false

@export var highlightMaterial: Material

signal scored

# Called when the node enters the scene tree for the first time.
func _ready():
	self.connect("body_entered", on_body_entered)

func on_body_entered(body: PhysicsBody3D):
	if needs:
		Global.gotPacket()
		needs = false
		unhighlight()
		body.get_parent().remove_child(body)
		emit_signal("scored")

func set_goal():
	needs = true
	highlight()

func highlight():
	if get_child_count() > 1:
		return
	var box = CSGBox3D.new()
	box.rotation = get_child(0).rotation
	var collider: BoxShape3D = get_child(0).shape
	box.size = collider.size + Vector3(0.1, 0.1, 0.1)
	box.material = highlightMaterial
	add_child(box)

func unhighlight():
	if get_child_count() > 1:
		remove_child(get_child(1))

func needs_packet():
	return needs
