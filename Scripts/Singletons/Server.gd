extends Node

var network = ENetMultiplayerPeer.new() 
var ip = "127.0.0.1"
var port  = 6969
var gateway
var spawner =  MultiplayerSpawner.new()

var connected_peer_ids = []
var local_player_character


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	multiplayer.connected_to_server.connect(OnConnectionSucceeded)
	multiplayer.connection_failed.connect(OnConnectionFailed)
	#connect_to_server()
	#print(self.get_path())
	#spawner.add_spawnable_scene("res://Objects/rocket.tscn")
	#spawner.add_spawnable_scene("res://Objects/explosion.tscn")
	#spawner.spawn_path = ".."
	#add_child(spawner)
	
	


func _exit_tree() -> void:
	print("Hello")

func connect_to_server():
	
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(ip, port)
	multiplayer.multiplayer_peer = peer		
	#get_tree().root.get_node()
	
	
func OnConnectionFailed():
	print("Failed To Connect")
	
func OnConnectionSucceeded():
	print("Successfully Connected")
	
@rpc("any_peer","call_remote")
func recieve_map(map):
	print(map)
	enter_game()
	
func enter_game():
	get_tree().root.get_node("Client").get_node("CanvasLayer").hide()
	var map_instance = load("res://Objects/Maps/DefaultDM.tscn").instantiate()
	get_tree().root.get_node("Client").add_child(map_instance)
	
	

func add_player_character(peer_id, color):
	connected_peer_ids.append(peer_id)
	var player_character = preload("res://Objects/Player.tscn").instantiate()
	
	player_character.color = color
	player_character.position = Global.spawn_points.pick_random()
	player_character.set_multiplayer_authority(int(peer_id),true)
	player_character.name = str(peer_id)
	add_child(player_character)
	
	if int(peer_id) == multiplayer.get_unique_id():
		local_player_character = player_character
		
		
@rpc("any_peer")
func send_rocket(direction, position,target,fly_direction,player_name):
	var r = preload("res://Objects/rocket.tscn").instantiate()
	
	r.global_position = position
	
	r.velocity = fly_direction  * 15
	r.rotation = direction
	r.rotation.x -= rad_to_deg(-90)
	r.shooter = player_name
	add_child(r)

func add_rocket(direction, position,target,fly_direction,player_name):
	rpc_id(1,"send_rocket",direction, position,target,fly_direction,player_name)

@rpc
func add_newly_connected_player_character(new_peer_id, color):
	add_player_character(new_peer_id, color)
	
@rpc
func add_previously_connected_player_characters(peer_ids,peer_names,peer_colors):
	for i in peer_ids.size():
		
		
		
		add_player_character(peer_ids[i],peer_colors[i])
		
@rpc("any_peer")
func remove_player(player_id = 1):
	player_id
	rpc_id(1, "remove_player", multiplayer.get_unique_id())
	
@rpc
func remove_other_player(player_id):
	for player in get_children():
		if player.get_multiplayer_authority() == int(player_id):
			player.queue_free()
			break
			
			
@rpc
func kill_player(player_id):
	for player in get_children():
		if player.get_multiplayer_authority() == player_id:
			player.take_damage(1000)
			break

@rpc
func update_colors(player_id):
	for player in get_children():
		if player.get_multiplayer_authority() == int(player_id):
			player.update_colors()
			break


@rpc
func knockback_player(player_id,direction,energy):
	var target = get_node(str(player_id))
	target.knockback(direction, energy)

@rpc	("any_peer")
func send_player_data(player_id,color, username):
	pass
	
@rpc
func recieve_player_data(player_id):
	rpc_id(1,"send_player_data",str(player_id),Global.char_color,Global.char_name)
	
@rpc	
func update_cosmetics():
	pass
