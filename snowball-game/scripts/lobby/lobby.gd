extends Control

onready var conn_panel = $ConnectionPanel
onready var lobby_panel = $LobbyPanel

func _ready():
	var _err = Global.connect("connected", self, "_on_connected")
	_err = Global.connect("abort_game", self, "_on_abort")
	conn_panel.visible = true
	lobby_panel.visible = false
	
func _on_connected():
	conn_panel.visible = false
	lobby_panel.visible = true
	
func _on_abort(_message:String):
	conn_panel.visible = true
	lobby_panel.visible = false
