extends Label

const Gameover = preload("res://Menu/gameover.tscn")

var timeRemaining = 3*60.0


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	timeRemaining -= delta
	if timeRemaining < 0.0:
		get_tree().change_scene_to_packed(Gameover)
		timeRemaining = 0.0
	
	var sec = int(timeRemaining)
	var min = floor(sec / 60)
	sec %= 60
	
	text = ("0" + str(min) if min<10 else str(min)) + ":" + ("0" + str(sec) if sec<10 else str(sec)) + " min"
	
	pass
