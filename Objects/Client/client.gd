extends Node


var char_name
var char_color

var helm_index := 0
var helms
var old_map_name := ""

##Variables if you're the host

@export var current_map_name := ""
var map_pool := []
var map_index := 0
@export var kill_limit := 1
@export var round_end = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	
	helms = []
	for helm in $CanvasLayer/HelmetSelect/SubViewportContainer/SubViewport/betterplayer/Skeleton3D/Head/Helmets.get_children():
		helms.append(helm)
	
	Global.helmet_index = helm_index
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
	Global.mouse_sense = mouse_sense


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if old_map_name != current_map_name and multiplayer.multiplayer_peer != null:
		change_map()
	
	$CanvasLayer/Polygon2D.texture_offset.x += 0.1
	$CanvasLayer/Polygon2D.texture_offset.y += 0.1
	if $CanvasLayer.visible and !$CanvasLayer/AudioStreamPlayer.playing:
		$CanvasLayer/AudioStreamPlayer.playing = $CanvasLayer.visible
	elif !$CanvasLayer.visible and $CanvasLayer/AudioStreamPlayer.playing:
		$CanvasLayer/AudioStreamPlayer.playing = $CanvasLayer.visible
	
func _input(event: InputEvent) -> void:
	#Add some useful debugging inputs to test certain host functions
	if !is_multiplayer_authority(): return
	
	if event.is_action_pressed("change_map"):
		change_map()


func _on_connect_pressed() -> void:
	
	if $CanvasLayer/Customize/Username.text != "":
		%NetworkManager.active_ip = $CanvasLayer/TextEdit.text
		%NetworkManager.active_port = $CanvasLayer/TextEdit2.text
		#$CanvasLayer.hide()
		%NetworkManager.join_as_client()
		
		Global.char_name = $CanvasLayer/Customize/Username.text
		
		#var map_instance = load("res://Objects/Maps/DefaultDM.tscn").instantiate()
		#add_child(map_instance)



func _on_quit_pressed() -> void:
	get_tree().quit()
	
	


func _on_color_picker_color_changed(color: Color) -> void:
	helms[helm_index].get_child(0).get_surface_override_material(0).albedo_color = color
	$CanvasLayer/HelmetSelect/SubViewportContainer/SubViewport/betterplayer/Skeleton3D/Neck_001.get_surface_override_material(1).albedo_color = color
	Global.char_color = color
	#$CanvasLayer/HelmetSelect/SubViewportContainer/SubViewport/playerModel/Chest/Neck/Head/Chivalrous/Chivalrous.get_surface_override_material(0).albedo_color = color
	#$CanvasLayer/HelmetSelect/SubViewportContainer/SubViewport/playerModel/Chest/Neck/Head/Chivalrous/Chivalrous/Cube_050.get_surface_override_material(0).albedo_color = color
	#
	#$CanvasLayer/HelmetSelect/SubViewportContainer/SubViewport/playerModel/Chest/Neck/Head/conquerer/Conquerer.get_surface_override_material(0).albedo_color = color
	#$CanvasLayer/HelmetSelect/SubViewportContainer/SubViewport/playerModel/Chest/Neck/Head/imperial/GreatHelm.get_surface_override_material(0).albedo_color = color
	#$CanvasLayer/HelmetSelect/SubViewportContainer/SubViewport/playerModel/Chest/Neck/Head/Mercenary/Varangian.get_surface_override_material(0).albedo_color = color
	#$CanvasLayer/HelmetSelect/SubViewportContainer/SubViewport/playerModel/Chest/Neck/Head/Defender/Sallet.get_surface_override_material(0).albedo_color = color



func _on_next_pressed() -> void:
	helms[helm_index].hide()
	helm_index += 1
	if helm_index >= helms.size():
		helm_index = 0
	helms[helm_index].show()
	Global.helmet_index = helm_index

func _on_previous_pressed() -> void:
	helms[helm_index].hide()
	helm_index -= 1
	if helm_index < 0:
		helm_index = helms.size()-1
	helms[helm_index].show()
	Global.helmet_index = helm_index


func _on_credits_pressed() -> void:
	$CanvasLayer/CreditsWindow.show()
	

func _on_host_pressed() -> void:
	$CanvasLayer/HostScreen.show()
	
	#if $CanvasLayer/TextEdit2.text.is_valid_int() and $CanvasLayer/Customize/Username.text != "":
		#Global.helmet_index = helm_index
		#Global.char_name = $CanvasLayer/Customize/Username.text
		#print("Become host pressed")
		##var map_instance = load("res://Objects/Maps/DefaultDM.tscn").instantiate()
		#var map_dir = "res://Objects/Maps"
		#
		#add_child(map_instance)
		#$CanvasLayer.hide()
		#%NetworkManager.active_port = int($CanvasLayer/TextEdit2.text)
		#%NetworkManager.become_host()
		
		


func _on_start_pressed() -> void:
	map_pool = []
	if $CanvasLayer/TextEdit2.text.is_valid_int() and $CanvasLayer/Customize/Username.text != "" and $CanvasLayer/HostScreen/Panel/Maps/MapPool.get_children().size() >=2:
		Global.helmet_index = helm_index
		Global.char_name = $CanvasLayer/Customize/Username.text
		kill_limit = $CanvasLayer/HostScreen/SpinBox.value
		print("Become host pressed")
		#var map_instance = load("res://Objects/Maps/DefaultDM.tscn").instantiate()
		var map_dir = "res://Objects/Maps"
		
		for map_button in $CanvasLayer/HostScreen/Panel/Maps/MapPool.get_children():
			if map_button is Label:
				pass
			elif map_button is Button:
				map_pool.append((map_button.text + ".tscn").replace(".remap",""))
		current_map_name = map_dir+"/"+map_pool[map_index]
		if current_map_name.contains(".remap"):
			current_map_name = current_map_name.replace(".remap","")
		old_map_name = current_map_name
		var map_instance = load(current_map_name).instantiate()
		add_child(map_instance)
		$CanvasLayer.hide()
		$CanvasLayer/HostScreen.hide()
		%NetworkManager.active_port = int($CanvasLayer/TextEdit2.text)
		%NetworkManager.become_host()


func _on_players_child_entered_tree(node: Node) -> void:
	#print("player added")
	for player in $Players.get_children():
		if player.has_method("update_scoreboard"):
			player.update_scoreboard()

func change_map():
	if !multiplayer.multiplayer_peer: return
	if is_multiplayer_authority():
		map_index += 1
		if map_index >= map_pool.size():
			map_index = 0
		var map_dir = "res://Objects/Maps"
		current_map_name = map_dir+"/"+map_pool[map_index]
		old_map_name = current_map_name
		print("Map is changing to " + current_map_name)
		for i in get_tree().get_nodes_in_group("map"):
			i.queue_free()
		var map_instance = load(current_map_name).instantiate()
		add_child(map_instance)
		for player in $Players.get_children():
			player.score = 0
			player.respawn()
	#else:
		#old_map_name = current_map_name
		#print("Map is changing to " + current_map_name)
		#for i in get_tree().get_nodes_in_group("map"):
			#i.queue_free()
		#var map_instance = load(current_map_name).instantiate()
		#add_child(map_instance)	
		
	for player in $Players.get_children():
		if player.input.is_multiplayer_authority():
			old_map_name = current_map_name
			player.input.respawn_hit = true


func finish_round():
	
	
	await get_tree().create_timer(20).timeout
	change_map()
	round_end = false
