extends Node3D


@export var noise : NoiseTexture2D
var time_passed = 0.0
@onready var lights = []

func _ready() -> void:
	for child in get_children():
		if child is OmniLight3D:
			lights.append(child)

func _process(delta):
	time_passed += delta
	
	var sampled_noise = noise.noise.get_noise_1d(time_passed)
	sampled_noise = abs(sampled_noise)
	#print(sampled_noise)
	for light in lights:
		light.light_energy = 1+sampled_noise*10
