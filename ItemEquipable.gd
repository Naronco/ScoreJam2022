extends Area3D

func interact(player):
	if Global.equippedPackages < 5:
		Global.equippedPackages += 1
