extends MultiplayerSynchronizer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for prop in self.replication_config.get_properties():
		replication_config.property_set_replication_mode(prop,SceneReplicationConfig.REPLICATION_MODE_ALWAYS)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
