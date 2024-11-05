extends Area3D






func _on_body_entered(body: Node3D) -> void:
	print(body.name + " Killed")
	Server.kill_player(body.get_multiplayer_authority())
