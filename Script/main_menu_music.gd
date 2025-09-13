extends AudioStreamPlayer

func _ready():
	$".".play()
	pass
	
func _process(_delta):
	
	if $".".playing == false:
		await get_tree().create_timer(30).timeout
		$".".play()
	pass
