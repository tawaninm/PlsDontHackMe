extends Node2D

const CARD_SCENE_PATH = "res://Scene/card.tscn"
var card_types = ["Overclock", "CorruptedScript", "VirusAttack", "Cat"]
var card_data_reference = preload("res://Script/CardData.gd")

func draw_card():
	print("draw")

	# Pick random type
	var card_type = card_types[randi() % card_types.size()]

	# Make new card
	var card_scene = preload(CARD_SCENE_PATH)
	var new_card = card_scene.instantiate()
	$"../CardManager".add_child(new_card)

	# Name it
	new_card.name = "Card_" + card_type

	# Apply artwork (⚠ requires the card scene to have a Sprite2D or TextureRect)
	if new_card.has_node("Artwork"): # your child node inside card.tscn
		new_card.get_node("Artwork").texture = card_data_reference.CARDS[card_type]["artwork"]

	# Send to hand
	$"../PlayerHand".add_card_to_hand(new_card)
