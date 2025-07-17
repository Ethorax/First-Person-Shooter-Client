extends RigidBody3D

var shooter
@export var SPEED  = 100
@export var energy = 50
var damage := 10
#@onready var explosion = preload("res://Objects/explosion.tscn")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	apply_impulse((transform.basis * Vector3(0,0,-1)).normalized() * 30)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

#
#func _on_timer_timeout() -> void:
	#print("explosion")
	#var e = explosion.instantiate()
	#e.global_position = global_position
	#e.scale = e.scale *1.5
	#get_parent().add_child(e)
	#queue_free()


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player") and str(body.name) != str(shooter):
		body.get_parent().get_node(str(shooter)).hitmarker.modulate.a = 1.0

		body.take_damage(damage)
		#if body.is_multiplayer_authority():
			#Server.hit_player(30,str(body.get_multiplayer_authority()),str(shooter))


func _on_timer_timeout() -> void:
	queue_free()
