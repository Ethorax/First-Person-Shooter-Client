extends Camera3D


const CAMERA_MOUSE_ROTATION_SPEED := 0.001
const CAMERA_X_ROT_MIN := deg_to_rad(-89.9)
const CAMERA_X_ROT_MAX := deg_to_rad(70)
const CAMERA_UP_DOWN_MOVEMENT = -1

var mouse_sense = 0.15

var camera_basis : Basis = Basis.IDENTITY

@onready var camera_3d: Camera3D = %Camera3D
var mouse_rotation: Vector2 = Vector2.ZERO
var look_angle: Vector2 = Vector2.ZERO
@export var mouse_sensitivity: float = 1.0

var is_setup: bool = false
var override_mouse: bool = false

func _ready():
	NetworkTime.before_tick_loop.connect(_gather)
	
	if is_multiplayer_authority():
		#camera_3D.current = true
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		pass

func _gather():
	camera_basis = get_camera_rotation_basis()

func _input(event):
	if !is_multiplayer_authority():
		return
	#if event is InputEventMouseMotion:
		#rotate_camera(event.relative * CAMERA_MOUSE_ROTATION_SPEED)
		
	if event is InputEventMouseMotion:
		mouse_rotation.y = event.relative.x * mouse_sensitivity
		mouse_rotation.x = event.relative.y * mouse_sensitivity
	if event.is_action_pressed("pause"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		override_mouse = true
		#rotate_y(deg_to_rad(-event.relative.x*mouse_sense))
		#rotate_x(deg_to_rad(-event.relative.y*mouse_sense))
		#rotation.x = clamp(rotation.x, deg_to_rad(-89), deg_to_rad(89))

func rotate_camera(move):
	# Horizontal camera movement
	# Currently, we only care to synch horizontal rotation, vertical camera changes are only for local client.
	rotate_y(-move.x)
	orthonormalize()
	
	# Vertical camera movement
	rotation.x = clamp(global_rotation.x + (CAMERA_UP_DOWN_MOVEMENT * move.y), CAMERA_X_ROT_MIN, CAMERA_X_ROT_MAX)

func get_camera_rotation_basis() -> Basis:
	# Use camera_mount here so we don't have to worry about correcting for lean
	return global_transform.basis 

func _exit_tree():
	NetworkTime.before_tick_loop.disconnect(_gather)
