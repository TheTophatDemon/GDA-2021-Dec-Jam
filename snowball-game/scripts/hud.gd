extends Control

const LOBBY_SCN = preload("res://scenes/lobby_panel.tscn")

onready var player = get_node("../..")

onready var mercury = $Thermometer/Mercury
onready var mercury_max_height = mercury.rect_size.y
onready var vignette = $FreezeVignette

onready var health_bar = $HealthBar/Bar
onready var health_bar_max = health_bar.rect_size.x

onready var tie_label = $TieLabel
onready var win_label = $WinLabel

var lobby_panel = null

func _ready():
	var _err = player.connect("temperature_change", self, "_on_temperature_change")
	_err = player.connect("health_change", self, "_on_health_change")
	_err = Global.connect("game_over", self, "_on_game_over")
	
	tie_label.visible = false
	win_label.visible = false
	
	if is_network_master():
		$SpectatorLabel.visible = false
	
func _on_temperature_change(new_temp:float):
	mercury.rect_size.y = mercury_max_height * new_temp
	var vignette_threshold = Player.FREEZING_THRESHOLD + 0.1
	if new_temp < vignette_threshold:
		vignette.modulate.a = (vignette_threshold - new_temp) / vignette_threshold

func _on_health_change(new_health:float):
	health_bar.rect_size.x = health_bar_max * new_health

func _on_game_over(winner_pid:int):
	if winner_pid == 0:
		tie_label.visible = true
	else:
		win_label.text = win_label.text % Global.players_info[winner_pid]["name"]
		win_label.visible = true
	
	yield(get_tree().create_timer(3.0), "timeout")
	Global.rpc("set_status", get_tree().get_network_unique_id(), Global.STATUS_UNREADY)
	var _err = get_tree().change_scene("res://scenes/lobby.tscn")

func _process(_delta):
	if Input.is_action_just_pressed("menu"):
		if !is_instance_valid(lobby_panel):
			lobby_panel = LOBBY_SCN.instance()
			add_child(lobby_panel)
		else:
			remove_child(lobby_panel)
			lobby_panel.queue_free()
