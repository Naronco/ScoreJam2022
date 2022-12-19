extends Control

const MainMenu = preload("res://Menu/MainMenu.tscn")

func _ready():
	pass

func _process(delta):
	pass

func _on_button_pressed():
	get_tree().change_scene_to_packed(MainMenu)
