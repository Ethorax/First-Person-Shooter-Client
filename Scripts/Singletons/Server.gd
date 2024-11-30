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
	spawner.add_spawnable_scene("res://Objects/rocket.tscn")
	spawner.add_spawnable_scene("res://Objects/explosion.tscn")
	spawner.spawn_path = ".."
	spawner.add_spawnable_scene("res://Objects/Player.tscn")
	add_child(spawner)
	
	

func connect_to_server():
	
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(ip, port)
	multiplayer.multiplayer_peer = peer		
	#get_tree().root.get_node()
	
	
func OnConnectionFailed():
	print("Failed To Connect")
	
func OnConnectionSucceeded():
	print("Successfully Connected")
	
@rpc("any_peer","call_remote","reliable")
func recieve_map(map):
	print("Receiving Map: "+map)
	enter_game()
	
func enter_game():
	get_tree().root.get_node("Client").get_node("CanvasLayer").hide()
	var map_instance = load("res://Objects/Maps/default_dm_textured.tscn").instantiate()
	get_tree().root.get_node("Client").add_child(map_instance)
	print("Entering Game...")
	
	

func add_player_character(peer_id):
	
	#print("Adding player: "+str(peer_id)+" With color: "+ str(color))
	
	connected_peer_ids.append(peer_id)
	var player_character = preload("res://Objects/Player.tscn").instantiate()
	#await get_tree().create_timer(1).timeout
	add_child(player_character)
	#player_character.color = color
	player_character.position = Global.spawn_points.pick_random()
	player_character.set_multiplayer_authority(int(peer_id))
	player_character.name = str(peer_id)
	
	#add_child(player_character)
	
	if int(peer_id) == multiplayer.get_unique_id():
		local_player_character = player_character
		
		local_player_character.toggle_hitbox()
		
@rpc("any_peer")
func send_rocket(direction, position,target,fly_direction,player_name):
	var r = preload("res://Objects/rocket.tscn").instantiate()
	
	r.global_position = position
	
	r.velocity = fly_direction  * 15
	r.rotation = direction
	r.rotation.x -= rad_to_deg(-90)
	r.shooter = player_name
	add_child(r)

func add_grenade(direction, position,target,fly_direction,player_name):
	rpc_id(1,"send_grenade",direction, position,target,fly_direction,player_name)
	
@rpc("any_peer")
func send_grenade(direction, position,target,fly_direction,player_name):
	var g = preload("res://Objects/grenade.tscn").instantiate()
	
	g.position = position
	g.shooter = player_name
	add_child(g)
	g.apply_central_force(direction*-10)

func add_rocket(direction, position,target,fly_direction,player_name):
	rpc_id(1,"send_rocket",direction, position,target,fly_direction,player_name)	


func add_fireball(direction, position,target,fly_direction,player_name):
	rpc_id(1,"send_fireball",direction, position,target,fly_direction,player_name)
	
@rpc("any_peer")
func send_fireball(direction, position,target,fly_direction,player_name):
	var f = preload("res://Objects/fireball.tscn").instantiate()
	
	f.position = position
	f.shooter = player_name
	add_child(f)
	f.apply_central_force(direction*-10)


@rpc("reliable")
func add_newly_connected_player_character(new_peer_id):
	add_player_character(new_peer_id)
	
@rpc("reliable")
func add_previously_connected_player_characters(peer_ids,peer_names,peer_colors):
	for i in peer_ids.size():
		#print(peer_colors[i])
		
		
		add_player_character(peer_ids[i])
		
@rpc("any_peer")
func remove_player(player_id = 1):
	player_id
	print("Player " +str(player_id) + " Removed")
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
		if player.is_in_group("Player"):
			if player.get_multiplayer_authority() == player_id:
				player.take_damage(1000,"1",str(player_id))
				break

@rpc
func update_colors(player_ids,player_colors):
	for player in get_children():
		for i in player_ids.size():
			if str(player_ids[i]) == player.name:
				player.color = player_colors[i]
				player.update_colors()
				break
		#if player.get_multiplayer_authority() == int(player_id):
		#if player.is_in_group("Player"):
			#player.update_colors()
		print("Player color updated: " +str(player.name))
				#break


@rpc
func knockback_player(player_id,direction,energy):
	var target = get_node(str(player_id))
	target.knockback(direction, energy)

@rpc("any_peer")
func send_player_data(player_id,color, username):
	pass
	
@rpc("reliable")
func recieve_player_data(player_id):
	rpc_id(1,"send_player_data",str(player_id),Global.char_color,Global.char_name)
	
@rpc	
func update_cosmetics():
	pass
	
@rpc("any_peer")
func broadcast_chat(player_name,text):
	rpc_id(1,"broadcast_chat",player_name,text)
	
@rpc
func new_chat(player_name,text):
	for player in get_children():
		if player.is_in_group("Player"):
			var new_text : Label = Label.new()
			new_text.text = (player_name+": "+text)
			print(player_name+": "+text)
			player.get_node("CanvasLayer/UI/Chat/VScrollBar/VBoxContainer").add_child(new_text)


			#player.get_node("CanvasLayer/UI/Chat/VScrollBar").get_v_scroll_bar().value = player.get_node("CanvasLayer/UI/Chat/VScrollBar").get_v_scroll_bar().max_value
@rpc("reliable")
func damage_player(damage,to,from):
	for player in get_children():
		if player.name == str(to):
			player.take_damage(damage,to,from)

@rpc("any_peer","call_local","reliable")
func hit_player(damage,to,from):
	rpc_id(1,"hit_player",damage,to,from)
	
@rpc("any_peer")
func frag(to,from = "1"):
	pass

@rpc
func update_scoreboard(name_array,color_array,frag_array):
	for player in get_children():
		if player.is_in_group("Player"):
			player.update_scores(name_array,color_array,frag_array)




@rpc
func test_connection():
	print("testing connection")
	
	
@rpc
func server_message(message):
	for player in get_children():
		if player.is_in_group("Player"):
			var new_text : Label = Label.new()
			new_text.text = (message)
			print(message)
			player.get_node("CanvasLayer/UI/Chat/VScrollBar/VBoxContainer").add_child(new_text)
