extends Area3D

@export var mountPoint: NodePath

func interact(player):
	player.setMount(get_node(mountPoint))
