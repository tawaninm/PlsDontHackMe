# res://Scripts/turn_controls.gd
extends Control

@onready var btn_draw: Button = $DrawButton
@onready var btn_skip: Button = $SkipButton

func _ready() -> void:
	# Defensive: make sure nodes exist
	if not btn_draw:
		push_error("TurnControls: DrawButton not found at $HBoxContainer/DrawButton")
	else:
		btn_draw.connect("pressed", Callable(self, "_on_draw_pressed"))

	if not btn_skip:
		push_error("TurnControls: SkipButton not found at $HBoxContainer/SkipButton")
	else:
		btn_skip.connect("pressed", Callable(self, "_on_skip_pressed"))


	hide()

# --- Public API used by GameManager (or Main) ---
func show_for_player(player_index: int) -> void:
	show()

# --- Button callbacks ---
func _on_draw_pressed() -> void:
	if Engine.has_singleton("GameManager"):
		# GameManager expects player index; we call using its current player index
		GameManager.player_draw_card(GameManager.current_player_index)

func _on_skip_pressed() -> void:
	if Engine.has_singleton("GameManager"):
		GameManager.player_skip_turn(GameManager.current_player_index)

func _on_end_pressed() -> void:
	if Engine.has_singleton("GameManager"):
		# Force end turn immediately (GameManager handles rotation)
		if GameManager.has_method("end_turn"):
			GameManager.end_turn()
		else:
			# fallback: rotate by calling skip function (safe default)
			GameManager.player_skip_turn(GameManager.current_player_index)
