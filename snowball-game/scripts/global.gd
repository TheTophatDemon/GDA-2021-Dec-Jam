extends Node

const PLAYER_SCN = preload("res://scenes/objects/player.tscn")

const MAX_PLAYERS = 8
const SERVER_PID = 1

signal connected()
signal connection_failure()
signal player_list_changed()
signal abort_game(message)

var server_ip = "127.0.0.1"
var port = 25565
var peer:NetworkedMultiplayerPeer = null

const AUTO_NAMES = [
	"Gopnik", "Stinkoman", "Butt Muncher Jr.", "Sans Undertale", "The Pope", "Mr. /b/", "Christina-chan", 
	"Killbo Fraggins", "George Washington", "Feeb", "Bakugo", "Thomas the Tank Engine", "Butt Muncher Sr.",
	"Tony the Tiger", "Vladimir Putin", "Big Ham", "Sgt. Frog", "Deku", "Nezuko", "Rodion Raskolnikov",
	"Quote", "Johnny Bravo", "Mr. Krabs", "Dr. Eggman", "COVID-19", "Android 18", "Hatsune Miku", "Hmph!",
	"Literally Hitler", "Captain", "I_am_someth1ng", "Sir Truffle III", "arthurvi", "Kill me",
]

var player_name:String

var players_info = {}
var game_started = false

func _enter_tree():
	randomize()
	var _err = get_tree().connect("network_peer_disconnected", self, "_on_peer_disconnect")
	_err = get_tree().connect("network_peer_connected", self, "_on_peer_connected")
	_err = get_tree().connect("connected_to_server", self, "_on_connection_success")
	_err = get_tree().connect("connection_failed", self, "_on_connection_failure")
	_err = get_tree().connect("server_disconnected", self, "_on_server_disconnected")

func _on_peer_connected(id:int):
	if get_tree().is_network_server():
		if game_started:
			rpc_id(id, "reject_player")
			peer.disconnect_peer(id)
		else:
			rpc_id(id, "register_player", players_info[SERVER_PID])

func _on_peer_disconnect(id:int):
	unregister_player(id)

remote func reject_player():
	players_info.clear()
	emit_signal("connection_failure", "Game is already in progress.")
	
remotesync func set_ready(id, new_state:bool):
	players_info[id]["ready"] = new_state
	emit_signal("player_list_changed")
	
remote func register_player(info):
	var id = get_tree().get_rpc_sender_id()
	print("Player registered: " + String(id))
	players_info[id] = info
	emit_signal("player_list_changed")
	
func unregister_player(id):
	players_info.erase(id)
	emit_signal("player_list_changed")

func _on_connection_success():
	rpc("register_player", players_info[peer.get_unique_id()])
	emit_signal("connected")
	
func _on_connection_failure():
	get_tree().network_peer = null
	emit_signal("connection_failure")

func _on_server_disconnected():
	emit_signal("abort_game", "Server disconnected.")

func validate_player_name(name:String) -> String:
	return name.trim_prefix(" ").trim_suffix(" ").validate_node_name()

func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		get_tree().network_peer = null
		peer = null
		get_tree().quit()

func start_game():
	assert(get_tree().is_network_server())
	
	var spawns = {}
	for pid in players_info:
		spawns[pid] = Vector2(rand_range(4.0, 500.0), rand_range(4.0, 500.0))
	
	rpc("setup_game", spawns)
	
remotesync func setup_game(spawns):
	var world = load("res://scenes/game.tscn").instance()
	get_tree().root.add_child(world)
	get_tree().root.get_node("Lobby").hide()
	var game_node = world.get_node("Gameplay")
	
	#Spawn players
	for pid in players_info:
		var node = PLAYER_SCN.instance()
		node.set_network_master(pid, true)
		node.peer_id = pid
		game_node.add_child(node)
		node.name = "Player%s" % pid
		node.position = spawns[pid]
		
	game_started = true

func host_game(name, p_port:int):
	if validate_player_name(name).length() > 0:
		player_name = name
	peer = NetworkedMultiplayerENet.new()
	port = p_port
	var err = peer.create_server(port, MAX_PLAYERS)
	if err == OK:
		get_tree().network_peer = peer
		players_info[SERVER_PID] = {
			"name": name,
			"ready": false
		}
		emit_signal("connected")
		emit_signal("player_list_changed")

func join_game(name, p_ip:String, p_port:int):	
	if validate_player_name(name).length() > 0:
		player_name = name
	peer = NetworkedMultiplayerENet.new()
	port = p_port
	server_ip = p_ip
	var err = peer.create_client(p_ip, p_port)
	if err == OK:
		get_tree().network_peer = peer
		players_info[peer.get_unique_id()] = {
			"name": player_name,
			"ready": false
		}
		emit_signal("player_list_changed")
	else:
		emit_signal("connection_failure")
