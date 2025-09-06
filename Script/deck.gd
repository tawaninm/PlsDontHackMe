extends Node2D

var player_deck = ["Knight","Knight","Knight"]
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


func draw_card():
	print("draw card")
	#var card_scene = preload(CARD_SCENE_PATH)
	#for i in range(Hand_count) :
	#	var new_card = card_scene.instantiate()
	#	$"../CardManager".add_child(new_card)
	#	new_card.name = "card"
	#	add_card_to_hand(new_card)
