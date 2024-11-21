extends RigidBody3D

var shooter
@export var SPEED  = 100
@export var energy = 50
@onready var explosion = preload("res://Objects/explosion.tscn")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_timer_timeout() -> void:
	print("explosion")
	var e = explosion.instantiate()
	e.global_position = global_position
	e.scale = e.scale *1.5
	e.player_id = str(shooter)
	get_parent().add_child(e)
	queue_free()
