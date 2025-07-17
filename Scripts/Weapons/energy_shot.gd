extends CharacterBody3D

var hit = false
var shooter
@export var SPEED  = 100
@export var energy = 50
@onready var explosion = preload("res://Objects/explosion.tscn")
@onready var ray_cast_3d: RayCast3D = $RayCast3D
var damage : int = 10

func _ready() -> void:
	var direction = (transform.basis * Vector3(0,0,-1)).normalized()
	velocity = (direction).normalized() * SPEED


func _physics_process(delta: float) -> void:
	
	if ray_cast_3d.is_colliding():
		if ray_cast_3d.get_collider().is_in_group("Player") and !hit:
			hit = true
			_on_area_3d_body_entered(ray_cast_3d.get_collider())
	move_and_slide()


func _on_area_3d_body_entered(body: Node3D) -> void: 
	
	#print(body.get_multiplayer_authority())
	#print(body.get_groups())
	if body.has_method("take_damage") and body.has_node("Input"):
		
		#print(str(body.input.get_multiplayer_authority()) + " " + str(shooter) )
		if str(body.input.get_multiplayer_authority()) != str(shooter):
			body.get_parent().get_node(str(shooter)).hitmarker.modulate.a = 1.0

			body.take_damage(damage, int(shooter))
			#print(str(shooter)+ " is the shooter")
	queue_free()
	#if body.is_in_group("PlayerRoot") and str(body.get_multiplayer_authority()) != str(shooter) and !hit:
		#if body.is_multiplayer_authority():
			#hit = true
			##Server.hit_player(13,str(body.get_multiplayer_authority()),str(shooter))
			#queue_free()
	#elif body.name != str(shooter):
		#queue_free()
