extends CharacterBody3D

var hit = false
var shooter
@export var SPEED  = 100
@export var energy = 50
@onready var explosion = preload("res://Objects/explosion.tscn")
@onready var ray_cast_3d: RayCast3D = $RayCast3D

func _physics_process(delta: float) -> void:
	
	if ray_cast_3d.is_colliding():
		if ray_cast_3d.get_collider().is_in_group("PlayerRoot") and !hit:
			hit = true
			_on_area_3d_body_entered(ray_cast_3d.get_collider())
	move_and_slide()


func _on_area_3d_body_entered(body: Node3D) -> void: 
	
	#print(body.get_multiplayer_authority())
	#print(body.get_groups())
	
	if body.is_in_group("PlayerRoot") and str(body.get_multiplayer_authority()) != str(shooter) and !hit:
		hit = true
		Server.hit_player(13,str(body.get_multiplayer_authority()),str(shooter))
		queue_free()
	elif body.name != str(shooter):
		queue_free()
