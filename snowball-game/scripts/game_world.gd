extends Node2D

const PLAYER_SCN = preload("res://scenes/objects/player.tscn")

onready var gameplay_node = $Gameplay

func _ready():
	var _err = Global.connect("abort_game", self, "_on_abort")
	Global.rpc("set_status", get_tree().get_network_unique_id(), Global.STATUS_PLAYING)

func _on_abort():
	Global.connection_status = "Server bailed on you."
	get_tree().change_scene("res://scenes/connection.tscn")

remotesync func spawn_player(pid:int, pos:Vector2):
	var node = PLAYER_SCN.instance()
	node.set_network_master(pid, true)
	node.peer_id = pid
	gameplay_node.add_child(node)
	node.name = "Player%s" % pid
	node.position = pos
	node.connect("died", Global, "_on_player_death", [pid])
