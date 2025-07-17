extends Panel



@onready var chat_box: LineEdit = $ChatBox


func _ready() -> void:
	hide()

func _input(event: InputEvent) -> void:
	if !get_parent().get_parent().get_parent().input.is_multiplayer_authority(): return
	if event.is_action_pressed("chat"):
		show()
		$ChatTimer.stop()
		$ChatBox.grab_focus.call_deferred()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event.is_action_pressed("pause"):
		$ChatBox.release_focus.call_deferred()
		$ChatTimer.start()
		


func _on_chat_timer_timeout() -> void:
	hide()


func _on_chat_box_text_submitted(new_text: String) -> void:
	print(new_text)
	chat_box.text = ""
	show()
	$ChatBox.release_focus.call_deferred()
	$ChatTimer.start()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if new_text == "": return
	new_text = get_player_name() + ": " + new_text
	rpc("add_chat", new_text)


func _on_v_box_container_child_entered_tree(node: Node) -> void:
	show()
	await get_tree().create_timer(0.16).timeout
	$VScrollBar.get_v_scroll_bar().value = $VScrollBar.get_v_scroll_bar().max_value
	$ChatTimer.start()

@rpc("any_peer","call_local")
func add_chat(chat : String):
	
	
	for chat_node in get_tree().get_nodes_in_group("Chat"):
		print(chat)
		var label : Label = Label.new()
		label.text = chat
		chat_node.add_child(label)

func get_player_name() -> String:
	return get_parent().get_parent().get_parent().username
