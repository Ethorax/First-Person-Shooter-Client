extends CharacterBody3D

#cosmetic information
@export var color : Color
@export var username: String
@export var helm_index : int

@export var score := 0
var old_score
var kill_combo = 0
var last_kill = -1
var game_point = false
@export var kill_streak := 0
var killing_spree = false
var rampage = false
var unkillable = false
var killdozer = false
var double = false
var triple = false
var oh_shit = false


@export var speed := 12.0
@export var input: PlayerInput

@onready var rollback_synchronizer = $RollbackSynchronizer
var peer_id = 0

var gravity := 9.8

var last_shooter : int = 0
@onready var hitmarker: TextureRect = $Crosshair/Hitmarker


##BAD VARIABLE PLEASE WORK
var can_switch := false
var last_switch := -1
var last_alt := -1

const JUMP_VELOCITY := 5.0
#const SPEED := 20
var in_water : bool = false

@export var health := 100
var max_health := 100
var old_health
@export var armor := 100
var max_armor := 100

@export var death_tick : int = -1
@export var respawn_position : Vector3
var did_respawn := false

@export var player_id : int

@export var _player_input : BaseNetInput
@export var _camera_input : Camera3D
@export var _player_model : Node3D
@export var _state_machine: RewindableStateMachine

@onready var gen_anim: AnimationPlayer = $GenAnim
@onready var leg_anim: AnimationPlayer = $LegAnim
@onready var arm_anim: AnimationPlayer = $ArmAnim


@onready var projectile: NetworkWeapon3D = %Weapons/Projectile
@onready var hitscan: NetworkWeaponHitscan3D = %Weapons/Hitscan

var buffered_force := Vector3.ZERO

#CAM FLAVOR VARIABLES
var camBobSpeed := 10.0 #10 
var camBobUpDown := 0.001 #.5
var _delta := 0.0
var og_cam_pos

#WEAPON VARIABLES
# KEY : MELEE, PISTOL, SHOTGUN, GATLING, SNIPER, FLAMER, BAZOOKA, GRENADE, MAGNUM, ENERGY

@export var weapon_index := 0
@export var weapon_inventory = [true,true,false,false,false,false,false,false,false,false]
#@export var weapon_inventory = [true,true,true,true,true,true,true,true,true,true]

var ammo_dict = {
	"sword" : 99999999999,
	"pistol" : 50,
	"shotgun" : 20,
	"sniper" : 15,
	"flamer" : 35,
	"bazooka" : 15,
	"magnum" : 15,
	"energy" : 50
 }

var ammo_limits = {
	"sword" : 99999999999,
	"pistol" : 200,
	"shotgun" : 50,
	"sniper" : 30,
	"bazooka" : 50,
	"flamer" : 75,
	"magnum" : 30,
	"energy" : 150
}


func _enter_tree() -> void:
	
	set_multiplayer_authority(1)
	
	player_id = int(name)
	#set_multiplayer_authority(player_id,true)
	input.set_multiplayer_authority(player_id,true)
	#$Camera3D.set_multiplayer_authority(player_id,false)
	$Camera3D/Weapons/Hitscan.exclude.append(get_rid())
	

func _ready():
  # Wait a frame so peer_id is set
	await get_tree().process_frame
	NetworkTime.on_tick.connect(_tick)
	
	input.respawn_hit = true
	
	#TODO apply settings
	$Camera3D.fov = Global.fov
	input.mouse_sensitivity = Global.mouse_sense
	if input.is_multiplayer_authority(): input.mouse_sensitivity = Global.mouse_sense
	
	og_cam_pos = $Camera3D.position
	$Username.text = username
	
	old_health = health
	old_score = score
	
  # Set owner
	#set_multiplayer_authority(1)
	#input.set_multiplayer_authority(peer_id)
	rollback_synchronizer.process_settings()
	if input.is_multiplayer_authority():
		$Camera3D.current = true
		$Skeleton3D/Neck_001.cast_shadow = MeshInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
		#$Skeleton3D/Neck_001.set_layer_mask_value(1,false)
		$Username.hide()
		$CanvasLayer.show()
		$Crosshair.show()
		
		
	# Default state
	_state_machine.state = &"IdleState"
	#_animation_player = _player_model.get_node("AnimationPlayer")
	
	# TODO: can this be moved to movement_state
	_state_machine.on_display_state_changed.connect(_on_display_state_changed)

	# Call this after setting authority
	# https://foxssake.github.io/netfox/netfox/tutorials/responsive-player-movement/#ownership
	rollback_synchronizer.process_settings()
	
	# Hide the loading screen once our player is spawned in game and ready
	#if multiplayer.get_unique_id() == str(name).to_int():
		#%NetworkManager.hide_loading()

func _on_display_state_changed(old_state, new_state):
	# print("Old state %s, new %s" % [old_state, new_state])
	
	var animation_name = new_state.animation_name
	if leg_anim && animation_name != "":
		# print("Play animation %s" % animation_name)
		leg_anim.play(animation_name)


func _rollback_tick(delta, tick, is_fresh):
	_force_update_is_on_floor()
	
	#if tick == death_tick:
		#####TODO get random respawn point
		#global_position = respawn_position
		#did_respawn = true
	#else:
		#did_respawn = false
	
	if input.alt_fire and NetworkTime.seconds_between(last_alt,NetworkTime.tick) > 0.5:
		last_alt = NetworkTime.tick
		alt_fire()
	
	
	if input.respawn_hit:
		health = max_health
		armor = 50
		#await get_tree().create_timer(1).timeout
		if !respawn_position:
			respawn_position = Global.spawn_points.pick_random()
		elif Global.spawn_points:
			respawn_position = Global.spawn_points.pick_random()
		global_position = respawn_position
		weapon_index = 1
		$DeathMenu.hide()
		#$Skeleton3D.show()
		
		weapon_inventory = [true,true,false,false,false,false,false,false,false,false]
		input.respawn_hit = false
		ammo_dict = {
		"sword" : 99999999999,
		"pistol" : 50,
		"shotgun" : 20,
		"sniper" : 15,
		"flamer" : 35,
		"bazooka" : 15,
		"magnum" : 15,
		"energy" : 50
 }
		
		if input.is_multiplayer_authority():
			input.respawn_hit = false
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
	
	if is_on_floor() or in_water:
		if input.jump_input:
			velocity.y = JUMP_VELOCITY
		else:
			velocity.y -= gravity * delta / 3
	else:
		velocity.y -= gravity * delta
	
	
	
	#if !is_multiplayer_authority(): return
	if input.switch_weapon_down and input.can_switch:
		switch_weapon_down()
		input.can_switch = false
		#input.switch_weapon_down = false
	if input.switch_weapon_up and input.can_switch:
		switch_weapon_up()
		input.can_switch = false
		#input.switch_weapon_up = false
		
	
	if input.one and weapon_inventory[0]:
		weapon_index = 0
	if input.two and weapon_inventory[1]:
		weapon_index = 1
	if input.three and weapon_inventory[2]:
		weapon_index = 2
	if input.four and weapon_inventory[3]:
		weapon_index = 3
	if input.five and weapon_inventory[4]:
		weapon_index = 4
	if input.six and weapon_inventory[5]:
		weapon_index = 5
	if input.seven and weapon_inventory[6]:
		weapon_index = 6
	if input.eight and weapon_inventory[7]:
		weapon_index = 7
	if input.nine and weapon_inventory[8]:
		weapon_index = 8
	if input.zero and weapon_inventory[9]:
		weapon_index = 9

	
	rotate_object_local(Vector3(0,1,0), input.look_angle.x)
	%Camera3D.rotate_object_local(Vector3(1, 0, 0), input.look_angle.y)
	%Camera3D.rotation.x = clamp(%Camera3D.rotation.x, -1.57, 1.57)
	%Camera3D.rotation.z = 0
	%Camera3D.rotation.y = 0

func _apply_movement_from_input(delta):
	_force_update_is_on_floor()
	
	

func _force_update_is_on_floor():
	var old_velocity = velocity
	velocity = Vector3.ZERO
	move_and_slide()
	velocity = old_velocity
	#var direction = ($Camera3D.basis * Vector3(input.movement.x,0,input.movement.z)).normalized()
	#if direction:
		#velocity.x = direction.x * speed
		#velocity.z = direction.z * speed 
	
			

	var input_dir = input.movement
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.z)).normalized()
	if direction and is_on_floor():
		velocity.x = move_toward(velocity.x,direction.x * speed, 1.0)
		velocity.z = move_toward(velocity.z,direction.z * speed,1.0)
	elif is_on_floor():
		velocity.x = move_toward(velocity.x, 0, 0.8)
		velocity.z = move_toward(velocity.z, 0, 0.8)	
	elif direction and !is_on_floor():
		velocity.x = move_toward(velocity.x,direction.x * speed, 0.5)
		velocity.z = move_toward(velocity.z,direction.z * speed,0.5)
	else:
		velocity.x = move_toward(velocity.x, 0, 0.1)
		velocity.z = move_toward(velocity.z, 0, 0.1)
		
	
	
	
	if is_multiplayer_authority():
		velocity += buffered_force
		buffered_force = Vector3.ZERO
	velocity *= NetworkTime.physics_factor
	#print(velocity)
	move_and_slide()
	velocity /= NetworkTime.physics_factor
	

func _process(delta):
	_delta += delta
	update_UI.call_deferred()
	weapon_check()
	process_animations()
	
	hitmarker.modulate.a -= 0.01
	
	if !$Audio/Music.playing and input.is_multiplayer_authority():
			$Audio/Music.go_mode()
	
	username = input.username
	color = input.color
	$Username.text = username
	$Skeleton3D/Neck_001.get_surface_override_material(1).albedo_color = color
	if !input.is_multiplayer_authority():
		#$Skeleton3D/Head/Helmets.get_children():
		for helm in $Skeleton3D/Head/Helmets.get_children():
			helm.hide()
		$Skeleton3D/Head/Helmets.get_child(input.helmet_index).show()
		$Skeleton3D/Head/Helmets.get_child(input.helmet_index).get_child(0).get_surface_override_material(0).albedo_color = input.color
	
	var bob_amount = (sin(_delta*10)* camBobUpDown*4) * Vector3.UP
			#print(bob_amount)
			#print(_delta)
	if input.movement != Vector3.ZERO and is_on_floor():
		#print(delta)
		$Camera3D.position += bob_amount
	elif og_cam_pos:
		$Camera3D.position = og_cam_pos
	
	if old_health != health:
		if old_health > health:
			leave_blood(1)
			$Audio/Hurt.play()
			gen_anim.stop()
			gen_anim.play("hurt")
		old_health = health
		
	if old_score != score:
		if old_score < score:
			last_kill = NetworkTime.tick
			if NetworkTime.seconds_between(last_kill,NetworkTime.tick) <= 5.0:
				kill_combo += 1
				if !double and kill_combo >= 2:
					$Audio/Announcer/double_kill.play()
					double = true
				elif !triple and kill_combo >= 3:
					$Audio/Announcer/triple_kill.play()
					triple = true
				elif !oh_shit and kill_combo >= 4:
					oh_shit = true
					$Audio/Announcer/oh_shit.play()
			
			else:
				last_kill = -1
				kill_combo = 0
				double = false
				triple = false
				oh_shit = false
		old_score = score
		
	
func apply_gravity(delta):
	velocity.y -= gravity * delta
	
func take_damage(damage : int, player : int = 0):
	#print( get_multiplayer_authority())
	$Audio/Hurt.play()
	if is_multiplayer_authority():
		$DamageTimer.stop()
		$DamageTimer.start()
		var beginning_health = health
		armor += -(round(damage/3.0))*2
		if armor < 0 :
			health += armor
			armor = 0
		
	
		health += -(damage/3.0)
		#health += -damage
			
		#health -= damage
		update_UI()
		
		if player > 0:
			last_shooter = player
			print(str(name) + "was shot by " + str(player))
		
		if health <= 0:
			_state_machine.state = &"DieState"
	#NetworkRollback.mutate(self)
	
func update_UI():
	var weapons = $"Skeleton3D/Weapon hand/Weapons"
	$"CanvasLayer/UI/Health/Health Label".text = str(health)
	$"CanvasLayer/UI/Shield/Shield Label".text = str(armor)

	$"CanvasLayer/UI/Gun Selection/Gun Label".text = str(weapons.get_child(weapon_index).name)
	var gun_data =  weapons.get_child(weapon_index).gun_data as GunData
	$"CanvasLayer/UI/Ammo/Ammo Label".text = str(ammo_dict[gun_data.ammo_type])
	
	update_scoreboard()
	

func switch_weapon_up():
	if !is_multiplayer_authority(): return
	var weapons = $"Skeleton3D/Weapon hand/Weapons"
	var weapon_data = weapons.get_child(weapon_index).gun_data as GunData
	can_switch = NetworkTime.seconds_between(last_switch,NetworkTime.tick) > 0.05

	if can_switch:
		print("weapon switch")
		
		
		for gun in weapons.get_children():
			gun.hide()
		weapon_index += 1
		if weapon_index > weapons.get_children().size()-1:
			weapon_index = 0
		while !weapon_inventory[weapon_index]:
			weapon_index += 1
			if(weapon_index >= weapons.get_child_count()):
				weapon_index = 0
		
		
		
		arm_anim.play("hold_"+ str(weapon_data.hold_pose))
		hitscan.fire_rate = weapon_data.fire_rate
		hitscan.fire_sound = weapon_data.fire_sound
		hitscan.projectile = weapon_data.projectile
		
		projectile.fire_rate = weapon_data.fire_rate
		projectile.fire_sound = weapon_data.fire_sound
		projectile.projectile = weapon_data.projectile
		
		weapons.get_child(weapon_index).show()
		last_switch = NetworkTime.tick
	
	
	
func switch_weapon_down():
	#if !is_multiplayer_authority(): return
	
	can_switch = NetworkTime.seconds_between(last_switch,NetworkTime.tick) > 0.05

	
	if can_switch:
		var weapons = $"Skeleton3D/Weapon hand/Weapons"
		for gun in weapons.get_children():
			gun.hide()
		weapon_index -= 1
		if weapon_index < 0:
			weapon_index = weapons.get_children().size()-1
		while !weapon_inventory[weapon_index]:
			weapon_index -= 1
			if(weapon_index <= -1):
				weapon_index = weapons.get_child_count()-1
		

		
		#TODO Change the network weapon stats
		var weapon_data = weapons.get_child(weapon_index).gun_data as GunData
		arm_anim.play("hold_"+ str(weapon_data.hold_pose))
		
		hitscan.fire_rate = weapon_data.fire_rate
		hitscan.fire_sound = weapon_data.fire_sound
		hitscan.projectile = weapon_data.projectile
		
		projectile.fire_rate = weapon_data.fire_rate
		projectile.fire_sound = weapon_data.fire_sound
		projectile.projectile = weapon_data.projectile	
		
		
		weapons.get_child(weapon_index).show()
		
		if input.is_multiplayer_authority():
			input.can_switch = false
		last_switch = NetworkTime.tick
	
	
func weapon_check():
	var weapons = $"Skeleton3D/Weapon hand/Weapons"
	for gun in weapons.get_children():
		gun.hide()
		
	var weapon_data = weapons.get_child(weapon_index).gun_data
	
	if weapon_index != 4:
		$Camera3D.fov = Global.fov
		input.mouse_sensitivity = Global.mouse_sense
	
	
	hitscan.fire_rate = weapon_data.fire_rate
	hitscan.fire_sound = weapon_data.fire_sound
	hitscan.projectile = weapon_data.projectile
	hitscan.damage = weapon_data.damage
	hitscan.b_spread = weapon_data.spread
	
	projectile.fire_rate = weapon_data.fire_rate
	projectile.fire_sound = weapon_data.fire_sound
	projectile.projectile = weapon_data.projectile	
	projectile.damage = weapon_data.damage
	if arm_anim.current_animation.contains("hold") or arm_anim.current_animation == "":
		arm_anim.play("hold_"+ str(weapon_data.hold_pose))
	weapons.get_child(weapon_index).show()
	
	var inventory_container = $CanvasLayer/UI/Inventory/InventoryContainer
	
	for i in inventory_container.get_children().size():
		i = i - 1
		
		if weapon_inventory[i]:
			var visual_slot = inventory_container.get_child(i) as TextureRect
			visual_slot.get_child(0).modulate = Color(1,1,1,1.00)
		else:
			var visual_slot = inventory_container.get_child(i) as TextureRect
			visual_slot.get_child(0).modulate = Color(0.2,0.2,0.2,1.00)
		inventory_container.get_child(i).self_modulate = Color(0.2,0.2,0.2,1.00)
			
	inventory_container.get_child(weapon_index).self_modulate = Color(1,1,1,1)
	
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("scoreboard"):
		$CanvasLayer/Scoreboard.show()
	if event.is_action_released("scoreboard"):
		$CanvasLayer/Scoreboard.hide()
	if event.is_action_pressed("pause"):
		$CanvasLayer/PauseMenu.visible = !$CanvasLayer/PauseMenu.visible
		if !$CanvasLayer/PauseMenu.visible:
			if input.is_multiplayer_authority():
				if !$DeathMenu.visible:
					input.override_mouse = false
					Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			
		if $CanvasLayer/PauseMenu.visible:
			if input.is_multiplayer_authority():
				input.override_mouse = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			
func knockback(vector : Vector3, override: bool = false):
	if is_multiplayer_authority():
		
		if override:
			velocity = Vector3.ZERO
			buffered_force = Vector3.ZERO
		
		buffered_force = vector
		#print(buffered_force)
		
func add_ammo(ammo_type:String = "pistol",amount:int = 0):
	#var gun_data =  weapons.get_child(weapon_index).gun_data as GunData
	ammo_dict[ammo_type] += amount
	if ammo_dict[ammo_type] > ammo_limits[ammo_type]:
		ammo_dict[ammo_type] = ammo_limits[ammo_type]


func _on_respawn_pressed() -> void:
	if input.is_multiplayer_authority():
		input.override_mouse = false
	

func die():
	if !is_multiplayer_authority(): return
	death_tick = NetworkTime.tick
	respawn_position = Global.spawn_points.pick_random()
	weapon_index = 1
	print(str(input.get_multiplayer_authority()) +" was killed by " + str(last_shooter))
	if get_parent().get_node(str(last_shooter)):
		message(username + " was killed by "+get_parent().get_node(str(last_shooter)).username)
	else:
		message(username + " was killed by world")
	if last_shooter > 0 and int(input.get_multiplayer_authority()) != int(last_shooter):
		get_parent().get_node(str(last_shooter)).score += 1
		get_parent().get_node(str(last_shooter)).kill_streak += 1
	else:
		score -= 1
	kill_streak = 0


func _tick(dt: float, tick: int):
	if health <= 0:
		#TODO: DEATH SOUND PLAYS
		#TODO: ADD TO THE SCOREBOARD
		
		if $Skeleton3D.visible:
			leave_blood(2.0)
			for gib in $Gibs.get_children():
				if gib is CPUParticles3D and $Skeleton3D.visible:
					gib.emitting = true
		
		if input.is_multiplayer_authority() and !$DeathMenu.visible:
			$DeathMenu.show()
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			$Audio/Death.play()
			killing_spree = false
			rampage = false
			unkillable = false
			killdozer = false
		if $Skeleton3D.visible:
			die()
		$Skeleton3D.hide()
	else:
		$Skeleton3D.show()

func respawn():
	if not is_multiplayer_authority(): return
	respawn_position = Global.spawn_points.pick_random()
	position = respawn_position
	health = 100
	armor = 50


func _on_resume_pressed() -> void:
	$CanvasLayer/PauseMenu.hide()
	$CanvasLayer/Settings.hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if input.is_multiplayer_authority():
		input.override_mouse = false


func _on_quit_menu_pressed() -> void:
	if get_parent().get_parent().get_node("NetworkManager"):
		get_parent().get_parent().get_node("NetworkManager").return_to_menu()


func _on_settings_pressed() -> void:
	$CanvasLayer/Settings.show()


func _on_quit_desktop_pressed() -> void:
	get_tree().quit()
	


func process_animations():
	if !is_on_floor():
		leg_anim.play("Jump")
	elif velocity.x != 0 or velocity.z != 0:
		leg_anim.play("Run",-1,2.5)
	else:
		leg_anim.stop()
		leg_anim.play("RESET")

func update_scoreboard():
	if !input.is_multiplayer_authority(): return
	var player_node = get_parent()
	var scoreboard = $CanvasLayer/Scoreboard/VBoxContainer
	var info = load("res://Objects/UI/player_info.tscn")
	var first = true
	for child in scoreboard.get_children():
		if first:
			first = false
		else:
			child.queue_free()
			
	var players = player_node.get_children()
	players.sort_custom( func(a,b): return a.score < b.score )
	players.reverse()
	
			
	for player in players:
		var info_instance = info.instantiate()
		info_instance.username = player.username
		info_instance.frags = player.score
		info_instance.color = player.color
		info_instance.killstreak = player.kill_streak
		scoreboard.add_child(info_instance)
		
		if player.score >= get_parent().get_parent().kill_limit and !get_parent().get_parent().round_end:
			get_parent().get_parent().round_end = true
			$Audio/Announcer/game.play()
			if player.username == username: message(player.username + " WON!")
			$CanvasLayer/Scoreboard.show()
			if is_multiplayer_authority(): get_parent().get_parent().finish_round()
		
		if !player.game_point and player.score == get_parent().get_parent().kill_limit - 1 and !get_parent().get_parent().round_end:
			$Audio/Announcer/game_point.play()
			if !get_parent().get_parent().round_end and game_point != true:
				player.game_point = true
				message(player.username + " is at game point!")
		elif player.game_point and player.score != get_parent().get_parent().kill_limit - 1:
			player.game_point = false
		
		if kill_streak >= 5 and !killing_spree:
			$Audio/Announcer/killing_spree.play()
			message(username + " is on a killing spree")
			killing_spree = true
		if kill_streak >= 10 and !rampage:
			$Audio/Announcer/rampage.play()
			message(username + " is on a rampage!")
			rampage = true
		if kill_streak >= 15 and !unkillable:
			$Audio/Announcer/unkillable.play()
			unkillable = true
			message(username + " is unkillable!")
		if kill_streak >= 20 and !killdozer:
			$Audio/Announcer/killdozer.play()
			killdozer = true
			message(username + " is a KILLDOZER!!!")
			
			
			
		
func apply_settings():
	$Camera3D.fov = Global.fov
	if input.is_multiplayer_authority(): input.mouse_sensitivity = Global.mouse_sense



func _on_damage_timer_timeout() -> void:
	if !is_multiplayer_authority(): return
	if last_shooter:
		last_shooter = 0
		

func alt_fire():
	var weapon = $"Skeleton3D/Weapon hand/Weapons".get_child(weapon_index)
	if weapon.name == "Sniper":
		if $Camera3D.fov == Global.fov:
			$Camera3D.fov = Global.fov / 4.0
			input.mouse_sensitivity = Global.mouse_sense / 4.0
		else:
			$Camera3D.fov = Global.fov
			input.mouse_sensitivity = Global.mouse_sense



func message(text:String):
	
	if !input.is_multiplayer_authority(): return
	var chat_node = $CanvasLayer/UI/Chat
	chat_node.rpc("add_chat", text)
	
	
func leave_blood(scale_mod):
	var blood_instance = load("res://Objects/Gibs/blood_splatter.tscn").instantiate()
	
	
	var blood_pointer: RayCast3D = $Gibs/BloodPointer

	blood_instance.scale = blood_instance.scale * scale_mod
	
	blood_instance.scale.z = 1
	
	#print(aim.get_collision_point())
	var surface_dir_up = Vector3(0,1,0)
	var surface_dir_down = Vector3(0,-1,0)
	print(blood_pointer.get_collision_normal())
	
	blood_instance.rotation_degrees.x = blood_pointer.get_collision_normal().y * 90
	#if blood_pointer.get_collision_normal() == surface_dir_up:
		#blood_instance.look_at(blood_pointer.get_collision_point() + blood_pointer.get_collision_normal(), Vector3.RIGHT)
	#elif blood_pointer.get_collision_normal() == surface_dir_down:
		#blood_instance.look_at(blood_pointer.get_collision_point() + blood_pointer.get_collision_normal(), Vector3.RIGHT)
	#else:
		#blood_instance.look_at(blood_pointer.get_collision_point() + blood_pointer.get_collision_normal(), Vector3.DOWN)
	
	#get_tree().root.get_node("Client").get_child(2).add_child(blood_instance)
	get_tree().get_nodes_in_group("map")[0].add_child(blood_instance)
	blood_instance.global_position = blood_pointer.get_collision_point()
