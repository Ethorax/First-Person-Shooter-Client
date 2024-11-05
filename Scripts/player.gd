extends CharacterBody3D

@onready var camera_3d: Camera3D = $Camera3D
@onready var aim: RayCast3D = $Camera3D/Aim
@onready var shotgun_container: Node3D = $Camera3D/ShotgunContainer



@onready var BULLET_DECAL = preload("res://Objects/bullet_decal.tscn")
@onready var rocket = preload("res://Objects/rocket.tscn")

#Camera Shake Variables
@export var randomStrength : float = 0.1
@export var shakeFade : float = 5.0
var rng = RandomNumberGenerator.new()
var shake_strength : float = 0.0


#PlayerModel Stuffs
@onready var player_model: Node3D = $playerModel
@onready var gun_hand: Marker3D = $playerModel/Chest/RightShoulder/RightBicep/RightForearm/RightHand/GunHand
@onready var chest: MeshInstance3D = $playerModel/Chest
@onready var chest_animator: AnimationPlayer = $"playerModel/Chest Animator"
@onready var pelvis_animator: AnimationPlayer = $"playerModel/Pelvis Animator"


#Movement Variables
const SPEED = 8.0
const JUMP_VELOCITY = 4.5

var direction
var isRunning := false
var speed := 8.0
var jump := 30.0
const GRAVITY := 2
var distanceFootstep := 0.0
var playFootstep := 3 #Lower if we want to play the sounds faster
var _delta := 0.0
var camBobSpeed := 10 #10 
var camBobUpDown := 1 #.5
var mouse_sense = 0.15
var mouse_locked : bool


#Water Variables
var in_water : bool = false
var swim_up_speed := 10.0
var wish_dir := Vector3.ZERO
var cam_aligned_wish_dir := Vector3.ZERO

#Cosmetic Variables
@export var color : Color = "ff0000"
var username = Global.char_name
@onready var username_label: Label3D = $username


var health : int = 100
var shield : int = 50
var alive : bool = true

#Gun Variables
var b_spread : float = 10.0
var og_fov : float = 75.0
var zoom_fov : float = 5.0
var current_weapon_index : int = 0
var can_shoot : bool = true
@onready var reload_timer: Timer = $ReloadTimer




func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())
	rng.randomize()
	
	
	
func _ready() -> void:
	#position = Global.spawn_points.pick_random().position
	if is_multiplayer_authority():
		#player_model.update_color(color)
		username_label.text = username
		update_health()
		$CanvasLayer.show()

func _physics_process(delta: float) -> void:
	
	
	if is_multiplayer_authority():
		#player_model.update_colors(color)
		username_label.text = username
		
		player_model.hide()
		chest.rotation = -camera_3d.rotation
		
		if velocity != Vector3.ZERO:
			pelvis_animator.play("Running")
		else:
			pelvis_animator.play("Idle")
		
		if !$CanvasLayer.visible:
			update_health()
			$CanvasLayer.show()
		
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
	
		if(Input.is_action_pressed("fire")):
			fire_gun()
			
	move_and_slide()
	
	
func _input(event):
	if is_multiplayer_authority():
		if event is InputEventMouseMotion:
			rotate_y(deg_to_rad(-event.relative.x*mouse_sense))
			camera_3d.rotate_x(deg_to_rad(-event.relative.y*mouse_sense))
			camera_3d.rotation.x = clamp(camera_3d.rotation.x, deg_to_rad(-89), deg_to_rad(89))
			
		if(event.is_action_pressed("weapon_switch_down")):
			switch_weapon_down()
		if(event.is_action_pressed("weapon_switch_up")):
			switch_weapon_up()
		
		if(event.is_action_pressed("alt_fire")):
			alt_fire()			
		if event.is_action_pressed("pause"):
			if $CanvasLayer/PauseMenu.visible:
				if !$DeathMenu.visible:
					Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
				
			
			
			$CanvasLayer/PauseMenu.visible = !$CanvasLayer/PauseMenu.visible
			
				
		if event.is_action_pressed("scoreboard"):
			$CanvasLayer/Scoreboard.show()
		if event.is_action_released("scoreboard"):
			$CanvasLayer/Scoreboard.hide()
	
func process_movement(delta):
	if !in_water:
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
	elif in_water:
		direction = Vector3.ZERO
		
		var h_rot = global_transform.basis.get_euler().y
		
		direction.x = -Input.get_action_strength("move_left")+Input.get_action_strength("move_right")
		direction.z = -Input.get_action_strength("move_forward")+Input.get_action_strength("move_back")
		direction = Vector3(direction.x,0,direction.z).rotated(Vector3.UP,h_rot).normalized()

		var actualSpeed = speed / 2 if !isRunning else speed
		
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
						hit_player.take_damage.rpc_id(hit_player.get_multiplayer_authority(),5)
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
						hit_player.take_damage.rpc_id(hit_player.get_multiplayer_authority(),10)
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
				#var r_instance = rocket.instantiate()
				
				#get_parent().add_child(r_instance)
				#r_instance.global_position = Vector3(aim.global_position.x,aim.global_position.y,aim.global_position.z-2)
				#r_instance.global_rotation.y = camera_3d.global_rotation.y
				#r_instance.global_rotation.x = rotation.x
				#r_instance.global_position = $Camera3D/ShootLocation.global_position
				#r_instance.rotation = $Camera3D/ShootLocation.global_rotation
				#r_instance.rotation.x -= rad_to_deg(-90)
				#r_instance.shooter = self
				var target = $Camera3D/Aim/Target.global_position
				#
				#var direction = (target - global_position).normalized()
				Server.add_rocket($Camera3D/ShootLocation.global_rotation,$Camera3D/ShootLocation.global_position,$Camera3D/Aim/Target.global_position,(target - global_position).normalized(),name)
				#r_instance.velocity = direction  * 15
				
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
							hit_player.take_damage.rpc_id(hit_player.get_multiplayer_authority(),5)
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
					#print(shotgun_aim.rotation_degrees)
					shotgun_aim.rotation_degrees = Vector3.ZERO

		if $Camera3D/Guns.get_node_or_null("Flamer")!=null:
			if($Camera3D/Guns/Flamer.visible):			
				$Camera3D/Guns/Flamer/AnimationPlayer.play("fire")
				
		
		
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
	update_health()
	print(health)
	if(health <= 0):
		$DeathMenu.show()
		$Camera3D/Guns.hide()
		player_model.hide()
		$CollisionShape3D.disabled = true
		
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		for gib in $Gibs.get_children():
			gib.emitting = true
		
		
		#$AnimationPlayer.play("death")

func knockback(direction, force):
	if not is_multiplayer_authority(): return
	velocity += direction * force

func _on_respawn_pressed() -> void:
	$DeathMenu.hide()
	$Camera3D/Guns.show()
	#$MeshInstance3D.show()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	health = 100
	update_health()
	alive = true
	player_model.show()
	$CollisionShape3D.disabled = false
	#$AnimationPlayer.play("respawn")
	global_position = Global.spawn_points.pick_random()
	
	

func _on_quit_pressed() -> void:
	get_tree().quit()


func apply_shake(random_strength):
	shake_strength = random_strength
	
func random_offset():
	return Vector2(rng.randf_range(-shake_strength,shake_strength),rng.randf_range(-shake_strength,shake_strength))
	
func switch_weapon_up():
	var guns = $Camera3D/Guns
	guns.get_child(current_weapon_index).hide()
	current_weapon_index += 1
	if(current_weapon_index >= guns.get_child_count()):
		current_weapon_index = 0
	guns.get_child(current_weapon_index).show()
	
	$"CanvasLayer/UI/Gun Selection/Gun Label".text = guns.get_child(current_weapon_index).name
	
func switch_weapon_down():
	var guns = $Camera3D/Guns
	guns.get_child(current_weapon_index).hide()
	current_weapon_index -= 1
	if(current_weapon_index <= -1):
		current_weapon_index = guns.get_child_count()-1
	guns.get_child(current_weapon_index).show()
	
	$"CanvasLayer/UI/Gun Selection/Gun Label".text = guns.get_child(current_weapon_index).name


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






func _on_resume_pressed() -> void:	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	$CanvasLayer/PauseMenu.hide()


func _on_settings_pressed() -> void:
	$CanvasLayer/Settings.show()


func _on_quit_menu_pressed() -> void:
	disconnect_from_game()


func _on_quit_desktop_pressed() -> void:
	disconnect_from_game()
	get_tree().quit()
	
func disconnect_from_game():
	Server.remove_player()
	
func update_health():
	$"CanvasLayer/UI/Shield/Shield Label".text = str(shield)
	$"CanvasLayer/UI/Health/Health Label".text = str(health)
	
func update_colors():
	player_model.get_node("Pelvis").material_override.albedo_color = color
