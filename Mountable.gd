extends Area3D

@export var mountPoint: NodePath

func interact(player):
	Global.equipPackage()
	Global.equipPackage()
	Global.equipPackage()
	Global.equipPackage()
	Global.equipPackage()
	player.setMount(get_node(mountPoint))
