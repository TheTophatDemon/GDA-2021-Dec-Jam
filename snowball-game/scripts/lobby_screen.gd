extends Control

func _ready():
	var _err = Global.connect("abort_game", self, "_on_abort")
	Global.game_started = false

func _on_abort():
	Global.connection_status = "Server bailed on you."
	var _err = get_tree().change_scene("res://scenes/connection.tscn")
