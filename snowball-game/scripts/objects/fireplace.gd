extends KinematicBody2D

func _ready():
	$WarmingArea/Polygon2D/AnimationPlayer.play("default")
	$Smoke.emitting = true
