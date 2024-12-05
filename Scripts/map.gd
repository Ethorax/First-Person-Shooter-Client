extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Global.spawn_points = []
	for point in $SpawnPoints.get_children():
		Global.spawn_points.append(point.position)
