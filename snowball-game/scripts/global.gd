extends Node

const MAX_PLAYERS = 8
const SERVER_PID = 1

signal connected()
signal connection_failure()
signal player_list_changed()
signal abort_game(message)

var server_ip = "127.0.0.1"
var port = 25565
var peer:NetworkedMultiplayerPeer = null

var player_name:String

var players_info = {}
var game_started = false
var players_spawned = false
var num_dead = 0
var num_playing = 0

func _enter_tree():
	randomize()
	var _err = get_tree().connect("network_peer_disconnected", self, "_on_peer_disconnect")
	#_err = get_tree().connect("network_peer_connected", self, "_on_peer_connected")
	_err = get_tree().connect("connected_to_server", self, "_on_connection_success")
	_err = get_tree().connect("connection_failed", self, "_on_connection_failure")
	_err = get_tree().connect("server_disconnected", self, "_on_server_disconnected")

func _on_peer_disconnect(id:int):
	unregister_player(id)

remote func reject_player():
	players_info.clear()
	emit_signal("abort_game", "Game is already in progress.")
	
const STATUS_READY = "Ready"
const STATUS_UNREADY = "Not Ready"
const STATUS_PLAYING = "Playing"
const STATUS_DEAD = "Dead"
	
remotesync func set_status(id, new_status:String):
	players_info[id]["status"] = new_status
	emit_signal("player_list_changed")
	
remote func host_register_player(info):
	var id = get_tree().get_rpc_sender_id()
	if game_started:
		peer.disconnect_peer(id)
		rpc_id(id, "reject_player")
	else:
		print("Player registered: " + String(id))
		#Tell the new player about our existing players
		for pid in players_info:
			rpc_id(id, "peer_register_player", pid, players_info[pid])
		players_info[id] = info
		#Tell everyone (including the new player) about the new player
		rpc("peer_register_player", id, info)
		emit_signal("player_list_changed")
	
remote func peer_register_player(id:int, info:Dictionary):
	players_info[id] = info
	if id == peer.get_unique_id():
		emit_signal("connected")
	emit_signal("player_list_changed")
	
func unregister_player(id):
	players_info.erase(id)
	emit_signal("player_list_changed")

func _on_connection_success():
	rpc_id(SERVER_PID, "host_register_player", new_player_info(player_name))
	
func _on_connection_failure():
	players_info.clear()
	get_tree().network_peer = null
	emit_signal("connection_failure")

func _on_server_disconnected():
	players_info.clear()
	emit_signal("abort_game", "Server disconnected.")

func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		get_tree().network_peer = null
		peer = null
		get_tree().quit()
		
func _on_player_death(pid):
	num_dead += 1
	players_info[pid]["status"] = STATUS_DEAD
	if num_dead >= len(players_info) - 1:
		pass

func _process(_delta):
	if get_tree().is_network_server():
		var n_playing = 0
		for pid in players_info:
			if players_info[pid]["status"] == STATUS_PLAYING:
				n_playing += 1
		if !players_spawned and n_playing == len(players_info):
			spawn_players()
			players_spawned = true

#Construct the game world and place spawn points before telling everyone to switch to it
func setup_game():
	assert(get_tree().is_network_server())
	players_spawned = false
	rpc("start_game")
	
func spawn_players():
	var world = get_tree().root.get_node("World")
	for pid in players_info:
		world.rpc("spawn_player", pid, Vector2(rand_range(4.0, 500.0), rand_range(4.0, 500.0)))
	
remotesync func start_game():
	get_tree().change_scene("res://scenes/game.tscn")
	num_dead = 0
	game_started = true

func new_player_info(name:String)->Dictionary:
	return {
		"name": name,
		"status": STATUS_UNREADY,
		"wins": 0
	}

func host_game(name, p_port:int):
	game_started = false
	players_info.clear()
	player_name = name
	peer = NetworkedMultiplayerENet.new()
	port = p_port
	var err = peer.create_server(port, MAX_PLAYERS)
	if err == OK:
		get_tree().network_peer = peer
		players_info[SERVER_PID] = new_player_info(name)
		emit_signal("connected")
		emit_signal("player_list_changed")

func join_game(name, p_ip:String, p_port:int):	
	players_info.clear()
	player_name = name
	peer = NetworkedMultiplayerENet.new()
	port = p_port
	server_ip = p_ip
	var err = peer.create_client(p_ip, p_port)
	if err == OK:
		get_tree().network_peer = peer
	else:
		emit_signal("connection_failure")
