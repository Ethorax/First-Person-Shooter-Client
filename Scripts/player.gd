extends CharacterBody3D

@onready var camera_3d: Camera3D = $Camera3D
@onready var aim: RayCast3D = $Camera3D/Aim
@onready var shotgun_container: Node3D = $Camera3D/ShotgunContainer
#@onready var multiplayer_synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer



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

#Chat Variables
@onready var chat_input: LineEdit = $CanvasLayer/UI/Chat/ChatBox
@onready var v_scroll_bar: ScrollContainer = $CanvasLayer/UI/Chat/VScrollBar
@onready var v_box_container: VBoxContainer = $CanvasLayer/UI/Chat/VScrollBar/VBoxContainer
@onready var chat: Panel = $CanvasLayer/UI/Chat



#state machine
enum player_states{
	normal,
	chatting,
	dead,
	paused,
}
var player_state = player_states.normal


#Movement Variables
const JUMP_VELOCITY = 4.5

var direction
var isRunning := false
var speed := 12.0
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
# KEY : MELEE, PISTOL, SHOTGUN, SNIPER, FLAMER, BAZOOKA, GRENADEa
var weapons = [true,true,true,true,true,true,true,true]
var ammo_dict = {
	"sword" : 99999999999,
	"pistol" : 40,
	"shotgun" : 40,
	"sniper" : 40,
	"flamer" : 40,
	"bazooka" : 40,
	"magnum" : 40
 }
var gun_to_ammo = {
	"Sword" : "sword",
	"Pistol" : "pistol",
	"Shotgun" : "shotgun",
	"Sniper" : "sniper",
	"Flamer" : "flamer",
	"Bazooka" : "bazooka",
	"GrenadeLauncher" : "bazooka",
	"Magnum" : "magnum"
}
 

@onready var scoreboard: Control = $CanvasLayer/Scoreboard



func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())
	rng.randomize()
	
	
	
	
func _ready() -> void:
	#position = Global.spawn_points.pick_random().position
	#multiplayer_synchronizer.replication_config.add_property(name+":position")
	
	if is_multiplayer_authority():
		#player_model.update_color(color)
		username_label.text = username
		update_health()
		$CanvasLayer.show()

func _physics_process(delta: float) -> void:
	
	auto_disconnect_check()
	
	if is_multiplayer_authority():
		
		match player_state:
			player_states.normal:
		#$Camera3D/Guns.get_child(current_weapon_index).position = 
		
				hide_player()
				#player_model.update_colors(color)
				username_label.text = username
				
				#player_model.hide()
				#var temp_chest_rot = chest.rotation
				chest.rotation.x = -camera_3d.rotation.x
				
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
				
			player_states.paused:
				pass
			player_states.chatting:
				pass
				
				
				
			player_states.dead:
				pass	
	move_and_slide()
	
	
func _input(event):
	if is_multiplayer_authority():
		
		match player_state:
			player_states.normal:
		
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
				
				if event.is_action_pressed("chat"):
					player_state = player_states.chatting
					chat.show()
					Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
					chat_input.grab_focus()
					
					
	
			player_states.chatting:
				if Input.is_action_just_pressed("chat"):
					player_state = player_states.normal
					Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
					chat_input.release_focus()
					
					if !chat_input.text == "":
						Server.broadcast_chat(username,chat_input.text)
					
					
					chat_input.text = ""
					chat.hide()
				if Input.is_action_just_pressed("pause"):
					player_state = player_states.normal
					Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
					chat_input.release_focus()
					chat_input.text = ""
					chat.hide()
				
			player_states.dead:
				pass
			player_states.paused:
				pass
			
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
			velocity.x = lerp(velocity.x,direction.x * actualSpeed,0.25)
			velocity.z = lerp(velocity.z,direction.z * actualSpeed,0.25)
		else:
			velocity.x = lerp(velocity.x,direction.x * actualSpeed,0.01)
			velocity.z = lerp(velocity.z,direction.z * actualSpeed,0.01)


func fire_gun():
	if can_shoot and ammo_dict[gun_to_ammo.get($playerModel/Chest/Guns.get_child(current_weapon_index).name)] > 0:
		player_model.get_node("AudioController").get_node(str($playerModel/Chest/Guns.get_child(current_weapon_index).name)).play()
		chest_animator.stop()
		chest_animator.play("fire_"+$playerModel/Chest/Guns.get_child(current_weapon_index).name.to_lower())
		ammo_dict[gun_to_ammo.get($playerModel/Chest/Guns.get_child(current_weapon_index).name)] -= 1
		$"CanvasLayer/UI/Ammo/Ammo Label".text = str(ammo_dict.get(gun_to_ammo.get($playerModel/Chest/Guns.get_child(current_weapon_index).name)))

		if $playerModel/Chest/Guns.get_node_or_null("Sword"):
			$playerModel/Chest/Guns/Sword/AnimationPlayer.play("fire")
			reload_timer.start(0.9)
			can_shoot = false
		if $playerModel/Chest/Guns.get_node_or_null("Pistol") != null:
			if($playerModel/Chest/Guns.get_node("Pistol").visible):
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
						#hit_player.take_damage.rpc_id(hit_player.get_multiplayer_authority(),5,name)
						Server.hit_player(5,hit_player.name,name)
					else:
						var b = BULLET_DECAL.instantiate()
						get_parent().add_child(b)
						b.global_position = aim.get_collision_point()
						#print(aim.get_collision_point())
						var surface_dir_up = Vector3(0,1,0)
						var surface_dir_down = Vector3(0,-1,0)
						if aim.get_collision_normal() == surface_dir_up:
							b.look_at(aim.get_collision_point() + aim.get_collision_normal(), Vector3.RIGHT)
						elif aim.get_collision_normal() == surface_dir_down:
							b.look_at(aim.get_collision_point() + aim.get_collision_normal(), Vector3.RIGHT)
						else:
							b.look_at(aim.get_collision_point() + aim.get_collision_normal(), Vector3.DOWN)
				var pistol_anim = $playerModel/Chest/Guns/Pistol/AnimationPlayer as AnimationPlayer	
				pistol_anim.stop()
				pistol_anim.play("fire")
				#print(aim.rotation_degrees)
				aim.rotation_degrees = Vector3.ZERO
		if $playerModel/Chest/Guns.get_node_or_null("Sniper"):
			if($playerModel/Chest/Guns/Sniper.visible):
				apply_shake(0.02)
				reload_timer.start(0.5)
				can_shoot = false
				
				if(aim.is_colliding()):
					
					if(aim.get_collider().is_in_group("Player")):
						
						print(aim.get_collider().name)
						
						print("Player Hit")
						var hit_player = aim.get_collider()
						Server.hit_player(10,hit_player.name,name)
					else:
						var b = BULLET_DECAL.instantiate()
						get_parent().add_child(b)
						b.global_position = aim.get_collision_point()
						#print(aim.get_collision_point())
						var surface_dir_up = Vector3(0,1,0)
						var surface_dir_down = Vector3(0,-1,0)
						if aim.get_collision_normal() == surface_dir_up:
							b.look_at(aim.get_collision_point() + aim.get_collision_normal(), Vector3.RIGHT)
						elif aim.get_collision_normal() == surface_dir_down:
							b.look_at(aim.get_collision_point() + aim.get_collision_normal(), Vector3.RIGHT)
						else:
							b.look_at(aim.get_collision_point() + aim.get_collision_normal(), Vector3.DOWN)
				var sniper_anim = $playerModel/Chest/Guns/Sniper/AnimationPlayer as AnimationPlayer	
				sniper_anim.stop()
				sniper_anim.play("fire")
				#print(aim.rotation_degrees)
				aim.rotation_degrees = Vector3.ZERO
									
		if $playerModel/Chest/Guns.get_node_or_null("Bazooka")!=null:
			if($playerModel/Chest/Guns/Bazooka.visible):
				$playerModel/Chest/Guns/Bazooka/AnimationPlayer.play("fire")
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
				
		if $playerModel/Chest/Guns.get_node_or_null("Shotgun")!=null:
			if($playerModel/Chest/Guns/Shotgun.visible):
				$playerModel/Chest/Guns/Shotgun/AnimationPlayer.play("fire")
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
							Server.hit_player(5,hit_player.name,name)
						else:
							var b = BULLET_DECAL.instantiate()
							get_parent().add_child(b)
							b.global_position = shotgun_aim.get_collision_point()
							#print(shotgun_aim.get_collision_point())
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

		if $playerModel/Chest/Guns.get_node_or_null("Flamer")!=null:
			if($playerModel/Chest/Guns/Flamer.visible):			
				#$playerModel/Chest/Guns/Flamer/AnimationPlayer.play("fire")
				apply_shake(0.01)
				reload_timer.start(0.8)
				can_shoot = false
				var target = $Camera3D/Aim/Target.global_position
				#
				#var direction = (target - global_position).normalized()
				Server.add_fireball($Camera3D/ShootLocation.global_transform.basis.z*100,$Camera3D/ShootLocation.global_position,$Camera3D/Aim/Target.global_position,(target - global_position).normalized(),name)
						
				
		if $playerModel/Chest/Guns.get_node_or_null("GrenadeLauncher")!=null:
			if($playerModel/Chest/Guns/GrenadeLauncher.visible):			
				#$playerModel/Chest/Guns/Flamer/AnimationPlayer.play("fire")
				
				apply_shake(0.01)
				reload_timer.start(0.8)
				can_shoot = false
				var target = $Camera3D/Aim/Target.global_position
				#
				#var direction = (target - global_position).normalized()
				Server.add_grenade($Camera3D/ShootLocation.global_transform.basis.z*100,$Camera3D/ShootLocation.global_position,$Camera3D/Aim/Target.global_position,(target - global_position).normalized(),name)
				#r_instance.velocity = direction  * 15

		if $playerModel/Chest/Guns.get_node_or_null("Magnum")!=null:
			if($playerModel/Chest/Guns/Magnum.visible):			
				#$playerModel/Chest/Guns/Flamer/AnimationPlayer.play("fire")
				
				apply_shake(0.05)
				reload_timer.start(0.8)
				can_shoot = false
				
				aim.global_rotation_degrees.x += rng.randf_range(-b_spread,b_spread)
				aim.global_rotation_degrees.y += rng.randf_range(-b_spread,b_spread)
				aim.force_raycast_update()
				if(aim.is_colliding()):
					
					if(aim.get_collider().is_in_group("Player")):
						print("Player Hit")
						var hit_player = aim.get_collider()
						#hit_player.take_damage.rpc_id(hit_player.get_multiplayer_authority(),5,name)
						Server.hit_player(40,hit_player.name,name)
					else:
						var b = BULLET_DECAL.instantiate()
						get_parent().add_child(b)
						b.global_position = aim.get_collision_point()
						#print(aim.get_collision_point())
						var surface_dir_up = Vector3(0,1,0)
						var surface_dir_down = Vector3(0,-1,0)
						if aim.get_collision_normal() == surface_dir_up:
							b.look_at(aim.get_collision_point() + aim.get_collision_normal(), Vector3.RIGHT)
						elif aim.get_collision_normal() == surface_dir_down:
							b.look_at(aim.get_collision_point() + aim.get_collision_normal(), Vector3.RIGHT)
						else:
							b.look_at(aim.get_collision_point() + aim.get_collision_normal(), Vector3.DOWN)
				#var pistol_anim = $playerModel/Chest/Guns/Pistol/AnimationPlayer as AnimationPlayer	
				#pistol_anim.stop()
				#pistol_anim.play("fire")
				#print(aim.rotation_degrees)
				aim.rotation_degrees = Vector3.ZERO
				
		
func alt_fire():
	if($playerModel/Chest/Guns.get_node("Pistol").visible):
		pass
	elif($playerModel/Chest/Guns.get_node("Sniper").visible):
		if(camera_3d.fov != og_fov):
			camera_3d.fov = og_fov
		else:
			camera_3d.fov = zoom_fov
		
			
@rpc("any_peer")
func take_damage(damage : int,to : String = "1", from_id : String = "1") -> void:
	if not is_multiplayer_authority(): return
	var beginning_health = health
	shield += -(round(damage/3))*2
	if shield < 0 :
		health += shield
		shield = 0
		
	
	health += -(damage/3)
	#health += -damage
	update_health()
	print(health)
	
	
	
	if(health <= 0 and beginning_health > 0):
		Server.rpc_id(1,"frag", to,from_id)
		$DeathMenu.show()
		$playerModel/Chest/Guns.hide()
		player_model.hide()
		$CollisionShape3D.disabled = true
		print(str(to)+" was killed by " + from_id)
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		for gib in $Gibs.get_children():
			gib.emitting = true
		
		
		#$AnimationPlayer.play("death")

func knockback(direction, force):
	if not is_multiplayer_authority(): return
	velocity += direction * force

func _on_respawn_pressed() -> void:
	$DeathMenu.hide()
	$playerModel/Chest/Guns.show()
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
	var guns = $playerModel/Chest/Guns
	var anim = $"playerModel/Chest Animator"
	guns.get_child(current_weapon_index).hide()
	current_weapon_index += 1
	if(current_weapon_index >= guns.get_child_count()):
			current_weapon_index = 0
	while !weapons[current_weapon_index]:
		current_weapon_index += 1
		if(current_weapon_index >= guns.get_child_count()):
			current_weapon_index = 0
	
	guns.get_child(current_weapon_index).show()
	anim.play("hold_"+guns.get_child(current_weapon_index).name.to_lower())
	
	$"CanvasLayer/UI/Gun Selection/Gun Label".text = guns.get_child(current_weapon_index).name
	$"CanvasLayer/UI/Ammo/Ammo Label".text = str(ammo_dict.get(gun_to_ammo.get(guns.get_child(current_weapon_index).name)))
func switch_weapon_down():
	var guns = $playerModel/Chest/Guns
	var anim = $"playerModel/Chest Animator"
	guns.get_child(current_weapon_index).hide()
	current_weapon_index -= 1
	if(current_weapon_index <= -1):
		current_weapon_index = guns.get_child_count()-1
	while !weapons[current_weapon_index]:
		current_weapon_index -= 1
		if(current_weapon_index <= -1):
			current_weapon_index = guns.get_child_count()-1
	
	guns.get_child(current_weapon_index).show()
	anim.play("hold_"+guns.get_child(current_weapon_index).name.to_lower())
	
	
	$"CanvasLayer/UI/Gun Selection/Gun Label".text = guns.get_child(current_weapon_index).name
	$"CanvasLayer/UI/Ammo/Ammo Label".text = str(ammo_dict.get(gun_to_ammo.get(guns.get_child(current_weapon_index).name)))


func _on_reload_timer_timeout() -> void:
	can_shoot = true

func add_weapon(weapon_index : int):
	if is_multiplayer_authority():
		if !weapons[weapon_index]:
			weapons[weapon_index] = true
		


func add_ammo(amount, type):
	
	if type == "health":
		health += amount
		if health > 100:
			health = 100
		$"CanvasLayer/UI/Health/Health Label".text = str(health)
		
	elif type == "armor":
		shield += amount
		if shield > 100:
			shield = 100
		$"CanvasLayer/UI/Shield/Shield Label".text = str(shield)
	else:
		ammo_dict[type] += amount
		
		$"CanvasLayer/UI/Ammo/Ammo Label".text = str(ammo_dict.get(gun_to_ammo.get($playerModel/Chest/Guns.get_child(current_weapon_index).name)))

	



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
	player_model.get_node("Pelvis/RightThigh").material_override.albedo_color = color
	player_model.get_node("Pelvis/LeftThigh").material_override.albedo_color = color
	player_model.get_node("Pelvis/RightThigh/RightKnee/RightShin").material_override.albedo_color = color
	player_model.get_node("Pelvis/LeftThigh/LeftKnee/LeftShin").material_override.albedo_color = color
	player_model.get_node("Chest/RightShoulder/RightBicep").material_override.albedo_color = color
	player_model.get_node("Chest/RightShoulder/RightBicep/RightForearm").material_override.albedo_color = color
	player_model.get_node("Chest/RightShoulder/RightBicep/RightForearm/RightHand").material_override.albedo_color = color
	player_model.get_node("Chest/RightShoulder/RightBicep/RightForearm/RightHand/RightThumb").material_override.albedo_color = color

	player_model.get_node("Chest/LeftShoulder/LeftBicep").material_override.albedo_color = color
	player_model.get_node("Chest/LeftShoulder/LeftBicep/LeftForearm").material_override.albedo_color = color
	player_model.get_node("Chest/LeftShoulder/LeftBicep/LeftForearm/LeftHand").material_override.albedo_color = color
	player_model.get_node("Chest/LeftShoulder/LeftBicep/LeftForearm/LeftHand/LeftThumb").material_override.albedo_color = color
	player_model.get_node("Chest/Neck/Head/Cube_049").material_override.albedo_color = color


func box_container_child_entered_tree(node: Node) -> void:
	chat.show()
	$chat_timer.start(5)
	v_scroll_bar.get_v_scroll_bar().value = v_scroll_bar.get_v_scroll_bar().max_value


func _on_chat_timer_timeout() -> void:
	chat.hide()


func hide_player():
	
	
	player_model.get_node("Pelvis").set_layer_mask_value(1,false)
	player_model.get_node("Pelvis/RightThigh").set_layer_mask_value(1,false)
	player_model.get_node("Pelvis/LeftThigh").set_layer_mask_value(1,false)
	player_model.get_node("Pelvis/RightThigh/RightKnee/RightShin").set_layer_mask_value(1,false)
	player_model.get_node("Pelvis/LeftThigh/LeftKnee/LeftShin").set_layer_mask_value(1,false)
	player_model.get_node("Chest/RightShoulder/RightBicep").set_layer_mask_value(1,false)
	player_model.get_node("Chest/RightShoulder/RightBicep/RightForearm").set_layer_mask_value(1,false)
	player_model.get_node("Chest/RightShoulder/RightBicep/RightForearm/RightHand").set_layer_mask_value(1,false)
	player_model.get_node("Chest/RightShoulder/RightBicep/RightForearm/RightHand/RightThumb").set_layer_mask_value(1,false)

	player_model.get_node("Chest/LeftShoulder/LeftBicep").set_layer_mask_value(1,false)
	player_model.get_node("Chest/LeftShoulder/LeftBicep/LeftForearm").set_layer_mask_value(1,false)
	player_model.get_node("Chest/LeftShoulder/LeftBicep/LeftForearm/LeftHand").set_layer_mask_value(1,false)
	player_model.get_node("Chest/LeftShoulder/LeftBicep/LeftForearm/LeftHand/LeftThumb").set_layer_mask_value(1,false)
	player_model.get_node("Chest/Neck/Head/Cube_049").set_layer_mask_value(1,false)
	$playerModel/Chest/LeftShoulder.set_layer_mask_value(1,false)
	$playerModel/Chest/RightShoulder.set_layer_mask_value(1,false)
	$playerModel/Chest/Neck/Head.set_layer_mask_value(1,false)
	$playerModel/Chest/Neck.set_layer_mask_value(1,false)
	$playerModel/Chest.set_layer_mask_value(1,false)
	$playerModel/Pelvis/LeftThigh/LeftKnee/LeftShin/LeftFoot.set_layer_mask_value(1,false)
	$playerModel/Pelvis/LeftThigh/LeftKnee.set_layer_mask_value(1,false)
	$playerModel/Pelvis/RightThigh/RightKnee/RightShin/RightFoot.set_layer_mask_value(1,false)
	$playerModel/Pelvis/RightThigh/RightKnee.set_layer_mask_value(1,false)
	




func update_scores(names,colors,frags):
	
	
	if is_multiplayer_authority():
	
		var is_first = true
		for info in scoreboard.get_child(2).get_children():
			if is_first:
				is_first=false
			else:
				info.queue_free()
		
		
		for i in names.size():
			var player_info = preload("res://Objects/UI/player_info.tscn")
			var info_instance = player_info.instantiate()
			
			info_instance.frags = int(frags[i])
			info_instance.username = names[i]
			info_instance.color = colors[i]
			info_instance.placing = str(i+1)
			
			scoreboard.get_child(2).add_child(info_instance)
		
	


func auto_disconnect_check():
	
	if username == "USERNAME":
		var old_position = position
		await get_tree().creat_timer(3).timeout
		if old_position == position:
			disconnect_from_game()

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.get_multiplayer_authority() != get_multiplayer_authority():
		Server.hit_player(30,str(body.get_multiplayer_authority()),str(get_multiplayer_authority()))
