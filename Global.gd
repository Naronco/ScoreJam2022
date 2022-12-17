extends Node

@export var equippedPackages: int = 0 : set = setEquippedPackages
@export var canInteract: bool = 0 : set = setCanInteract

func _ready():
	pass # Replace with function body.

func setEquippedPackages(v):
	equippedPackages = v

func setCanInteract(v):
	canInteract = v

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
