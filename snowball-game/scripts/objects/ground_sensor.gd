extends Area2D

const ICE_LAYER = 16
const WATER_LAYER = 32
const WARMTH_LAYER = 128
const TREE_LAYER = 256

signal water_entered()
signal water_exited()

#Counts for the number of bodies of water/ice that are intersecting at the moment
var n_ice_bodies = 0
var n_water_bodies = 0
var n_warmth_bodies = 0
var n_trees = 0

func is_on_ice() -> bool:
	return n_ice_bodies > 0

func is_on_water() -> bool:
	return n_water_bodies > 0

func is_on_warmth() -> bool:
	return n_warmth_bodies > 0
	
func is_in_tree() -> bool:
	return n_trees > 0

func _ready():
	var _err = connect("body_entered", self, "_on_enter")
	_err = connect("body_exited", self, "_on_exit")
	_err = connect("area_entered", self, "_on_enter")
	_err = connect("area_exited", self, "_on_exit")
	
func _on_enter(other):
	if (other.collision_layer & ICE_LAYER) > 0:
		n_ice_bodies += 1
	elif (other.collision_layer & WATER_LAYER) > 0:
		n_water_bodies += 1
		emit_signal("water_entered")
	elif (other.collision_layer & WARMTH_LAYER) > 0:
		n_warmth_bodies += 1
	elif (other.collision_layer & TREE_LAYER) > 0:
		n_trees += 1
	
func _on_exit(other):
	if (other.collision_layer & ICE_LAYER) > 0:
		n_ice_bodies -= 1
	elif (other.collision_layer & WATER_LAYER) > 0:
		n_water_bodies -= 1
		if n_water_bodies == 0: emit_signal("water_exited")
	elif (other.collision_layer & WARMTH_LAYER) > 0:
		n_warmth_bodies -= 1
	elif (other.collision_layer & TREE_LAYER) > 0:
		n_trees -= 1
