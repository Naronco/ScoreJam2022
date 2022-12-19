extends Control

const MainMenu = preload("res://Menu/MainMenu.tscn")

func _ready():
	pass

func _process(delta):
	pass

func _onSubmit():
	var name = $BgName/NameBox.text
	if name == "":
		name = "Anonymous"
	await Global.set_user(name, null)
	get_tree().change_scene_to_packed(MainMenu)


func _on_name_box_text_submitted(new_text):
	_onSubmit()
