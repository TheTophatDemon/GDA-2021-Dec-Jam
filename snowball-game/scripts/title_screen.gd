extends Control

func _ready():
	$Instructions/AnimationPlayer.play("default")

func _input(event):
	if event is InputEventMouseButton:
		var _err = get_tree().change_scene("res://scenes/connection.tscn")
