extends CharacterBody3D



var shooter
@export var SPEED  = 100
@export var energy = 50
@onready var explosion = preload("res://Objects/explosion.tscn")
@onready var ray_cast_3d: RayCast3D = $RayCast3D

var dir : Vector3
var spawn_pos : Vector3
var spawn_rot : Vector3
var e_location : Vector3


func _physics_process(delta: float) -> void:
	
	if e_location:
		print("explosion")
		var e = explosion.instantiate()
		e.global_position = e_location
		e.player_id = str(shooter)
		get_parent().add_child(e)
		queue_free()
	
	if ray_cast_3d.is_colliding():
		e_location = ray_cast_3d.get_collision_point()
	
	move_and_slide()


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.name != shooter:
		print("explosion")
		var e = explosion.instantiate()
		e.global_position = global_position
		get_parent().add_child(e)
		queue_free()
