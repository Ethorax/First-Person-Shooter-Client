extends Node

var server_port = 8080
var server_ip = "127.0.0.1"

var multiplayer_scene = preload("res://Objects/NFplayer.tscn")
var multiplayer_peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
var _players_spawn_node

func _ready() -> void:
	pass

func become_host():
	print("Starting host!")
	multiplayer_peer = ENetMultiplayerPeer.new()
	multiplayer_peer.create_server(server_port)
	multiplayer.multiplayer_peer = multiplayer_peer
	multiplayer.peer_connected.connect(_add_player_to_game)
	multiplayer.peer_disconnected.connect(_del_player)

	if not OS.has_feature("dedicated_server"):
		_add_player_to_game(1)
	
func join_as_client(lobby_id):
	#print(multiplayer.get_unique_id())
	#multiplayer.multiplayer_peer = null
	multiplayer_peer.close()
	multiplayer_peer = ENetMultiplayerPeer.new()
	
	multiplayer_peer.create_client(server_ip, server_port)
	multiplayer.multiplayer_peer = multiplayer_peer

func _add_player_to_game(id: int):
	print("Player %s joined the game!" % id)
	
	var player_to_add = multiplayer_scene.instantiate()
	player_to_add.player_id = id
	player_to_add.name = str(id)
	
	
	_players_spawn_node.add_child(player_to_add, true)
	player_to_add.global_position = Global.spawn_points.pick_random()
	
func _del_player(id: int):
	print("Player %s left the game!" % id)
	if not _players_spawn_node.has_node(str(id)):
		return
	_players_spawn_node.get_node(str(id)).queue_free()

	
	
func leave_game():
	print("leaving game!")
	
	#multiplayer_peer.create_server(server_port)
	multiplayer.multiplayer_peer = null
	multiplayer.peer_connected.disconnect(_add_player_to_game)
	multiplayer.peer_disconnected.disconnect(_del_player)
	
	
	
	
	
