extends Control

onready var ready_button = $MarginContainer/VBoxContainer/HSplitContainer/ReadyButton
onready var start_button = $MarginContainer/VBoxContainer/HSplitContainer/StartButton
onready var player_list = $MarginContainer/VBoxContainer/PlayerList

func _ready():
	var _err = ready_button.connect("toggled", self, "_on_ready_pressed")
	_err = Global.connect("player_list_changed", self, "_update_player_list")
	_err = start_button.connect("button_down", Global, "start_game")
	start_button.disabled = true

func _on_ready_pressed(new_state:bool):
	Global.rpc("set_ready", get_tree().network_peer.get_unique_id(), new_state)
	
func _update_player_list():
	player_list.clear()
	var num_ready = 0
	for pid in Global.players_info:
		var player = Global.players_info[pid]
		player_list.add_item("%s (%s) %s" % [player["name"], pid, "Ready!" if player["ready"] else ""])
		if player["ready"]: num_ready += 1
	#Allow game start if this is the host and everyone's ready
	if get_tree().is_network_server():
		start_button.disabled = (num_ready != player_list.get_item_count())

