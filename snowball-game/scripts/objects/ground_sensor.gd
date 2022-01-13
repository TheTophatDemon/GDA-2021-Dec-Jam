extends Area2D

const ICE_LAYER = 16
const WATER_LAYER = 32

signal water_entered()
signal water_exited()

#Counts for the number of bodies of water/ice that are intersecting at the moment
var n_ice_bodies = 0
var n_water_bodies = 0

func is_on_ice() -> bool:
	return n_ice_bodies > 0

func is_on_water() -> bool:
	return n_water_bodies > 0

func _ready():
	var _err = connect("body_entered", self, "_on_body_enter")
	_err = connect("body_exited", self, "_on_body_exit")
	
func _on_body_enter(body):
	if (body.collision_layer & ICE_LAYER) > 0:
		n_ice_bodies += 1
	elif (body.collision_layer & WATER_LAYER) > 0:
		n_water_bodies += 1
		emit_signal("water_entered")
	
func _on_body_exit(body):
	if (body.collision_layer & ICE_LAYER) > 0:
		n_ice_bodies -= 1
	elif (body.collision_layer & WATER_LAYER) > 0:
		n_water_bodies -= 1
		if n_water_bodies == 0: emit_signal("water_exited")
