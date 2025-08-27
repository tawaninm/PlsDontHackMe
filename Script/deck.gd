extends Node2D

const CARD_SCENE_PATH = "res://Scene/card.tscn"
var card_types = ["Overclock", "CorruptedScript", "VirusAttack", "Cat"]
var card_data_reference
@onready var card_manager_reference = $"../CardManager"
@onready var player_hand_reference = $"../PlayerHand"

func _ready() -> void:
	card_data_reference = preload("res://Script/CardData.gd")

func draw_card():
	print("draw")
	
	if not card_manager_reference:
		push_error("CardManager node not found at path: ../CardManager")
		return
	if not player_hand_reference:
		push_error("PlayerHand node not found at path: ../PlayerHand")
		return

	var card_type = card_types[randi() % card_types.size()]
	var card_scene = preload(CARD_SCENE_PATH)

	if not card_scene:
		push_error("Failed to load the card scene at: ", CARD_SCENE_PATH)
		return

	var new_card = card_scene.instantiate()
	
	card_manager_reference.add_child(new_card)

	var card_image_page = str("res://Asset/CARDS/"+card_type+".png")
	new_card.get_node("Area2D/CardImage").texture = load(card_image_page)

	new_card.name = "Card_" + card_type

	player_hand_reference.add_card_to_hand(new_card)
