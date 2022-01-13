extends KinematicBody2D
class_name Player

const FREEZING_THRESHOLD:float = 0.3

onready var body = $Body
onready var body_anim = $Body/Anim
onready var head_sprite = $Body/HeadSprite
onready var leg_sprite = $LegSprite
onready var arm_sprite = $Body/ArmSprite
onready var ground_sensor = $GroundSensor
onready var label = $Label
var label_offset = Vector2()

onready var throw_sound = $ThrowSound
onready var pain_sounds = $PainSounds
onready var step_sounds = $StepSounds
onready var splash_sounds = $SplashSounds

puppet var puppet_pos = Vector2()
puppet var puppet_motion = Vector2()
puppet var puppet_rotation = 0.0
puppet var puppet_health = 1.0

var move_speed = 256.0
var move_accel = 2048.0
var move_friction = 1024.0
var ice_friction = 512.0 #Friction while on ice
var ice_accel = 1024.0 #Acceleration while on ice
var water_speed = 128.0 #Speed of movement in water
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
var water_damage = 1.0 #Percentage of temp. lost when in water
var temp_regen_rate = 0.01 #Percentage of temperature regained per second

signal health_change(new_health)
signal died()
var health:float = 1.0 setget set_health #Percentage
var hurt_sound_timer = 0.0
var hurt_sound_freq = 1.0

var freeze_rate:float = 0.1 #Percentage of health lost per second while freezing

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
	
	ground_sensor.connect("water_entered", self, "_on_water_transition")
	ground_sensor.connect("water_exited", self, "_on_water_transition")
	
	#Add label to the HUD node so it shows up over everything
	label_offset = label.rect_position
	remove_child(label)
	get_node("../../HUD").add_child(label)
	
	#Mark enemy players so they get hit by snowballs
	if not is_network_master():
		collision_layer |= 4
		$Camera2D.current = false
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
			var friction = ice_friction if ground_sensor.is_on_ice() else move_friction
			if speed != 0.0:
				velocity *= max(0.0, speed - friction * delta) / speed
		else:
			var accel = move_accel if !ground_sensor.is_on_ice() else ice_friction
			velocity += motion * accel * delta
		
		#Turn to face the cursor
		var m_pos = get_global_mouse_position()
		body.rotation = atan2(m_pos.y - position.y, m_pos.x - position.x)
		
		if ground_sensor.is_on_water():
			set_temperature(temperature - water_damage * delta)
		else:
			set_temperature(temperature + temp_regen_rate * delta)
		
		#Fire snowballs
		if Input.is_action_pressed("throw") and throw_timer <= 0.0 and !ground_sensor.is_on_water():
			throw_timer = throw_speed
			rpc("throw_snowball", balls_thrown, position, Vector2(cos(body.rotation), sin(body.rotation)), peer_id)
			balls_thrown += 1
		else:
			throw_timer -= delta
			
		if temperature < FREEZING_THRESHOLD:
			set_health(health - freeze_rate * delta)
			
		if Input.is_action_just_pressed("cheat_die"):
			set_health(0.1)
			body_anim.play("pain")
			
		if health <= 0.0:
			rpc("die")
			return
		
		rset_unreliable("puppet_motion", motion)
		rset_unreliable("puppet_pos", position)
		rset_unreliable("puppet_rotation", body.rotation)
		rset("puppet_health", health)
	else:
		position = puppet_pos
		motion = puppet_motion
		body.rotation = puppet_rotation
		health = puppet_health
		
	if ground_sensor.is_on_water():
		body_anim.play("underwater")
	elif !body_anim.playback_active:
		body_anim.play("default")

	if not is_zero_approx(motion.length_squared()):
		leg_sprite.animation = "walk"
		leg_sprite.rotation = atan2(motion.y, motion.x)
		if !ground_sensor.is_on_water():
			step_timer += delta
			if step_timer > step_freq:
				step_timer = 0.0
				play_random_sound(step_sounds, 0.5 if ground_sensor.is_on_ice() else 0.0)
	else:
		leg_sprite.animation = "idle"
	
	hurt_sound_timer += delta
	
	#Make name tag follow us
	label.rect_position = position + label_offset
		
func _physics_process(_delta):
	var speed = velocity.length()
	var max_speed = move_speed if !ground_sensor.is_on_water() else water_speed
	if speed > max_speed: #Prevent velocity from exceeding maximum speed
		velocity *= max_speed / speed
	var _res = move_and_slide(velocity)

func _on_peer_disconnect(id):
	if id == peer_id:
		#If the peer for this player disconnected, remove the node
		if is_instance_valid(label): label.queue_free()
		queue_free()
		
func _on_water_transition():
	var puff = preload("res://scenes/objects/puff.tscn").instance()
	get_parent().add_child(puff)
	puff.position = position
	play_random_sound(splash_sounds)
		
func set_temperature(new_temp):
	temperature = clamp(new_temp, 0.0, 1.0)
	emit_signal("temperature_change", temperature)
	
func set_health(new_health):
	health = max(0.0, new_health)
	emit_signal('health_change', health)

func play_random_sound(parent_node:Node, pitch_ofs:float = 0.0):
	var idx = randi() % parent_node.get_child_count()
	var sound:AudioStreamPlayer2D = parent_node.get_child(idx)
	sound.pitch_scale = 1.0 - (abs(randf()) * 0.1) + pitch_ofs
	sound.play()

remotesync func _on_snowball_hit(snowball_name:String):
	var snowball = get_node("../" + snowball_name)
	body_anim.play("pain")
	
	if hurt_sound_timer > hurt_sound_freq: 
		play_random_sound(pain_sounds)
		hurt_sound_timer = 0.0
	
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

remotesync func die():
	var corpse = preload("res://scenes/objects/corpse.tscn").instance()
	get_parent().add_child(corpse)
	corpse.position = position
	play_random_sound(corpse.get_node("DeathSounds"))
	corpse.get_node("Blood").emitting = true
	corpse.rotation = rand_range(0.0, 2.0 * PI)
	label.queue_free()
	var cam = $Camera2D
	var pos = cam.global_position
	remove_child(cam)
	get_parent().add_child(cam)
	cam.global_position = pos
	emit_signal("died")
	queue_free()
