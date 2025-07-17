extends Node3D



@export var jump_force : float
var direction = Vector3.ZERO

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	direction = (rotation).normalized()
	if direction == Vector3.ZERO:
		direction = Vector3(1,1,1)
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		print("Jump Activated")
		print(direction)
		body.knockback(Vector3.UP * jump_force * direction,true)
		
		#Server.knockback_player(body.name,Vector3.UP,jump_force,true)
