extends Control

const Game = preload("res://GameWorld.tscn")
@onready var ProfileScreen = load("res://Menu/Profile.tscn")
const Highscores = preload("res://Menu/Highscores.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_start_pressed():
	get_tree().change_scene_to_packed(Game)

func _on_profile_pressed():
	get_tree().change_scene_to_packed(ProfileScreen)

func _on_scoreboard_pressed():
	get_tree().change_scene_to_packed(Highscores)
