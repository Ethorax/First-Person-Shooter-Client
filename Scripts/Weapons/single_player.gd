extends CharacterBody3D

@onready var camera_3d: Camera3D = $Camera3D
@onready var subviewport_camera: Camera3D = $CanvasLayer/SubViewportContainer/SubViewport/SubviewportCamera


@onready var aim: RayCast3D = $Camera3D/Aim
@onready var shotgun_container: Node3D = $Camera3D/ShotgunContainer

@onready var BULLET_DECAL = preload("res://Objects/bullet_decal.tscn")
@onready var rocket = preload("res://Objects/rocket.tscn")

#Camera Shake Variables
@export var randomStrength : float = 0.1
@export var shakeFade : float = 5.0
var rng = RandomNumberGenerator.new()
var shake_strength : float = 0.0


#Movement Variables
const SPEED = 5.0
const JUMP_VELOCITY = 4.5

var direction
var isRunning := false
var speed := 8
var jump := 30.0
const GRAVITY := 2
var distanceFootstep := 0.0
var playFootstep := 3 #Lower if we want to play the sounds faster
var _delta := 0.0
var camBobSpeed := 10 #10 
var camBobUpDown := 1 #.5
var mouse_sense = 0.15
var mouse_locked : bool

var health : int = 5
var alive : bool = true

#Gun Variables
var b_spread : float = 10.0
var og_fov : float = 75.0
var zoom_fov : float = 5.0
var current_weapon_index : int = 0
var can_shoot:bool = true
@onready var reload_timer: Timer = $ReloadTimer

func _enter_tree() -> void:
	#set_multiplayer_authority(name.to_int())
	rng.randomize()


func _physics_process(delta: float) -> void:
	
	subviewport_camera.global_transform = camera_3d.global_transform
	
	$Label.text = str(velocity)
	
	
	
	#if is_multiplayer_authority():
	$Camera3D.current = true
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	process_movement(delta)
	
	if(shake_strength>0):
		shake_strength = lerpf(shake_strength,0,shakeFade*delta)
		var r = random_offset()
		camera_3d.h_offset = r.x
		camera_3d.v_offset = r.y
	move_and_slide()
	
	
func _input(event):
	#if is_multiplayer_authority():
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x*mouse_sense))
		camera_3d.rotate_x(deg_to_rad(-event.relative.y*mouse_sense))
		camera_3d.rotation.x = clamp(camera_3d.rotation.x, deg_to_rad(-89), deg_to_rad(89))
	if event.is_action_pressed("ui_cancel"):
		if mouse_locked:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			mouse_locked = false
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			mouse_locked = true	
			
	if(event.is_action_pressed("weapon_switch_down")):
		switch_weapon_down()
	if(event.is_action_pressed("weapon_switch_up")):
		switch_weapon_up()
	if(event.is_action_pressed("fire")):
		fire_gun()
	if(event.is_action_pressed("alt_fire")):
		alt_fire()
	
func process_movement(delta):
	direction = Vector3.ZERO
	
	var h_rot = global_transform.basis.get_euler().y
	
	direction.x = -Input.get_action_strength("move_left")+Input.get_action_strength("move_right")
	direction.z = -Input.get_action_strength("move_forward")+Input.get_action_strength("move_back")
	direction = Vector3(direction.x,0,direction.z).rotated(Vector3.UP,h_rot).normalized()

	var actualSpeed = speed if !isRunning else speed*2
	
	
	if is_on_floor():
		velocity.x = lerp(velocity.x,direction.x * actualSpeed,0.5)
		velocity.z = lerp(velocity.z,direction.z * actualSpeed,0.5)
	else:
		velocity.x = lerp(velocity.x,direction.x * actualSpeed,0.01)
		velocity.z = lerp(velocity.z,direction.z * actualSpeed,0.01)


func fire_gun():
	if can_shoot:
		if $Camera3D/Guns.get_node_or_null("Pistol") != null:
			if($Camera3D/Guns.get_node("Pistol").visible):
				reload_timer.start(0.2)
				can_shoot = false
				apply_shake(0.02)
				
				aim.global_rotation_degrees.x += rng.randf_range(-b_spread,b_spread)
				aim.global_rotation_degrees.y += rng.randf_range(-b_spread,b_spread)
				aim.force_raycast_update()
				if(aim.is_colliding()):
					
					if(aim.get_collider().is_in_group("Player")):
						print("Player Hit")
						var hit_player = aim.get_collider()
						hit_player.take_damage.rpc_id(hit_player.get_multiplayer_authority(),1)
					else:
						var b = BULLET_DECAL.instantiate()
						get_parent().add_child(b)
						b.global_position = aim.get_collision_point()
						print(aim.get_collision_point())
						var surface_dir_up = Vector3(0,1,0)
						var surface_dir_down = Vector3(0,-1,0)
						if aim.get_collision_normal() == surface_dir_up:
							b.look_at(aim.get_collision_point() + aim.get_collision_normal(), Vector3.RIGHT)
						elif aim.get_collision_normal() == surface_dir_down:
							b.look_at(aim.get_collision_point() + aim.get_collision_normal(), Vector3.RIGHT)
						else:
							b.look_at(aim.get_collision_point() + aim.get_collision_normal(), Vector3.DOWN)
				var pistol_anim = $Camera3D/Guns/Pistol/AnimationPlayer as AnimationPlayer	
				pistol_anim.stop()
				pistol_anim.play("fire")
				print(aim.rotation_degrees)
				aim.rotation_degrees = Vector3.ZERO
		if $Camera3D/Guns.get_node_or_null("Sniper"):
			if($Camera3D/Guns/Sniper.visible):
				apply_shake(0.02)
				reload_timer.start(0.5)
				can_shoot = false
				
				if(aim.is_colliding()):
					
					if(aim.get_collider().is_in_group("Player")):
						print("Player Hit")
						var hit_player = aim.get_collider()
						hit_player.take_damage.rpc_id(hit_player.get_multiplayer_authority(),1)
					else:
						var b = BULLET_DECAL.instantiate()
						get_parent().add_child(b)
						b.global_position = aim.get_collision_point()
						print(aim.get_collision_point())
						var surface_dir_up = Vector3(0,1,0)
						var surface_dir_down = Vector3(0,-1,0)
						if aim.get_collision_normal() == surface_dir_up:
							b.look_at(aim.get_collision_point() + aim.get_collision_normal(), Vector3.RIGHT)
						elif aim.get_collision_normal() == surface_dir_down:
							b.look_at(aim.get_collision_point() + aim.get_collision_normal(), Vector3.RIGHT)
						else:
							b.look_at(aim.get_collision_point() + aim.get_collision_normal(), Vector3.DOWN)
				var sniper_anim = $Camera3D/Guns/Sniper/AnimationPlayer as AnimationPlayer	
				sniper_anim.stop()
				sniper_anim.play("fire")
				print(aim.rotation_degrees)
				aim.rotation_degrees = Vector3.ZERO
					
					
		if $Camera3D/Guns.get_node_or_null("Bazooka")!=null:
			if($Camera3D/Guns/Bazooka.visible):
				$Camera3D/Guns/Bazooka/AnimationPlayer.play("fire")
				apply_shake(0.01)
				reload_timer.start(0.8)
				can_shoot = false
				var r_instance = rocket.instantiate()
				get_parent().add_child(r_instance)
				#r_instance.global_position = Vector3(aim.global_position.x,aim.global_position.y,aim.global_position.z-2)
				#r_instance.global_rotation.y = camera_3d.global_rotation.y
				#r_instance.global_rotation.x = rotation.x
				r_instance.global_position = $Camera3D/ShootLocation.global_position
				r_instance.rotation = $Camera3D/ShootLocation.global_rotation
				r_instance.rotation.x -= rad_to_deg(-90)
				r_instance.shooter = self
				var target = $Camera3D/Aim/Target.global_position
				
				var direction = (target - global_position).normalized()
				
				r_instance.velocity = direction  * 15
				
		if $Camera3D/Guns.get_node_or_null("Shotgun")!=null:
			if($Camera3D/Guns/Shotgun.visible):
				$Camera3D/Guns/Shotgun/AnimationPlayer.play("fire")
				reload_timer.start(0.5)
				can_shoot = false
				apply_shake(0.06)
				for shotgun_aim in shotgun_container.get_children():
					shotgun_aim.global_rotation_degrees.x += rng.randf_range(-b_spread,b_spread)
					shotgun_aim.global_rotation_degrees.y += rng.randf_range(-b_spread,b_spread)
					shotgun_aim.force_raycast_update()
					if(shotgun_aim.is_colliding()):
						
						if(shotgun_aim.get_collider().is_in_group("Player")):
							print("Player Hit")
							var hit_player = shotgun_aim.get_collider()
							hit_player.take_damage.rpc_id(hit_player.get_multiplayer_authority(),1)
						else:
							var b = BULLET_DECAL.instantiate()
							get_parent().add_child(b)
							b.global_position = shotgun_aim.get_collision_point()
							print(shotgun_aim.get_collision_point())
							var surface_dir_up = Vector3(0,1,0)
							var surface_dir_down = Vector3(0,-1,0)
							if shotgun_aim.get_collision_normal() == surface_dir_up:
								b.look_at(shotgun_aim.get_collision_point() + shotgun_aim.get_collision_normal(), Vector3.RIGHT)
							elif shotgun_aim.get_collision_normal() == surface_dir_down:
								b.look_at(shotgun_aim.get_collision_point() + shotgun_aim.get_collision_normal(), Vector3.RIGHT)
							else:
								b.look_at(shotgun_aim.get_collision_point() + shotgun_aim.get_collision_normal(), Vector3.DOWN)
					print(shotgun_aim.rotation_degrees)
					shotgun_aim.rotation_degrees = Vector3.ZERO
				
					
		
		
func alt_fire():
	if($Camera3D/Guns.get_child(0).visible):
		pass
	elif($Camera3D/Guns.get_child(1).visible):
		if(camera_3d.fov != og_fov):
			camera_3d.fov = og_fov
		else:
			camera_3d.fov = zoom_fov
		
			
@rpc("any_peer")		
func take_damage(damage : int) -> void:
	if not is_multiplayer_authority(): return
	
	health += -damage
	print(health)
	if(health <= 0):
		$DeathMenu.show()
		#$AnimationPlayer.play("death")

@rpc("any_peer")
func knockback(direction, force):
	velocity += direction * force

func _on_respawn_pressed() -> void:
	$DeathMenu.hide()
	alive = true
	#$AnimationPlayer.play("respawn")
	position = Global.spawn_points.pick_random()


func _on_quit_pressed() -> void:
	get_tree().quit()


func apply_shake(random_strength):
	shake_strength = random_strength
	
func random_offset():
	return Vector2(rng.randf_range(-shake_strength,shake_strength),rng.randf_range(-shake_strength,shake_strength))
	
func switch_weapon_up():
	
	camera_3d.fov = og_fov
	
	var guns = $Camera3D/Guns
	guns.get_child(current_weapon_index).hide()
	current_weapon_index += 1
	if(current_weapon_index >= guns.get_child_count()):
		current_weapon_index = 0
	guns.get_child(current_weapon_index).show()
	
func switch_weapon_down():
	
	camera_3d.fov = og_fov
	
	var guns = $Camera3D/Guns
	guns.get_child(current_weapon_index).hide()
	current_weapon_index -= 1
	if(current_weapon_index <= -1):
		current_weapon_index = guns.get_child_count()-1
	guns.get_child(current_weapon_index).show()


func _on_reload_timer_timeout() -> void:
	can_shoot = true


func add_weapon(weapon : String):
	var already = false
	for gun in $Camera3D/Guns.get_children():
		if weapon.split("/")[-1].split(".")[0].to_upper() == gun.name.to_upper():
			already = true
	if !already:
		var gun = load(weapon).instantiate()
		gun.position = $Camera3D/Guns.position
		gun.rotation_degrees.y = 90
		gun.hide()
		$Camera3D/Guns.add_child(gun)
	
