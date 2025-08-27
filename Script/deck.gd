extends Node2D

const CARD_SCENE_PATH = "res://Scene/card.tscn"
var card_types = ["Overclock", "CorruptedScript", "VirusAttack", "Cat"]
var card_data_reference
var card_manager_reference

func _ready() -> void:
	card_data_reference = preload("res://Script/CardData.gd")
	card_manager_reference = $"../CardManager"

func draw_card():
	print("draw")

	# Pick a random card type.
	var card_type = card_types[randi() % card_types.size()]

	# Create a new card instance.
	var card_scene = preload(CARD_SCENE_PATH)
	var new_card = card_scene.instantiate()
	
	# Add the new card to the CardManager as a child.
	card_manager_reference.add_child(new_card)

	# Corrected path for the card texture.
	var card_image_page = str("res://Asset/CARDS/"+card_type+".png")
	new_card.get_node("Area2D/CardImage").texture = load(card_image_page)

	# Name it.
	new_card.name = "Card_" + card_type

	# Send to hand.
	$"../PlayerHand".add_card_to_hand(new_card)
