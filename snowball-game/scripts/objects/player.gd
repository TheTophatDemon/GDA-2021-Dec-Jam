extends KinematicBody2D

onready var sprite = $Sprite
onready var label = $Label
var label_offset = Vector2()

puppet var puppet_pos = Vector2()
puppet var puppet_motion = Vector2()

var move_speed = 256.0

var motion = Vector2()

var peer_id = 0

func _ready():
	var _err = get_tree().connect("network_peer_disconnected", self, "_on_peer_disconnect")
	puppet_pos = position
	label.text = Global.players_info[peer_id]["name"]
	
	#Add label to the HUD node so it shows up over everything
	label_offset = label.rect_position
	remove_child(label)
	get_node("../../HUD").add_child(label)
	
func _process(_delta):
	if is_network_master():
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
		
		rset("puppet_motion", motion)
		rset("puppet_pos", position)
	else:
		position = puppet_pos
		motion = puppet_motion
	
	#Make name tag follow us
	label.rect_position = position + label_offset
		
func _physics_process(_delta):
	var _res = move_and_slide(motion * move_speed)

func _on_peer_disconnect(id):
	if id == peer_id:
		#If the peer for this player disconnected, remove the node
		if is_instance_valid(label): label.queue_free()
		queue_free()
