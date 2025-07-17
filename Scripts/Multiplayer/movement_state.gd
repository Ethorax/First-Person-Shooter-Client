class_name MovementState 
extends RewindableState

# A base movement state for common functions, extend when making new movement state.

const WALK_SPEED := 5.0
const RUN_MODIFIER := 2.5
const ROTATION_INTERPOLATE_SPEED := 10
const JUMP_VELOCITY := 6.5
const JUMP_MOVE_SPEED := 3.0

@export var animation_name: String
@export var camera_input : Node3D
@export var player_model : Node3D
@export var player_input: PlayerInput
@export var parent: Node3D

@export var gun_holder : Node3D



# Default movement, override as needed
func move_player(delta: float, speed: float = WALK_SPEED):
	#parent.velocity *= NetworkTime.physics_factor
	#parent.move_and_slide()
	#parent.velocity /= NetworkTime.physics_factor
	pass

func rotate_player_model(delta: float):
	#var camera_basis : Basis = camera_input.camera_basis
	
	
	pass
	## NOTE: Model direction issues can be resolved by adding a negative to camera_z, depending on setup.
	##var player_lookat_target = -camera_basis.z
	#
	#var q_from = player_model.global_transform.basis.get_rotation_quaternion()
	##var q_to = Transform3D().looking_at(player_lookat_target, Vector3.UP).basis.get_rotation_quaternion()
#
	#var set_model_rotation = Basis(q_from.slerp(q_to, delta * ROTATION_INTERPOLATE_SPEED))
	#player_model.global_transform.basis = set_model_rotation
	#player_model.rotation.z = 0
	#player_model.rotation.x = 0

# https://foxssake.github.io/netfox/netfox/tutorials/rollback-caveats/#characterbody-on-floor
#func force_update_is_on_floor():
	#var old_velocity = parent.velocity
	#parent.velocity *= 0
	#parent.move_and_slide()
	#parent.velocity = old_velocity

func get_movement_input() -> Vector3:
	return player_input.movement

func get_run() -> bool:
	#return player_input.run_input
	return false
	
func get_jump() -> float:
	return player_input.jump_input

func get_fire() -> bool:
	return player_input.fire
	
func handle_fire():
	if get_fire():
		
		var hitscan = %Weapons/Hitscan as NetworkWeaponHitscan3D
		var hitscan_results = hitscan.fire()
		#print("bang")
