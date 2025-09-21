extends Control

@onready var btn_draw: Button = $DrawButton
@onready var btn_skip: Button = $SkipButton

var gm: Node = null

func set_gm(game_manager: Node) -> void:
	gm = game_manager

func _ready() -> void:
	if btn_draw:
		btn_draw.connect("pressed", Callable(self, "_on_draw_pressed"))
	if btn_skip:
		btn_skip.connect("pressed", Callable(self, "_on_skip_pressed"))
	hide()

func show_for_player(_player_index: int) -> void:
	show()

func _on_draw_pressed() -> void:
	if gm:
		gm.player_draw_card(gm.current_player_index)

func _on_skip_pressed() -> void:
	if gm:
		gm.player_skip_turn(gm.current_player_index)

func _on_end_pressed() -> void:
	if gm:
		if gm.has_method("end_turn"):
			gm.end_turn()
		else:
			gm.player_skip_turn(gm.current_player_index)
