extends HBoxContainer

var placing : int
var color : Color
var username : String
var frags : int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	var gradient = GradientTexture2D.new()
	print(gradient)
	#gradient.gradient.remove_point(1)
	gradient.gradient = Gradient.new()
	#gradient.gradient.remove_point(0)
	#gradient.gradient.remove_point(0)
	gradient.width = 128
	gradient.height = 32
	gradient.gradient.add_point(0,color)
	
	
	$Color.texture = gradient
	$Placing.text = str(placing)
	$Name.text = username
	$Frags.text = str(frags)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
