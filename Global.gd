extends Node

@export var equippedPackages: int = 0
@export var canInteract: bool = 0 : set = setCanInteract
@export var score: int = 0

func _ready():
	pass # Replace with function body.

func equipPackage():
	if equippedPackages < 5:
		equippedPackages += 1
		return true
	return false

func dropPackage():
	if equippedPackages > 0:
		equippedPackages -= 1

func setCanInteract(v):
	canInteract = v

func gotPacket():
	score += 1000

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
