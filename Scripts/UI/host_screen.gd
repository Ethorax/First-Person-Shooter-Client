extends Control

var folder_path = "res://Objects/Maps/"

func _ready() -> void:
	var dir = DirAccess.open(folder_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.contains("DM") and file_name.contains(".tscn"):
				print(file_name)
				file_name = file_name.replace(".tscn","")
				var button_instance = Button.new()
				button_instance.text = file_name
				button_instance.add_theme_font_size_override("font_size",50)
				
				$Panel/Maps/MapSelection.add_child(button_instance)
				button_instance.pressed.connect(add_map.bind(button_instance))
				
			file_name = dir.get_next()
			
			
func add_map(map_button):
	print("Map button pressed " + str(map_button.name))
	var map_dupe = map_button.duplicate()
	$Panel/Maps/MapPool.add_child(map_dupe)
	map_dupe.pressed.connect(delete_map.bind(map_dupe))
	

func delete_map(map_button ):
	map_button.queue_free()


func _on_back_pressed() -> void:
	hide()
