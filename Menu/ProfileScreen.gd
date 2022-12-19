extends Control

const MainMenu = preload("res://Menu/MainMenu.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _enter_tree():
	$Profile/ErrorLabel.text = ""
	$Profile/LabelName/Name.text = Global.username
	$Profile/BackBtn.visible = Global.username != ""

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_password_text_changed(new_text):
	var auth = new_text != ""
	$Profile/Login.visible = auth
	$Profile/Register.visible = auth
	$Profile/PlayAnon.visible = !auth


func _on_password_text_submitted(password):
	auto_login()

func _on_name_text_submitted(new_text):
	auto_login()

func auto_login():
	if $Profile/LabelPass/Password.text != "":
		_on_login_pressed()
	else:
		_on_play_anon_pressed()

func set_disabled(disabled):
	$Profile/LabelName/Name.editable = !disabled
	$Profile/LabelPass/Password.editable = !disabled
	$Profile/Login.disabled = disabled
	$Profile/Register.disabled = disabled
	$Profile/PlayAnon.disabled = disabled

func _on_play_anon_pressed():
	var username = $Profile/LabelName/Name.text
	if username == "":
		username = "Anonymous"
	await Global.set_user(username, null)
	_on_back_btn_pressed()

func _on_login_pressed():
	var username = $Profile/LabelName/Name.text
	var password = $Profile/LabelPass/Password.text
	$Profile/ErrorLabel.text = ""
	set_disabled(true)
	var res = await Global.set_user(username, password)
	set_disabled(false)
	if res["success"]:
		_on_back_btn_pressed()
	else:
		$Profile/ErrorLabel.text = "Error: " + res["error"]

func _on_register_pressed():
	var username = $Profile/LabelName/Name.text
	var password = $Profile/LabelPass/Password.text
	set_disabled(true)
	var res = await Global.register(username, password)
	set_disabled(false)
	if res["success"]:
		_on_back_btn_pressed()
	else:
		$Profile/ErrorLabel.text = "Couldn't Register: " + res["error"]

func _on_back_btn_pressed():
	get_tree().change_scene_to_packed(MainMenu)
