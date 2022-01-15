extends Node2D

var watching_idx = 0

func _process(_delta):
	var players = get_tree().get_nodes_in_group("players")
	if len(players) > 0:
		if Input.is_action_just_pressed("throw"):
			watching_idx += 1
		watching_idx = watching_idx % len(players)
	for player in players:
		var cam = player.get_node("Camera2D")
		if is_instance_valid(cam):
			if player == players[watching_idx]:
				cam.current = true
				cam.visible = true
			else:
				cam.current = false
				cam.visible = false
