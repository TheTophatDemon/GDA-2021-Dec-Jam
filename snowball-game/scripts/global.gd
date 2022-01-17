extends Node

const MAX_PLAYERS = 8
const SERVER_PID = 1

signal connected()
signal connection_failure()
signal player_list_changed()
signal abort_game()
signal game_over()

var server_ip = "127.0.0.1"
var port = 25565
var peer:NetworkedMultiplayerPeer = null

var player_name = ""
var connection_status = ""

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
	connection_status = "Game is already in progress."
	emit_signal("abort_game")
	
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
		rpc_id(id, "reject_player")
		peer.disconnect_peer(id)
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
		connection_status = ""
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
	connection_status = "Connection failed."
	emit_signal("connection_failure")

func _on_server_disconnected():
	players_info.clear()
	get_tree().network_peer = null
	emit_signal("abort_game")

func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		get_tree().network_peer = null
		peer = null
		get_tree().quit()
		
func _on_player_death(pid):
	players_info[pid]["status"] = STATUS_DEAD
	num_dead += 1
	if get_tree().is_network_server():
		#Declare winner as the last one standing
		var is_winner = false
		if num_dead >= len(players_info) - 1:
			for pid in players_info:
				if players_info[pid]["status"] == STATUS_PLAYING:
					is_winner = true
					rpc("declare_winner", pid)
					break
			if !is_winner:
				#Declare a tie
				rpc("declare_winner", 0)
		

remotesync func declare_winner(winner_pid:int):
	if winner_pid > 0:
		players_info[winner_pid]["wins"] += 1
	emit_signal("game_over", winner_pid)

func _process(_delta):
	if get_tree().network_peer != null and get_tree().is_network_server():
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
	var spawn_order = range(MAX_PLAYERS)
	spawn_order.shuffle()
	for pid in players_info:
		world.rpc("spawn_player", pid, spawn_order.pop_front())
	
remotesync func start_game():
	var _err = get_tree().change_scene("res://scenes/game.tscn")
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
	connection_status = "Hosting..."
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
	else:
		connection_status = "Can't host game on this port."
		emit_signal("abort_game")

func join_game(name, p_ip:String, p_port:int):	
	players_info.clear()
	player_name = name
	connection_status = "Connecting..."
	peer = NetworkedMultiplayerENet.new()
	port = p_port
	server_ip = p_ip
	var err = peer.create_client(p_ip, p_port)
	if err == OK:
		get_tree().network_peer = peer
	else:
		emit_signal("connection_failure")
