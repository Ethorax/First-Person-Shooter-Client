extends Node3D

@onready var weapon_holder: Marker3D = $WeaponHolder
@export var gun_model : String



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var gun_instance = load(gun_model).instantiate()
	gun_instance.scale = Vector3(0.3,0.3,0.3)
	$WeaponHolder.add_child(gun_instance)	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	delta
	weapon_holder.rotation_degrees.y = fposmod(move_toward(weapon_holder.rotation_degrees.y,361,1), 360)
	
	$AnimationPlayer.play("normal") 


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		body.add_weapon(gun_model)
