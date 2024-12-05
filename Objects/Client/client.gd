extends Node

var char_name
var char_color

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	var config = ConfigFile.new()

# Load data from a file.
	var err = config.load("res://Config/options.cfg")
	if err != OK:
		return
	
	var fov = config.get_value("Options","fov")
	var game_volume = config.get_value("Options","game_volume")
	var music_volume = config.get_value("Options","music_volume")
	var mouse_sense = config.get_value("Options","mouse_sense")
	
	var music = AudioServer.get_bus_index("Music")
	var sfx = AudioServer.get_bus_index("SFX")
	AudioServer.set_bus_volume_db(music,-80.0 + music_volume*(80.0/100.0))
	AudioServer.set_bus_volume_db(sfx,-80.0 + game_volume*(80.0/100.0))
	Global.fov = fov


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_connect_pressed() -> void:
	Server.ip = $CanvasLayer/TextEdit.text
	
	if $CanvasLayer/Customize/Username.text == "":
		pass
	else:
		Global.char_color = $CanvasLayer/Customize/ColorPicker.color
		Global.char_name = $CanvasLayer/Customize/Username.text
		Server.connect_to_server()



func _on_quit_pressed() -> void:
	print("button works")
	rpc_id(1, 'print_name')
	
	
