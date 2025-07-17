extends Resource
class_name GunData


@export var name: String = ""
@export var ammo_type : String = ""
@export var fire_rate : float = 0.5
@export var projectile : PackedScene
@export var fire_sound : AudioStream
@export var hold_pose : int
@export var damage : int
@export var spread : float
