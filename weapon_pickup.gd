@tool
extends Node3D

@onready var weapon_holder: Marker3D = $WeaponHolder
var gun_model : String

enum gun {
	shotgun,
	sniper,
	flamer,
	bazooka,
	grenade,
	magnum
}
var weapon_index
@export var gun_pickup = gun.shotgun

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	match gun_pickup:
		gun.shotgun:
			gun_model ="res://Objects/shotgun.tscn"
			weapon_index = 2
		gun.sniper:
			gun_model ="res://Objects/sniper.tscn"
			weapon_index = 3

		gun.flamer:
			gun_model ="res://Objects/flamer.tscn"
			weapon_index = 4

		gun.bazooka:
			gun_model ="res://Objects/bazooka.tscn"
			weapon_index = 5
		gun.grenade:
			gun_model = "res://Objects/grenade_launcher.tscn"
			weapon_index = 6
		gun.magnum:
			gun_model = "res://Objects/magnum.tscn"
			weapon_index = 7
	
	
	var gun_instance = load(gun_model).instantiate()
	gun_instance.scale = Vector3(0.3,0.3,0.3)
	$WeaponHolder.add_child(gun_instance)	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	weapon_holder.rotation_degrees.y = fposmod(move_toward(weapon_holder.rotation_degrees.y,361,1), 360)
	
	$AnimationPlayer.play("normal") 


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		if !body.weapons[weapon_index]:
			body.add_weapon(weapon_index)
			despawn()
		
		
		
func despawn():
	$WeaponHolder.hide()
	$MeshInstance3D.hide()
	$Timer.start(30)
	$Area3D/CollisionShape3D.call_deferred("set_disabled",true)
func respawn():
	$WeaponHolder.show()
	$MeshInstance3D.show()
	$Area3D/CollisionShape3D.call_deferred("set_disabled",false)


func _on_timer_timeout() -> void:
	respawn()
