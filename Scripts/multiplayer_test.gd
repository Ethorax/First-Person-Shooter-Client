extends Node3D

var peer = ENetMultiplayerPeer.new()
@export var player_scene : PackedScene
@onready var ip: TextEdit = $IP

var port = 7777
# Called when the node enters the scene tree for the first time.
#func _ready() -> void:
	#pass # Replace with function body.
#
#
## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass

func _ready() -> void:
	for point in $SpawnPoints.get_children():
		Global.spawn_points.append(point.position)



func _on_host_pressed() -> void:
	peer.create_server(7777)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	_add_player( multiplayer.get_unique_id())
	upnp_setup()
	toggle_multiplayer_menu()

func _add_player(id = 1):
	var player = player_scene.instantiate()
	player.position = Global.spawn_points.pick_random()
	
	player.name = str(id)
	call_deferred("add_child",player)

func remove_player(peer_id):
	var player = get_node_or_null(str(peer_id))
	if player:
		player.queue_free()

func _on_join_pressed() -> void:
	peer.create_client(ip.text, port)
	multiplayer.multiplayer_peer = peer
	toggle_multiplayer_menu()
	
func upnp_setup():
	var upnp = UPNP.new()
	
	var discover_result = upnp.discover()
	var gateway = upnp.get_gateway()
	assert(discover_result == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP Discover Failed! Error %s" % discover_result)
	
	assert(upnp.get_gateway() and upnp.get_gateway().is_valid_gateway(), \
		"UPNP Invalid Gateway!")

	var map_result = upnp.add_port_mapping(port)
	assert(map_result == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP Port Mapping Failed! Error %s" % map_result)
	
	print("Success! Join Address: %s" % upnp.query_external_address())
	
func toggle_multiplayer_menu():
	$Host.visible = !$Host.visible
	$Join.visible = !$Join.visible
	$IP.visible = !$IP.visible

	
