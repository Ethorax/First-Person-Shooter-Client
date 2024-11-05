extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5

var health : int = 5

func take_damage(damage : int) -> void:
	health += -damage
	print(health)
	if(health <= 0):
		queue_free()
