extends Control

onready var disconnect_button = $MarginContainer/VBoxContainer/Controls/DisconnectButton
onready var ready_button = $MarginContainer/VBoxContainer/Controls/ReadyButton
onready var start_button = $MarginContainer/VBoxContainer/Controls/StartButton
onready var music_button = $MarginContainer/VBoxContainer/Controls/MusicButton
onready var voices_button = $MarginContainer/VBoxContainer/Controls/VoicesButton
onready var sounds_button = $MarginContainer/VBoxContainer/Controls/SoundsButton
onready var player_list = $MarginContainer/VBoxContainer/PlayerList

var peer_id = 0

func _ready():
	peer_id = get_tree().get_network_unique_id()
	
	ready_button.pressed = Global.players_info[peer_id]["status"] != Global.STATUS_UNREADY
	var _err = ready_button.connect("toggled", self, "_on_ready_pressed")
	
	_err = Global.connect("player_list_changed", self, "_update_player_list")
	
	_err = start_button.connect("button_down", self, "_on_start_pressed")
	
	disconnect_button.disabled = Global.game_started
	_err = disconnect_button.connect("pressed", self, "_on_disconnect_pressed")
	
	music_button.pressed = get_audio_bus("Music")
	_err = music_button.connect("toggled", self, "set_audio_bus", ["Music"])
	
	voices_button.pressed = get_audio_bus("Voices")
	_err = voices_button.connect("toggled", self, "set_audio_bus", ["Voices"])
	
	sounds_button.pressed = get_audio_bus("SFX")
	_err = sounds_button.connect("toggled", self, "set_audio_bus", ["SFX"])
	
	start_button.disabled = true
	
	_update_player_list()

func _on_ready_pressed(new_state:bool):
	var status = Global.STATUS_READY if new_state else Global.STATUS_UNREADY
	Global.rpc("set_status", get_tree().network_peer.get_unique_id(), status)
	
func _on_start_pressed():
	Global.setup_game()
	
func _on_disconnect_pressed():
	get_tree().network_peer = null
	get_tree().change_scene("res://scenes/connection.tscn")
	
func set_audio_bus(new_state:bool, name:String):
	var idx = AudioServer.get_bus_index(name)
	AudioServer.set_bus_mute(idx, !new_state)
	
func get_audio_bus(name:String):
	var idx = AudioServer.get_bus_index(name)
	return !AudioServer.is_bus_mute(idx)
	
func _update_player_list():
	player_list.clear()
	var num_ready = 0
	for pid in Global.players_info:
		var player = Global.players_info[pid]
		player_list.add_item("%s (%s) Status: %s, Wins: %s" % [player["name"], pid, player["status"], player["wins"]])
		if player["status"] == Global.STATUS_READY: num_ready += 1
	#Allow game start if this is the host and everyone's ready
	if get_tree().is_network_server():
		start_button.disabled = (num_ready != player_list.get_item_count())

