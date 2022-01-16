extends Node2D

const PLAYER_SCN = preload("res://scenes/objects/player.tscn")

onready var gameplay_node = $Gameplay

onready var music_player:AudioStreamPlayer = $MusicPlayer

var win = false
var tie = false
var music_fade_speed:float = 20.0
var music_cutoff:float = -12.0
var fanfare = false

func _ready():
	var _err = Global.connect("abort_game", self, "_on_abort")
	_err = Global.connect("game_over", self, "_on_game_over")
	Global.rpc("set_status", get_tree().get_network_unique_id(), Global.STATUS_PLAYING)

func _on_abort():
	Global.connection_status = "Server bailed on you."
	var _err = get_tree().change_scene("res://scenes/connection.tscn")
	
func _process(delta):
	if tie or win:
		if !fanfare and music_player.volume_db > music_cutoff:
			music_player.volume_db -= delta * music_fade_speed
			if music_player.volume_db <= music_cutoff:
				music_player.volume_db = 0.0
				if win:
					music_player.stream = preload("res://sounds/win_fanfare.wav")
				elif tie:
					music_player.stream = preload("res://sounds/tie_fanfare.wav")
				music_player.play()
				fanfare = true
	
func _on_game_over(winner_pid):
	if winner_pid == 0:
		tie = true
	else:
		win = true

remotesync func spawn_player(pid:int, pos:Vector2):
	var node = PLAYER_SCN.instance()
	node.set_network_master(pid, true)
	node.peer_id = pid
	gameplay_node.add_child(node)
	node.name = "Player%s" % pid
	node.position = pos
	node.connect("died", Global, "_on_player_death", [pid])
