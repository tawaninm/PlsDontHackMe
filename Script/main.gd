extends Node2D

func _ready() -> void:
	# adjust names to match your scene tree
	var cm = $CardManager
	var deck = $Board/Draw
	var hands = [
		$PlayerHand,
		$PlayerHand2,
		$PlayerHand3
]

	var ui_nodes = []
	ui_nodes.append($CanvasLayer/UI/PlayerUI1)
	ui_nodes.append($CanvasLayer/UI/PlayerUI2)
	ui_nodes.append($CanvasLayer/UI/PlayerUI3)

	var turn_controls = $TurnControls

	GameManager.register_scene_nodes(cm, hands, deck, ui_nodes, turn_controls)
	GameManager.start_game()
