extends Area3D


var energy : float = 20
var size : float
var damage : int
var player_id

func _ready() -> void:
	$Timer.start()
	$AnimationPlayer.play("explode")
	$AudioStreamPlayer3D.play()

func _on_body_entered(body: Node3D) -> void:
	if(body is CharacterBody3D and body.is_in_group("PlayerRoot")):
		print("character exploded")
		
		var center = global_transform.origin
		var target = body.global_transform.origin
		var distance = target.distance_to(center)
		var distance_squared = distance * distance
		
		var direction = (target - center).normalized()
		
		#body.velocity += direction *10* energy
		var target_body = body.get_multiplayer_authority()
		print(distance)
		#rpc_id(target_body,"knockback",direction,energy/distance_squared)
		Server.knockback_player(body.get_multiplayer_authority(),direction,energy/distance)
		Server.hit_player(50/distance,str(body.get_multiplayer_authority()),str(player_id))
		
		#body.knockback.rpc_id(body.get_multiplayer_authority(),direction,10*energy)
		
		
	elif(body is RigidBody3D):
		print("object exploded")

@rpc
func knockback(direction,energy):
	pass

func _on_timer_timeout() -> void:
	queue_free()
