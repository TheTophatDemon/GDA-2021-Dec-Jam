extends Node2D

var timer = 0.0
var spectating = false

func _ready():
	$Sprite.rotation_degrees = rand_range(0.0, 360.0)
	$Blood.emitting = true

func _process(delta):
	if is_network_master():
		timer += delta
		if timer > 2.0 and not spectating:
			spectating = true
			if Global.num_dead < len(Global.players_info):
				var cam = get_node_or_null("Camera2D")
				if is_instance_valid(cam): cam.queue_free()
				#Switch on a different player's camera to spectate
				var spectator = preload("res://scenes/objects/spectator.tscn").instance()
				spectator.set_network_master(get_network_master())
				get_parent().add_child(spectator)
	else:
		var cam = get_node_or_null("Camera2D")
		if is_instance_valid(cam): cam.queue_free()
