extends Control

onready var player = get_node("../..")

onready var mercury = $Thermometer/Mercury
onready var mercury_max_height = mercury.rect_size.y
onready var vignette = $FreezeVignette

onready var health_bar = $HealthBar/Bar
onready var health_bar_max = health_bar.rect_size.x

func _ready():
	var _err = player.connect("temperature_change", self, "_on_temperature_change")
	_err = player.connect("health_change", self, "_on_health_change")
	if !is_network_master():
		queue_free()
	
func _on_temperature_change(new_temp:float):
	mercury.rect_size.y = mercury_max_height * new_temp
	var vignette_threshold = Player.FREEZING_THRESHOLD + 0.1
	if new_temp < vignette_threshold:
		vignette.modulate.a = (vignette_threshold - new_temp) / vignette_threshold

func _on_health_change(new_health:float):
	health_bar.rect_size.x = health_bar_max * new_health
