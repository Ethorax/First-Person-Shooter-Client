extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for point in $SpawnPoints.get_children():
		Global.spawn_points.append(point.position)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass