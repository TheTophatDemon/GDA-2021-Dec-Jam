extends Control

onready var player = get_node("../..")

onready var mercury = $Thermometer/Mercury
onready var mercury_max_height = mercury.rect_size.y
onready var vignette = $FreezeVignette

func _ready():
	player.connect("temperature_change", self, "_on_temperature_change")
	if !is_network_master():
		queue_free()
	
func _on_temperature_change(new_temp:float):
	mercury.rect_size.y = mercury_max_height * new_temp
	var vignette_threshold = Player.FREEZING_THRESHOLD + 0.1
	if new_temp < vignette_threshold:
		vignette.modulate.a = (vignette_threshold - new_temp) / vignette_threshold
