extends Control


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://Scene/Prep_menu.tscn")


func _on_settings_pressed() -> void:
	pass

func _on_quit_pressed() -> void:
	get_parent().queue_free()


func _on_scripts_pressed() -> void:
	pass
