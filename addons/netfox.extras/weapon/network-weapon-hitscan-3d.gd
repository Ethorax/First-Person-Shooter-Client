extends Node3D
class_name NetworkWeaponHitscan3D

@onready var bullet_decal: BulletHole = $BulletDecal

## A 3D-specific implementation of a networked hitscan (raycast) weapon.
var rng = RandomNumberGenerator.new()
## Maximum distance to cast the ray
@export var max_distance: float = 1000.0

## Mask used to detect raycast hits
@export_flags_3d_physics var collision_mask: int = 0xFFFFFFFF

## Colliders excluded from raycast hits
@export var exclude: Array[RID] = []

var _weapon: _NetworkWeaponProxy

var last_fire = -1
@onready var player: CharacterBody3D = $"../../.."

@onready var weapons = $"../../../Skeleton3D/Weapon hand/Weapons"
var damage := 1
var fire_rate := 0.5
var fire_sound : AudioStream
var projectile
var b_spread

func _ready() -> void:
	rng.randomize()
	NetworkTime.on_tick.connect(_tick)

## Try to fire the weapon and return the projectile.
## [br][br]
## Returns true if the weapon was fired.
func fire(override:bool = false) -> bool:
	if not can_fire() and !override:
		return false
	
	var gun_data = weapons.get_child(player.weapon_index).gun_data as GunData
	player.add_ammo(gun_data.ammo_type,-1)
	print(override)
	if !override and gun_data.ammo_type == "shotgun":
		player.add_ammo(gun_data.ammo_type, 7)
			
		
	_apply_data(_get_data())
	_after_fire()
	return true

## Check whether this weapon can be fired.
func can_fire() -> bool:
	return _weapon.can_fire()

func _init():
	_weapon = _NetworkWeaponProxy.new()
	add_child(_weapon, true, INTERNAL_MODE_BACK)
	_weapon.owner = self

	_weapon.c_can_fire = _can_fire
	_weapon.c_can_peer_use = _can_peer_use
	_weapon.c_after_fire = _after_fire
	_weapon.c_spawn = _spawn
	_weapon.c_get_data = _get_data
	_weapon.c_apply_data = _apply_data
	_weapon.c_is_reconcilable = _is_reconcilable
	_weapon.c_reconcile = _reconcile

## Override this method with your own can fire logic.
## [br][br]
## See [NetworkWeapon].
func _can_fire() -> bool:
	return NetworkTime.seconds_between(last_fire, NetworkTime.tick) >= fire_rate
	#return true

## Override this method to check if a given peer can use this weapon.
## [br][br]
## See [NetworkWeapon].
func _can_peer_use(peer_id: int) -> bool:
	#return true
	return peer_id == %Input.get_multiplayer_authority()

## Override this method to run any logic needed after successfully firing the 
## weapon.
## [br][br]
## See [NetworkWeapon].
func _after_fire():
	last_fire = NetworkTime.tick

func _spawn():
	# No projectile is spawned for a hitscan weapon.
	pass

func _get_data() -> Dictionary:
	# Collect data needed to synchronize the firing event.
	global_rotation_degrees.x += rng.randf_range(-b_spread,b_spread)
	global_rotation_degrees.y += rng.randf_range(-b_spread,b_spread)
	var spread_angle = -global_transform.basis.z
	rotation_degrees = Vector3.ZERO
	return {
		"origin": global_transform.origin,
		"direction": spread_angle  # Assuming forward direction.
	}

func _apply_data(data: Dictionary):
	# Reproduces the firing event on all peers.
	
	
	var origin = data["origin"] as Vector3
	var direction = data["direction"] as Vector3
	print(direction)

	# Perform the raycast from origin in the given direction.
	var space_state = get_world_3d().direct_space_state

	# Create a PhysicsRayQueryParameters3D object.
	var ray_params = PhysicsRayQueryParameters3D.new()
	ray_params.from = origin
	ray_params.to = origin + direction * max_distance

	# Set collision masks or exclude objects:
	ray_params.collision_mask = collision_mask
	ray_params.exclude = exclude

	var result = space_state.intersect_ray(ray_params)

	if result:
		# Handle the hit result, such as spawning hit effects.
		_on_hit(result)

	# Play firing effects on all peers.
	_on_fire()

func _is_reconcilable(request_data: Dictionary, local_data: Dictionary) -> bool:
	# Always reconcilable
	return true

func _reconcile(local_data: Dictionary, remote_data: Dictionary):
	# Nothing to do on reconcile
	pass

## Override to implement raycast hit logic.
## [br][br]
## The parameter is the result of a
## [method PhysicsDirectSpaceState3D.intersect_ray] call.
func _on_hit(result: Dictionary):
	#print(result.collider.name)
	
	var current_weapon = weapons.get_child($"../../..".weapon_index)
	if result.collider.has_method("take_damage") and current_weapon.name != "Sword":
		result.collider.take_damage(damage, %Input.get_multiplayer_authority())
		trigger_marker()
	else:
		bullet_decal.action(result)
	if current_weapon.name == "Sword":
		if result.collider.global_position.distance_to(global_position)<=4.0:
			if result.collider.has_method("take_damage"):
				result.collider.take_damage(damage, %Input.get_multiplayer_authority())
				trigger_marker()
			else:
				bullet_decal.action(result)
	if current_weapon.name == "Sniper" and result.collider.has_method("take_damage"):
		#print(result)
		print(result.position.y - result.collider.position.y)
		if (result.position.y - result.collider.position.y) >= 1.68:
			get_parent().get_parent().get_parent().get_node("Audio").get_node("Announcer").get_node("headshot").play()
			result.collider.take_damage(150, %Input.get_multiplayer_authority())
			trigger_marker()
## Override to implement firing effects, like muzzle flash or sound.
func _on_fire():
	if projectile: return
	# Implement firing effect logic here.
	var current_weapon = weapons.get_child($"../../..".weapon_index)
	if fire_sound:
		$"../../Gunshots".stream = fire_sound
		$"../../Gunshots".play()
	current_weapon.get_node("AnimationPlayer").stop()
	current_weapon.get_node("AnimationPlayer").play("fire")
	#print(current_weapon.name)
	var arm_anim = get_parent().get_parent().get_parent().get_node("ArmAnim") as AnimationPlayer
	if str(current_weapon.name) == "Sword":
		arm_anim.stop()
		arm_anim.play("fire_sword",-1,2.0)
	else:
		arm_anim.stop()
		arm_anim.play("fire_" + str(current_weapon.gun_data.hold_pose))
	
func _tick(_delta:float, _t:int):
	if %Input.fire and can_fire() and !projectile:
		var gun_data = weapons.get_child(player.weapon_index).gun_data as GunData
		#player.add_ammo(gun_data.ammo_type,-1)
		if player.ammo_dict[gun_data.ammo_type] <= 0:
			return
		
		if fire_sound.resource_path.contains("shotgun"):
			fire()
			for i in 7:
				
				
				
				fire(true)
				
			
				#print(fire_sound.resource_path.contains("shotgun"))
		else:
			fire()

func trigger_marker(auth_input = 1):
	var root_node = get_parent().get_parent().get_parent()
	root_node.hitmarker.modulate.a = 1.0
	
