extends Sprite2D

@onready var anim = $"Sign Animation" # points to child AnimationPlayer

func _ready():
	anim.play("Flicker")  # play the flicker animation immediately
