@tool
extends Node3D

@export var banner_texture : Texture

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$MeshInstance3D.mesh.material.set("shader_parameter/user_texture",banner_texture)
	$MeshInstance3D2.mesh.material.set("shader_parameter/user_texture",banner_texture)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
