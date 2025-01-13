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
	if body.is_in_group("PlayerRoot"):
		Server.hit_player(99999,body.name,"1")
