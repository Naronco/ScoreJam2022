extends Node3D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

@export var initialFollow: NodePath
@export var movementSpeedPercent: float = 0.999
@export var zoomSpeedPercent: float = 0.95
@export var accelerationSlowPercent: float = 0.005
@export var lookaheadScale: float = 0.55
@export var targetZoom: float = 40

@onready var follow = get_node(initialFollow)
@onready var zoom = targetZoom

var camAccel = Vector3(0, 0, 0)
var virtualOrigin = Vector3(0, 0, 0)

# Called when the node enters the scene tree for the first time.
func _ready():
	global_position = follow.global_position
	virtualOrigin = global_position

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	zoom = (zoom - targetZoom) * pow(1 - zoomSpeedPercent, delta) + targetZoom;
	
	$Camera3D.size = zoom
	$Camera3D.position.y = zoom
	RenderingServer.global_shader_parameter_set("camera_distance", zoom)
	
	if follow != null:
		var target = follow.global_position
		camAccel += (target - virtualOrigin) * 10 * delta
		camAccel *= pow(accelerationSlowPercent, delta)
		virtualOrigin += camAccel * delta
		global_position = virtualOrigin + camAccel * lookaheadScale

func set_target(target, zoom):
	follow = target
	targetZoom = zoom

func fade_zoom(zoom):
	targetZoom = zoom
