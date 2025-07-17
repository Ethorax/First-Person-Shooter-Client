extends AudioStreamPlayer


@export var songs : Array[AudioStreamMP3]
var songs_copy = []
func _ready() -> void:
	songs_copy = songs.duplicate(true)
	songs_copy.shuffle()



func go_mode():
	var next_song
	
	if songs_copy.size() > 0:
		songs_copy = songs.duplicate(true)
		songs_copy.shuffle()
	
	next_song = songs_copy.pop_at(0) as AudioStreamMP3
	
	print(next_song.resource_name)
	
	stream = next_song
	
	play()
