extends CSGBox3D


@onready var collision_shape_3d: CollisionShape3D = $Area3D/CollisionShape3D




# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide()
	collision_shape_3d.shape.size = size


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_area_3d_body_entered(body: Node3D) -> void:
	#if body.is_in_group("PlayerRoot") and body.is_multiplayer_authority():
		#Server.hit_player(99999,body.name,"1")
	if !is_multiplayer_authority(): return
	if body.has_method("take_damage"):
		body.take_damage(999999)
