extends Camera2D

var target:Node2D = null

func _process(_delta):
	if is_instance_valid(target):
		global_position = target.global_position
	else:
		target = get_parent().get_node("Player%s" % get_tree().network_peer.get_unique_id())
