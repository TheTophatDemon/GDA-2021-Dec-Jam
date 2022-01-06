extends KinematicBody2D

onready var sprite = $HeadSprite
onready var label = $Label
var label_offset = Vector2()

puppet var puppet_pos = Vector2()
puppet var puppet_motion = Vector2()
puppet var puppet_rotation = 0.0

var move_speed = 256.0

var motion = Vector2()

var player_name = "Unnamed"
var peer_id = 0

var throw_speed = 0.5
var throw_timer = throw_speed

func _ready():
	var _err = get_tree().connect("network_peer_disconnected", self, "_on_peer_disconnect")
	puppet_pos = position
	puppet_rotation = rotation
	player_name = Global.players_info[peer_id]["name"]
	label.text = player_name
	
	$HeadSprite/ColorSprite.modulate = Color(player_name.hash() | 0x000000FF)
	
	#Add label to the HUD node so it shows up over everything
	label_offset = label.rect_position
	remove_child(label)
	get_node("../../HUD").add_child(label)
	
	#Mark enemy players so they get hit by snowballs
	if not is_network_master():
		collision_layer |= 4
	
func _process(delta):
	if is_network_master():
		#Movement
		if Input.is_action_pressed("move_up"):
			motion.y = -1.0
		elif Input.is_action_pressed("move_down"):
			motion.y = 1.0
		else:
			motion.y = 0.0
			
		if Input.is_action_pressed("move_left"):
			motion.x = -1.0
		elif Input.is_action_pressed("move_right"):
			motion.x = 1.0
		else:
			motion.x = 0.0
			
		motion = motion.normalized()
		
		#Turn to face the cursor
		var m_pos = get_global_mouse_position()
		rotation = atan2(m_pos.y - position.y, m_pos.x - position.x)
		
		#Fire snowballs
		if Input.is_action_pressed("throw") and throw_timer <= 0.0:
			throw_timer = throw_speed
			rpc("throw_snowball", position, Vector2(cos(rotation), sin(rotation)), peer_id)
		else:
			throw_timer -= delta
		
		rset("puppet_motion", motion)
		rset("puppet_pos", position)
		rset("puppet_rotation", rotation)
	else:
		position = puppet_pos
		motion = puppet_motion
		rotation = puppet_rotation
	
	#Make name tag follow us
	label.rect_position = position + label_offset
		
func _physics_process(_delta):
	var _res = move_and_slide(motion * move_speed)

func _on_peer_disconnect(id):
	if id == peer_id:
		#If the peer for this player disconnected, remove the node
		if is_instance_valid(label): label.queue_free()
		queue_free()

remotesync func throw_snowball(pos:Vector2, dir:Vector2, owner_id:int):
	var ball = preload("res://scenes/objects/snowball.tscn").instance()
	ball.name = "Bomb" + String(owner_id)
	ball.direction = dir
	ball.position = pos
	ball.set_network_master(owner_id)
	get_node("../").add_child(ball)
