extends Node

var char_name
var char_color

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


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
	
	
