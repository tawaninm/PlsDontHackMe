# Main_control.gd
extends Control

func _on_start_pressed() -> void:
	NetworkManager.start_or_join()

func _on_settings_pressed() -> void:
	pass

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_scripts_pressed() -> void:
	pass
