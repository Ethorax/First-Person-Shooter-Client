extends Node3D
class_name NetworkWeapon3D

## A 3D-specific implementation of [NetworkWeapon].

## Distance to consider too large during reconciliation checks.
@export var distance_threshold: float = 1.0

var _weapon: _NetworkWeaponProxy
@onready var ray_cast_3d: RayCast3D = $"../../RayCast3D"

@onready var weapons = $"../../../Skeleton3D/Weapon hand/Weapons"

@onready var player: CharacterBody3D = $"../../.."

var damage := 1
var fire_rate := 0.5
var fire_sound : AudioStream
var projectile
var last_fire = -1

func _ready() -> void:
	NetworkTime.on_tick.connect(_tick)

func can_fire() -> bool:
	return _weapon.can_fire()

func fire() -> Node3D:
	
	
	
	return _weapon.fire()

func get_fired_tick() -> int:
	return _weapon.get_fired_tick()

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


## See [NetworkWeapon]
func _can_fire() -> bool:
	return NetworkTime.seconds_between(last_fire, NetworkTime.tick) >= fire_rate


## See [NetworkWeapon]
func _can_peer_use(peer_id: int) -> bool:
	return peer_id == %Input.get_multiplayer_authority()


## See [NetworkWeapon]
func _after_fire(projectile: Node3D):
	last_fire = NetworkTime.tick

## See [NetworkWeapon]
func _spawn() -> Node3D:
	if !projectile: return
	var gun_data = weapons.get_child(player.weapon_index).gun_data as GunData
	player.add_ammo(gun_data.ammo_type,-1)
	var projectile_instance = projectile.instantiate()
	projectile_instance.shooter = %Input.get_multiplayer_authority()
	projectile_instance.global_transform = global_transform
	
	print(projectile_instance.name)
	if ray_cast_3d.is_colliding() and projectile_instance.name =="Rocket":
		if ray_cast_3d.global_position.distance_to(ray_cast_3d.get_collision_point()) < 2.0:
			projectile_instance.point_blank = true
	
	projectile_instance.damage = damage
	get_tree().root.get_node("Client").add_child(projectile_instance)
	
	
	var current_weapon = weapons.get_child($"../../..".weapon_index)
	if fire_sound:
		$"../../Gunshots".stream = fire_sound
		$"../../Gunshots".play()
	var arm_anim = get_parent().get_parent().get_parent().get_node("ArmAnim") as AnimationPlayer
	arm_anim.stop()
	arm_anim.play("fire_" + str(current_weapon.gun_data.hold_pose))
	current_weapon.get_node("AnimationPlayer").stop()
	current_weapon.get_node("AnimationPlayer").play("fire")
	
	return projectile_instance

func _get_data(projectile: Node3D) -> Dictionary:
	return {
		"global_transform": projectile.global_transform
	}

func _apply_data(projectile: Node3D, data: Dictionary):
	#if !projectile: return
	projectile.global_transform = data["global_transform"]

func _is_reconcilable(projectile: Node3D, request_data: Dictionary, local_data: Dictionary) -> bool:
	var req_transform = request_data["global_transform"] as Transform3D
	var loc_transform = local_data["global_transform"] as Transform3D
	
	var request_pos = req_transform.origin
	var local_pos = loc_transform.origin
	
	return request_pos.distance_to(local_pos) < distance_threshold

func _reconcile(projectile: Node3D, local_data: Dictionary, remote_data: Dictionary):
	var local_transform = local_data["global_transform"] as Transform3D
	var remote_transform = remote_data["global_transform"] as Transform3D

	var relative_transform = projectile.global_transform * local_transform.inverse()
	var final_transform = remote_transform * relative_transform
	
	projectile.global_transform = final_transform

func _tick(_delta:float, _t:int):
	if %Input.fire:
		projectile = weapons.get_child($"../../..".weapon_index).gun_data.projectile
		if !projectile: return
		var gun_data = weapons.get_child(player.weapon_index).gun_data as GunData
		#player.add_ammo(gun_data.ammo_type,-1)
		if player.ammo_dict[gun_data.ammo_type] <= 0:
			return
		
		
		fire()
