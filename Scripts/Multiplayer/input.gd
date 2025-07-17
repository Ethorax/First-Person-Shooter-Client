extends Node
class_name PlayerInput

@export var username : String
@export var color : Color = Color(0,0,0)
@export var helmet_index : int = 0

var movement: Vector3 = Vector3.ZERO
var jump_input := false
var fire := false
var alt_fire := false
var switch_weapon_up := false
var switch_weapon_down := false

var respawn_hit := true

var last_switch = -1
var can_switch = true

var one := false
var two := false
var three := false
var four := false
var five := false
var six := false
var seven := false
var eight := false
var nine := false
var zero := false

@onready var camera_3d: Camera3D = %Camera3D

var mouse_rotation: Vector2 = Vector2.ZERO
var look_angle: Vector2 = Vector2.ZERO
@export var mouse_sensitivity: float = 1.0
var is_setup: bool = false
var override_mouse: bool = false

#func _ready() -> void:



func _notification(what):
	pass
	#if what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		#if get_parent().health > 0:
			#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			#override_mouse = false

func _gather():
	#respawn_hit = false
	#print(movement)
	if !is_multiplayer_authority():
		return
	if !get_parent().get_node("DeathMenu").visible:
		movement = Vector3(
			Input.get_axis("move_left", "move_right"),
			#Input.get_action_strength("ui_accept"),
			0,
			Input.get_axis("move_forward", "move_back")
			)
	else:
		movement = Vector3.ZERO
	#movement = (%Camera3D.transform.basis * Vector3(movement.x, 0, movement.z)).normalized()
	if !get_parent().get_node("DeathMenu").visible and !get_parent().get_node("CanvasLayer/PauseMenu").visible:
		jump_input = Input.is_action_pressed("jump")
		fire = Input.is_action_pressed("fire")
		alt_fire = Input.is_action_pressed("alt_fire")
	else:
		jump_input = false
		fire = false
		alt_fire = false
	switch_weapon_down = Input.is_action_just_pressed("weapon_switch_down")
	switch_weapon_up = Input.is_action_just_pressed("weapon_switch_up")
	can_switch = NetworkTime.seconds_between(last_switch,NetworkTime.tick) > 0.05
	
	one = Input.is_action_pressed("one")
	two = Input.is_action_pressed("two")
	three = Input.is_action_pressed("three")
	four = Input.is_action_pressed("four")
	five = Input.is_action_pressed("five")
	six = Input.is_action_pressed("six")
	seven = Input.is_action_pressed("seven")
	eight = Input.is_action_pressed("eight")
	nine =Input.is_action_pressed("nine")
	zero = Input.is_action_pressed("zero")
	
	
	
	
	if can_switch:	
		if switch_weapon_down or switch_weapon_up:
			last_switch = NetworkTime.tick
			#print("switched weapon")
		#switch_weapon_up = false
		#switch_weapon_down = false	
	
	if override_mouse:
		look_angle = Vector2.ZERO
		mouse_rotation = Vector2.ZERO
	else:
		look_angle = Vector2(-mouse_rotation.y * NetworkTime.ticktime, -mouse_rotation.x * NetworkTime.ticktime)
		mouse_rotation = Vector2.ZERO
		
	#if respawn_hit:
		#if get_parent().has_method("respawn"):
			#get_parent().respawn()
			#respawn_hit = false
	

func _input(event: InputEvent) -> void:
	if !is_multiplayer_authority(): return
	
		
	if event is InputEventMouseMotion:
		mouse_rotation.y = event.relative.x * mouse_sensitivity
		mouse_rotation.x = event.relative.y * mouse_sensitivity
		
	if event.is_action_pressed("pause"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		override_mouse = true
		
	
	
func _physics_process(delta: float) -> void:
	#print(is_multiplayer_authority())
	pass

func _ready():
	if is_multiplayer_authority():
		NetworkTime.before_tick_loop.connect(_gather)
		
		NetworkTime.start()
		username = Global.char_name
		color = Global.char_color
		helmet_index = Global.helmet_index


func _on_respawn_pressed() -> void:
	respawn_hit = true
