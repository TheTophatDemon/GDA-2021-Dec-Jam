extends KinematicBody2D

puppet var puppet_position = Vector2()

var move_speed = 500.0
var direction = Vector2()
var life_timer = 0.0
var hit = false

func _ready():
	puppet_position = position

func _process(_delta):
	if is_network_master():
		if hit or life_timer > 10.0:
			rpc("die")
			return
		rset_unreliable("puppet_position", position)
	else:
		position = puppet_position

func _physics_process(delta):
	if is_network_master():
		life_timer += delta
		
		var col = move_and_collide(direction * move_speed * delta)
		if col:
			hit = true
			if col.collider.has_method("_on_snowball_hit"):
				col.collider.rpc("_on_snowball_hit", name)
		else:
			hit = false

remotesync func die():
	var puff = preload("res://scenes/objects/puff.tscn").instance()
	get_parent().add_child(puff)
	puff.position = position
	queue_free()
