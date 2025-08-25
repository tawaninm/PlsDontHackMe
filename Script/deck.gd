extends Node2D

var player_deck = ["card", "card", "card",]

func _ready() -> void:
	pass

func draw_card():
	print("draw")
	pass
#	for i in range(HAND_COUNT):
#		var new_card = card_scene.instantiate()
#		$"../CardManager".add_child(new_card)
#		new_card.name = "Card_%d" % i
#		add_card_to_hand(new_card)
