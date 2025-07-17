extends Node3D

@onready var chest: MeshInstance3D = $Chest

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func update_colors(player_color):
	#if is_multiplayer_authority():
		#$Pelvis.material_override.albedo_color = player_color
	pass



func fire_sound():
	var active_gun
	for gun in $Chest/Guns.get_children():
		if gun.visible:
			active_gun = gun
			break
	if active_gun:
		$AudioController.get_node(str(active_gun.name)).play()


func rotate_correction():
	var camera = get_parent().get_node("Camera3D") as Camera3D
	#print(camera.rotation_degrees)
	#
	#var x = camera.rotation_degrees.x/90 * 54
	#var y = -36 - abs(x)
	#var z = camera.rotation_degrees.x
	#print(x)
	#print(y)
	#print(z)
	#chest.rotation_degrees =Vector3(x,y,z) 
	#print(camera.rotation_degrees)
	#print(to_global(camera.rotation_degrees))
	#
	#print(chest.rotation_degrees)
	#print(to_global(chest.rotation_degrees))
	var temp = camera.rotation
	temp.y = deg_to_rad(-36)
	#temp.x = temp.x *-1
	chest.quaternion = Quaternion.from_euler(temp)
	print(chest.quaternion)
	print(Quaternion.from_euler(temp))
	
	#chest.quaternion = Quaternion(Vector3(1,0,0),camera.rotation.x)
	#chest.rotation_degrees = to_local(to_global(camera.rotation_degrees) - to_global(Vector3(0,-36,0)))
	#chest.rotation_degrees.y -= 36
