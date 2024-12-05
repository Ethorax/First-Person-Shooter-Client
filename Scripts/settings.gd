extends Control


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
	
	$VBoxContainer/HBoxContainer/GameSlider.value = game_volume
	$VBoxContainer/HBoxContainer4/MusicSlider.value = music_volume
	$VBoxContainer/HBoxContainer2/FOVSlider.value = fov
	$VBoxContainer/HBoxContainer3/MouseSlider.value = mouse_sense


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_apply_pressed() -> void:
	
	var config = ConfigFile.new()

# Load data from a file.
	var err = config.load("res://Config/options.cfg")
	if err != OK:
		return
	
	config.set_value("Options","music_volume",$VBoxContainer/HBoxContainer4/MusicSlider.value)
	config.set_value("Options","game_volume",$VBoxContainer/HBoxContainer/GameSlider.value)
	config.set_value("Options","fov",$VBoxContainer/HBoxContainer2/FOVSlider.value)
	config.set_value("Options","mouse_sense",$VBoxContainer/HBoxContainer3/MouseSlider.value)
	
	config.save("res://Config/options.cfg")
	
	var music = AudioServer.get_bus_index("Music")
	var sfx = AudioServer.get_bus_index("SFX")
	var music_amount = -80.0 + $VBoxContainer/HBoxContainer4/MusicSlider.value*(80.0/100.0)
	print($VBoxContainer/HBoxContainer4/MusicSlider.value)
	print(music_amount)
	AudioServer.set_bus_volume_db(music,music_amount)
	var sound_amount = -80.0 + $VBoxContainer/HBoxContainer/GameSlider.value*(80.0/100.0)
	AudioServer.set_bus_volume_db(sfx,sound_amount)
	print(AudioServer.get_bus_volume_db(music))
	print(AudioServer.get_bus_volume_db(sfx))
	Global.fov = $VBoxContainer/HBoxContainer2/FOVSlider.value

	
	hide()


func _on_discard_pressed() -> void:
	hide()


func _on_game_slider_value_changed(value: float) -> void:
	$VBoxContainer/HBoxContainer/Label2.text = str(value)


func _on_music_slider_value_changed(value: float) -> void:
	$VBoxContainer/HBoxContainer4/Label2.text = str(value)


func _on_fov_slider_value_changed(value: float) -> void:
	$VBoxContainer/HBoxContainer2/Label2.text = str(value)


func _on_mouse_slider_value_changed(value: float) -> void:
	$VBoxContainer/HBoxContainer3/Label2.text = str(value)


func _on_visibility_changed() -> void:
	
	var config = ConfigFile.new()

# Load data from a file.
	var err = config.load("res://Config/options.cfg")
	if err != OK:
		return
	
	var fov = config.get_value("Options","fov")
	var game_volume = config.get_value("Options","game_volume")
	var music_volume = config.get_value("Options","music_volume")
	var mouse_sense = config.get_value("Options","mouse_sense")
	
	$VBoxContainer/HBoxContainer/GameSlider.value = game_volume
	$VBoxContainer/HBoxContainer4/MusicSlider.value = music_volume
	$VBoxContainer/HBoxContainer2/FOVSlider.value = fov
	$VBoxContainer/HBoxContainer3/MouseSlider.value = mouse_sense
