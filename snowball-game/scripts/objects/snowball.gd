extends KinematicBody2D

puppet var puppet_position = Vector2()

var move_speed = 500.0
var direction = Vector2()
var life_timer = 0.0

func _ready():
	puppet_position = position

func _physics_process(delta):
	if is_network_master():
		life_timer += delta
		
		var col = move_and_collide(direction * move_speed * delta)
		if col or life_timer > 10.0:
			rpc("die")
		rset("puppet_position", position)
	else:
		position = puppet_position

remotesync func die():
	queue_free()
