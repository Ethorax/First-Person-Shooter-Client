extends Area3D


var energy : float = 15
var size : float
var damage : int = 10
var player_id

func _ready() -> void:
	$Timer.start()
	$AnimationPlayer.play("explode")
	$AudioStreamPlayer3D.play()

func _on_body_entered(body: Node3D) -> void:
	#if(body is CharacterBody3D and body.is_in_group("PlayerRoot")):
	if(body is CharacterBody3D and body.is_in_group("Player")):
	
		#print("character exploded")
		
		body.get_parent().get_node(str(player_id)).hitmarker.modulate.a = 1.0
		
		var center = global_transform.origin
		var target = body.global_transform.origin
		var distance = target.distance_to(center)
		var distance_squared = distance * distance
		target.y += 1
		var direction = (target - center).normalized()
		
		#body.velocity += direction *10* energy
		var target_body = body.get_multiplayer_authority()
		#print(distance)
		
		var force = direction*energy
		#force.y = force.y * -1
		#print(distance)
		body.knockback(force / distance)
		body.take_damage( damage / distance, int(player_id))
		#NetworkRollback.mutate(body)
		#rpc_id(target_body,"knockback",direction,energy/distance_squared)
		#if is_multiplayer_authority():
			
			#Server.knockback_player(body.get_multiplayer_authority(),direction,energy/distance)
			#Server.hit_player(40/distance,str(body.get_multiplayer_authority()),str(player_id))
		
		#body.knockback.rpc_id(body.get_multiplayer_authority(),direction,10*energy)
		
		
	elif(body is RigidBody3D):
		print("object exploded")


func _on_timer_timeout() -> void:
	queue_free()
