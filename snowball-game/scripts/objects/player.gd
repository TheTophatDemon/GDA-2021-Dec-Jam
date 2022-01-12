extends KinematicBody2D
class_name Player

const FREEZING_THRESHOLD:float = 0.3

onready var body = $Body
onready var body_anim = $Body/Anim
onready var head_sprite = $Body/HeadSprite
onready var leg_sprite = $LegSprite
onready var arm_sprite = $Body/ArmSprite
onready var label = $Label
var label_offset = Vector2()

onready var throw_sound = $ThrowSound
onready var pain_sounds = $PainSounds
onready var step_sounds = $StepSounds

puppet var puppet_pos = Vector2()
puppet var puppet_motion = Vector2()
puppet var puppet_rotation = 0.0

var move_speed = 256.0
var move_accel = 2048.0
var move_friction = 1024.0
var step_timer = 0.0
var step_freq = 0.3

var snowball_knockback = 2048.0
var snowball_damage = 0.05 #Percentage of temp. lost when hit by snowball

var motion = Vector2()
var velocity = Vector2()

var player_name = "Unnamed"
var peer_id = 0

var throw_speed = 0.25
var throw_timer = throw_speed

signal temperature_change(new_temp)
var temperature:float = 1.0 setget set_temperature #Percentage of body heat

var balls_thrown = 0

func _ready():
	var _err = get_tree().connect("network_peer_disconnected", self, "_on_peer_disconnect")
	puppet_pos = position
	puppet_rotation = rotation
	player_name = Global.players_info[peer_id]["name"]
	label.text = player_name
	
	$Body/HeadSprite/ColorSprite.modulate = Color(player_name.hash() | 0x000000FF)
	leg_sprite.modulate = Color(player_name.to_upper().hash() | 0x000000FF)
	leg_sprite.animation = "idle"
	leg_sprite.playing = true
	
	arm_sprite.playing = true
	arm_sprite.frame = arm_sprite.frames.get_frame_count("default")-1
	
	body_anim.play("default")
	
	#Add label to the HUD node so it shows up over everything
	label_offset = label.rect_position
	remove_child(label)
	get_node("../../HUD").add_child(label)
	
	#Mark enemy players so they get hit by snowballs
	if not is_network_master():
		collision_layer |= 4
		$Camera2D.queue_free()
	else:
		$Camera2D.current = true
	
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
		
		#Movement speed
		if is_zero_approx(motion.length_squared()):
			#Friction
			var speed = velocity.length()
			if speed != 0.0:
				velocity *= max(0.0, speed - move_friction * delta) / speed
		else:
			velocity += motion * move_accel * delta
		
		#Turn to face the cursor
		var m_pos = get_global_mouse_position()
		body.rotation = atan2(m_pos.y - position.y, m_pos.x - position.x)
		
		#Fire snowballs
		if Input.is_action_pressed("throw") and throw_timer <= 0.0:
			throw_timer = throw_speed
			rpc("throw_snowball", balls_thrown, position, Vector2(cos(body.rotation), sin(body.rotation)), peer_id)
			balls_thrown += 1
		else:
			throw_timer -= delta
		
		rset("puppet_motion", motion)
		rset("puppet_pos", position)
		rset("puppet_rotation", body.rotation)
	else:
		position = puppet_pos
		motion = puppet_motion
		body.rotation = puppet_rotation
	
	if not is_zero_approx(motion.length_squared()):
		leg_sprite.animation = "walk"
		leg_sprite.rotation = atan2(motion.y, motion.x)
		step_timer += delta
		if step_timer > step_freq:
			step_timer = 0.0
			play_random_sound(step_sounds)
	else:
		leg_sprite.animation = "idle"
	
	#Make name tag follow us
	label.rect_position = position + label_offset
		
func _physics_process(_delta):
	var speed = velocity.length()
	if speed > move_speed: #Prevent velocity from exceeding maximum speed
		velocity *= move_speed / speed
	var _res = move_and_slide(velocity)

func _on_peer_disconnect(id):
	if id == peer_id:
		#If the peer for this player disconnected, remove the node
		if is_instance_valid(label): label.queue_free()
		queue_free()
		
func set_temperature(new_temp):
	temperature = new_temp
	emit_signal("temperature_change", temperature)

func play_random_sound(parent_node:Node):
	var idx = randi() % parent_node.get_child_count()
	var sound:AudioStreamPlayer2D = parent_node.get_child(idx)
	sound.pitch_scale = 1.0 - (abs(randf()) * 0.1)
	sound.play()

remotesync func _on_snowball_hit(snowball_name:String):
	var snowball = get_node("../" + snowball_name)
	body_anim.play("pain")
	
	if randf() < 0.5: play_random_sound(pain_sounds)
	
	velocity += (position - snowball.position).normalized() * snowball_knockback
	set_temperature(max(0.0, temperature - snowball_damage))

remotesync func throw_snowball(index:int, pos:Vector2, dir:Vector2, owner_id:int):
	arm_sprite.frame = 0
	throw_sound.play()
	
	var ball = preload("res://scenes/objects/snowball.tscn").instance()
	ball.name = "Ball" + String(owner_id) + "#" + String(index)
	ball.direction = dir
	ball.position = pos
	ball.set_network_master(owner_id)
	get_node("../").add_child(ball)
