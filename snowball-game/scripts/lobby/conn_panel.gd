extends Control

onready var host_button = $MarginContainer/GridContainer/HostButton
onready var join_button = $MarginContainer/GridContainer/JoinButton
onready var ip_edit = $MarginContainer/GridContainer/IPEdit
onready var port_edit = $MarginContainer/GridContainer/PortEdit
onready var name_edit = $MarginContainer/GridContainer/NameEdit
onready var status_label = $MarginContainer/GridContainer/StatusLabel

func _ready():
	name_edit.text = Global.AUTO_NAMES[randi() % len(Global.AUTO_NAMES)]
	var _err = host_button.connect("button_down", self, "_on_host_button_press")
	_err = join_button.connect("button_down", self, "_on_join_button_press")
	_err = Global.connect("abort_game", self, "_on_abort")

func start_connection():
	host_button.disabled = true
	join_button.disabled = true
	name_edit.editable = false
	ip_edit.editable = false
	port_edit.editable = false
	status_label.text = "Status: Connecting..."
	#The lobby script will handle connection success by switching screens
	yield(Global, "connection_failure")
	host_button.disabled = false
	join_button.disabled = false
	name_edit.editable = true
	ip_edit.editable = true
	port_edit.editable = true
	status_label.text = "Status: Connection failed."

func _on_abort(message:String):
	status_label.text = message

func _on_host_button_press():
	if port_edit.text.is_valid_integer():
		start_connection()
		Global.host_game(name_edit.text, int(port_edit.text))
	else:
		status_label.text = "Invalid port..."
	
func _on_join_button_press():
	if ip_edit.text.is_valid_ip_address() and port_edit.text.is_valid_integer():
		Global.join_game(name_edit.text, ip_edit.text, int(port_edit.text))
		start_connection()
	else:
		status_label.text = "Invalid IP/port..."