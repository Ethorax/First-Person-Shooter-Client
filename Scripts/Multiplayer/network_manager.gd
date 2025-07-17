extends Node

enum MULTIPLAYER_NETWORK_TYPE { ENET, STEAM }

@export var _players_spawn_node: Node3D

var active_network_type: MULTIPLAYER_NETWORK_TYPE = MULTIPLAYER_NETWORK_TYPE.ENET
var enet_network_scene := preload("res://Objects/Multiplayer/EnetNetwork.tscn")

var active_ip = ""
var active_port := 6969
var active_network

func _ready() -> void:
	multiplayer.connected_to_server.connect(hide_client)
	multiplayer.connection_failed.connect(show_client)

func _build_multiplayer_network():
	active_network = null
	active_network_type = MULTIPLAYER_NETWORK_TYPE.ENET
	if not active_network:
		print("Setting active_network")
		MultiplayerManager.multiplayer_mode_enabled = true
		
		match active_network_type:
			MULTIPLAYER_NETWORK_TYPE.ENET:
				print("Setting network type to ENet")
				_set_active_network(enet_network_scene)
			#MULTIPLAYER_NETWORK_TYPE.STEAM:
				#print("Setting network type to Steam")
				#_set_active_network(steam_network_scene)
			#_:
				#print("No match for network type!")

func _set_active_network(active_network_scene):
	var network_scene_initialized = active_network_scene.instantiate()
	active_network = network_scene_initialized
	active_network._players_spawn_node = _players_spawn_node
	
	var upnp = UPNP.new()
	upnp.discover(2000, 2, "InternetGatewayDevice")
	print(upnp.query_external_address())
	active_network.server_ip = upnp.query_external_address()
	active_network.server_port = active_port
	add_child(active_network)

func become_host(is_dedicated_server = false):
	multiplayer.multiplayer_peer.close()
	_build_multiplayer_network()
	MultiplayerManager.host_mode_enabled = true if is_dedicated_server == false else false
	active_network.become_host()
	
func join_as_client(lobby_id = 0):
	
	multiplayer.multiplayer_peer.close()
	#for enet in get_children():
		#enet.queue_free()
	if multiplayer.server_disconnected.is_connected(return_to_menu): multiplayer.server_disconnected.disconnect(return_to_menu)
	
	_build_multiplayer_network()
	active_network.server_ip = active_ip
	active_network.join_as_client(lobby_id)
	multiplayer.server_disconnected.connect(return_to_menu)
	
func list_lobbies():
	_build_multiplayer_network()
	active_network.list_lobbies()
	
	
func return_to_menu():
	#Disconnecting from a match but not the game
	multiplayer.multiplayer_peer.close()
	multiplayer.server_disconnected.disconnect(return_to_menu)
	active_network = null
	show_client()
	for player in get_parent().get_node("Players").get_children():
		player.queue_free()
	for map in get_tree().get_nodes_in_group("map"):
		map.queue_free()
	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func show_client():
	print("multiplayer failed")
	active_network = null
	get_child(0).queue_free()
	get_parent().get_child(0).show()
	multiplayer.server_disconnected.disconnect(return_to_menu)

func hide_client():
	get_parent().get_child(0).hide()
