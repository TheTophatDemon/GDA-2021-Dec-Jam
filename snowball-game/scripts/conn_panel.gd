extends Control

const AUTO_NAMES = [
	"Gopnik", "Stinkoman", "Butt Muncher Jr.", "Sans Undertale", "The Pope", "Mr. /b/", "Christina-chan", 
	"Killbo Fraggins", "George Washington", "Feeb", "Bakugo", "Thomas the Tank Engine", "Butt Muncher Sr.",
	"Tony the Tiger", "Vladimir Putin", "Big Ham", "Sgt. Frog", "Deku", "Nezuko", "Rodion Raskolnikov",
	"Quote", "Johnny Bravo", "Mr. Krabs", "Dr. Eggman", "COVID-19", "Android 18", "Hatsune Miku", "Hmph!",
	"Literally Hitler", "Captain", "I_am_someth1ng", "Sir Truffle III", "arthurvi", "Kill me",
]

onready var host_button = $MarginContainer/GridContainer/HostButton
onready var join_button = $MarginContainer/GridContainer/JoinButton
onready var ip_edit = $MarginContainer/GridContainer/IPEdit
onready var port_edit = $MarginContainer/GridContainer/PortEdit
onready var name_edit = $MarginContainer/GridContainer/NameEdit
onready var status_label = $MarginContainer/GridContainer/StatusLabel

func set_status(message:String):
	status_label.text = message

func _ready():
	if len(Global.player_name) == 0 :
		name_edit.text = AUTO_NAMES[randi() % len(AUTO_NAMES)]
	else:
		name_edit.text = Global.player_name
	var _err = host_button.connect("button_down", self, "_on_host_button_press")
	_err = join_button.connect("button_down", self, "_on_join_button_press")
	_err = Global.connect("abort_game", self, "_on_abort")
	_err = Global.connect("connected", self, "_on_connection_success")
	_err = Global.connect("connection_failure", self, "_on_connection_fail")
	
func start_connection():
	freeze()
	
func _process(_delta):
	set_status(Global.connection_status)
	
func _on_connection_success():
	var _err = get_tree().change_scene("res://scenes/lobby.tscn")
	
func _on_connection_fail():
	set_status("Connection failed")
	unfreeze()
	
func freeze():
	host_button.disabled = true
	join_button.disabled = true
	name_edit.editable = false
	ip_edit.editable = false
	port_edit.editable = false
	
func unfreeze():
	host_button.disabled = false
	join_button.disabled = false
	name_edit.editable = true
	ip_edit.editable = true
	port_edit.editable = true

func _on_abort():
	unfreeze()

func validate_player_name(name:String) -> String:
	return name.trim_prefix(" ").trim_suffix(" ").validate_node_name()

func _on_host_button_press():
	if port_edit.text.is_valid_integer():
		start_connection()
		
		Global.host_game(validate_player_name(name_edit.text), int(port_edit.text))
	else:
		status_label.text = "Invalid port..."
	
func _on_join_button_press():
	if ip_edit.text.is_valid_ip_address() and port_edit.text.is_valid_integer():
		start_connection()
		Global.join_game(validate_player_name(name_edit.text), ip_edit.text, int(port_edit.text))
	else:
		status_label.text = "Invalid IP/port..."
