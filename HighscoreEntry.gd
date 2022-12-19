extends Control

var state = 0

var overriden_by_local = false

var _username: String = ""
@export var username: String:
	get:
		return _username
	set(value):
		if _username != value:
			if $Name != null:
				$Name.text = value
			_username = value

var _score: int = 0
@export var score: int:
	get:
		return _score
	set(value):
		if _score != value:
			if $Score != null:
				$Score.text = str(value)
			_score = value

var _closed: bool = false
@export var closed: bool:
	get:
		return _closed
	set(value):
		_closed = value
		update_color()

var _local: bool = false
@export var local: bool:
	get:
		return _local
	set(value):
		_local = value
		update_color()

var target_y: float = 0
@export var moveSpeedPercent: float = 0.99

func _ready():
	$Name.text = _username
	$Score.text = str(_score)
	closed = _closed
	position.y = target_y

func _process(delta):
	position.y = (position.y - target_y) * pow(1 - moveSpeedPercent, delta) + target_y;

func update_color():
	var c = Color(1, 1, 1)
	if local:
		c = Color(1, 1, 0);

	if !closed:
		c.a = 0.7
	$Name.add_theme_color_override("font_color", c)
	$Score.add_theme_color_override("font_color", c)
