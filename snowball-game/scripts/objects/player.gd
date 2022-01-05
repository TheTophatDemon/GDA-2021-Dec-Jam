extends KinematicBody2D

onready var sprite = $Sprite
onready var label = $Label

var peer_id = 0

func _ready():
	get_tree().connect("network_peer_disconnected", self, "_on_peer_disconnect")

func set_player_name(new_name:String):
	label.text = new_name

func _on_peer_disconnect(id):
	if id == peer_id:
		#If the peer for this player disconnected, remove the node
		queue_free()
