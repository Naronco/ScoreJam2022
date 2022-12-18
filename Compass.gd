extends Node3D

var goal = null

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if goal != null:
		var thisPos = global_position
		var goalPos = goal.global_position
		global_rotation.y = -atan2(thisPos.z - goalPos.z, thisPos.x - goalPos.x) + PI

func set_goal(node):
	visible = true
	goal = node

func clear_goal():
	visible = false
	goal = null
