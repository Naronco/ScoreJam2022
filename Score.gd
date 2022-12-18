extends Label

rendered_score = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if rendered_score != Global.score:
		rendered_score = Global.score
		self.text = "Score: " + str(rendered_score)
