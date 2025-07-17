extends CharacterBody3D



var shooter
@export var SPEED  = 50
@export var energy = 50
@onready var explosion = preload("res://Objects/explosion.tscn")
@onready var ray_cast_3d: RayCast3D = $RayCast3D
@onready var backcast: RayCast3D = $Backcast

var dir : Vector3
var spawn_pos : Vector3
var spawn_rot : Vector3
var e_location : Vector3
var point_blank := false
var damage : int = 10


func _enter_tree() -> void:
	rotation_degrees.x -= 90

func _ready() -> void:
	if point_blank:
		e_location = global_position
func _physics_process(delta: float) -> void:
	#var direction = Vector3(-1,0,0)
	
	var direction = (transform.basis * Vector3(0,1,0)).normalized()
	if !point_blank:
		velocity = (direction).normalized() * SPEED
	
	if ray_cast_3d.is_colliding():
		e_location = ray_cast_3d.get_collision_point()
	if backcast.is_colliding():
		if !backcast.get_collider().is_in_group("Player"):
			e_location = backcast.get_collision_point()
			print(backcast.get_collider())
	if e_location:
		print("explosion")
		var e = explosion.instantiate()
		e.damage = damage
		e.player_id = str(shooter)
		get_parent().add_child(e)
		e.global_position = e_location
		queue_free()
	
	move_and_slide()


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.input.get_multiplayer_authority() != shooter and body.is_in_group("Player"):
		print("explosion")
		var e = explosion.instantiate()
		e.player_id = str(shooter)
		e.damage = damage
		get_parent().add_child(e)
		e.global_position = global_position
		queue_free()
