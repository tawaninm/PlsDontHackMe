extends Node2D   # or Control, depending on your scene root

@export var start_seconds: int = 20

@onready var prep_timer: Timer = $"Prep Time"
@onready var time_label: RichTextLabel = $"Time Left"   # <-- fixed

var remaining_seconds: int = 0

func _ready() -> void:
	remaining_seconds = start_seconds
	prep_timer.wait_time = 1.0
	prep_timer.one_shot = false
	prep_timer.autostart = false
	prep_timer.timeout.connect(_on_prep_time_timeout)
	update_time_label()
	prep_timer.start()

func _on_prep_time_timeout() -> void:
	remaining_seconds -= 1
	if remaining_seconds <= 0:
		prep_timer.stop()
		get_tree().change_scene_to_file("res://Scene/main.tscn") # change this path
	else:
		update_time_label()

func update_time_label() -> void:
	var m = remaining_seconds / 60
	var s = remaining_seconds % 60
	time_label.text = "[color=red]%02d:%02d[/color]" % [m, s]
