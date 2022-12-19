extends Control

const men = preload("res://Menu/MainMenu.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _enter_tree():
	$NinePatchRect/ScoreLabel.text = "Your Score: " + str(Global.score)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_button_pressed():
	get_tree().change_scene_to_packed(men)
