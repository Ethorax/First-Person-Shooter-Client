extends Node3D


enum pickup_types {
	ammo_pistol,
	ammo_rifle,
	ammo_shotgun,
	ammo_magnum,
	ammo_rocket,
	health_small,
	health_medium,
	health_large,
	armor_small,
	armor_medium,
	armor_large,
}





@export var type : pickup_types = pickup_types.ammo_pistol
var amount : int
var ammo_type
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	match type:
		pickup_types.ammo_pistol:
			$Sprite3D.texture = preload("res://Graphics/Pickups/pistolAmmo.png")
			$AudioStreamPlayer3D.stream = preload("res://Audio/SFX/Pickups/Books Impact D.wav")
			amount = 50
			ammo_type = "pistol"
		pickup_types.ammo_rifle:
			$Sprite3D.texture = preload("res://Graphics/Pickups/riflebullets.png")
			$AudioStreamPlayer3D.stream("res://Audio/SFX/Pickups/Books Impact D.wav")
			amount = 15
			ammo_type = "sniper"
		pickup_types.ammo_shotgun:
			$Sprite3D.texture = preload("res://Graphics/Pickups/shotgunshells.png")
			$AudioStreamPlayer3D.stream("res://Audio/SFX/Pickups/Books Impact D.wav")
			amount = 20
			ammo_type = "shotgun"
		pickup_types.ammo_magnum:
			$Sprite3D.texture = preload("res://Graphics/Pickups/magnumammo.png")
			$AudioStreamPlayer3D.stream("res://Audio/SFX/Pickups/Books Impact D.wav")
			amount = 8
			ammo_type = "magnum"
		pickup_types.ammo_rocket:
			$Sprite3D.texture = preload("res://Graphics/Pickups/rockets.png")
			$AudioStreamPlayer3D.stream("res://Audio/SFX/Pickups/Books Impact D.wav")
			amount = 5
			ammo_type = "bazooka"
		pickup_types.health_small:
			amount = 5
			ammo_type = "health"
			$Sprite3D.texture = preload("res://Graphics/Pickups/health_small.png")
			$AudioStreamPlayer3D.stream("res://Audio/SFX/Pickups/Sci-Fi Device Use 001.wav")
		pickup_types.health_medium:
			amount = 20
			ammo_type = "health"
			$Sprite3D.texture = preload("res://Graphics/Pickups/health_medium.png")
			$AudioStreamPlayer3D.stream("res://Audio/SFX/Pickups/Sci-Fi Device Use 001.wav")
		pickup_types.health_large:
			amount = 50
			ammo_type = "health"
			$Sprite3D.texture = preload("res://Graphics/Pickups/health_large.png")
			$AudioStreamPlayer3D.stream("res://Audio/SFX/Pickups/Sci-Fi Device Use 001.wav")
		pickup_types.armor_small:
			amount = 5
			ammo_type = "armor"
			$Sprite3D.texture = preload("res://Graphics/Pickups/armor_small.png")
			$AudioStreamPlayer3D.stream("res://Audio/SFX/Pickups/Sci-Fi Overshield 002.wav")
		pickup_types.armor_medium:
			amount = 20
			ammo_type = "armor"
			$Sprite3D.texture = preload("res://Graphics/Pickups/armor_medium.png")
			$AudioStreamPlayer3D.stream("res://Audio/SFX/Pickups/Sci-Fi Overshield 002.wav")
		pickup_types.armor_large:
			amount = 50
			ammo_type = "armor"
			$Sprite3D.texture = preload("res://Graphics/Pickups/armor_large.png")
			$AudioStreamPlayer3D.stream("res://Audio/SFX/Pickups/Sci-Fi Overshield 002.wav")
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass



func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		$Timer.start(30)
		body.add_ammo(amount,ammo_type)
		$AudioStreamPlayer3D.play()
		despawn()

func _on_timer_timeout() -> void:
	respawn()


func despawn():
	$Sprite3D.hide()
	$Area3D/CollisionShape3D.call_deferred("set_disabled",true)
func respawn():
	$Sprite3D.show()
	$Area3D/CollisionShape3D.call_deferred("set_disabled",false)
