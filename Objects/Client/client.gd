extends Node

var char_name
var char_color




var helm_index = 0
var helms

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	
	
	helms = [
	$CanvasLayer/HelmetSelect/SubViewportContainer/SubViewport/playerModel/Chest/Neck/Head/Chivalrous,
	$CanvasLayer/HelmetSelect/SubViewportContainer/SubViewport/playerModel/Chest/Neck/Head/conquerer,
	$CanvasLayer/HelmetSelect/SubViewportContainer/SubViewport/playerModel/Chest/Neck/Head/imperial,
	$CanvasLayer/HelmetSelect/SubViewportContainer/SubViewport/playerModel/Chest/Neck/Head/Mercenary,
	$CanvasLayer/HelmetSelect/SubViewportContainer/SubViewport/playerModel/Chest/Neck/Head/Defender
	]
	Global.helmet = helms[helm_index].name
	helms[helm_index].show()
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

	$CanvasLayer/Polygon2D.texture_offset.x += 0.1
	$CanvasLayer/Polygon2D.texture_offset.y += 0.1


func _on_connect_pressed() -> void:
	Server.ip = $CanvasLayer/TextEdit.text
	Server.port = $CanvasLayer/TextEdit2.text
	
	if $CanvasLayer/Customize/Username.text == "":
		pass
	else:
		
		for player in Server.get_children():
			if player is CharacterBody3D:
				player.queue_free()
		
		
		Global.char_color = $CanvasLayer/Customize/ColorPicker.color
		Global.char_name = $CanvasLayer/Customize/Username.text
		Server.connect_to_server()



func _on_quit_pressed() -> void:
	get_tree().quit()
	
	


func _on_color_picker_color_changed(color: Color) -> void:
	$CanvasLayer/HelmetSelect/SubViewportContainer/SubViewport/playerModel/Chest/Neck/Head/Chivalrous/Chivalrous.get_surface_override_material(0).albedo_color = color
	$CanvasLayer/HelmetSelect/SubViewportContainer/SubViewport/playerModel/Chest/Neck/Head/Chivalrous/Chivalrous/Cube_050.get_surface_override_material(0).albedo_color = color
	
	$CanvasLayer/HelmetSelect/SubViewportContainer/SubViewport/playerModel/Chest/Neck/Head/conquerer/Conquerer.get_surface_override_material(0).albedo_color = color
	$CanvasLayer/HelmetSelect/SubViewportContainer/SubViewport/playerModel/Chest/Neck/Head/imperial/GreatHelm.get_surface_override_material(0).albedo_color = color
	$CanvasLayer/HelmetSelect/SubViewportContainer/SubViewport/playerModel/Chest/Neck/Head/Mercenary/Varangian.get_surface_override_material(0).albedo_color = color
	$CanvasLayer/HelmetSelect/SubViewportContainer/SubViewport/playerModel/Chest/Neck/Head/Defender/Sallet.get_surface_override_material(0).albedo_color = color



func _on_next_pressed() -> void:
	helms[helm_index].hide()
	helm_index += 1
	if helm_index >= helms.size():
		helm_index = 0
	helms[helm_index].show()
	Global.helmet = helms[helm_index].name

func _on_previous_pressed() -> void:
	helms[helm_index].hide()
	helm_index -= 1
	if helm_index < 0:
		helm_index = helms.size()-1
	helms[helm_index].show()
	Global.helmet = helms[helm_index].name


func _on_credits_pressed() -> void:
	$CanvasLayer/CreditsWindow.show()
