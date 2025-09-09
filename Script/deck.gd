extends Node2D

const CARD_SCENE_PATH = "res://Scene/card.tscn"
const CARD_DRAW_SPEED = 0.2
const STARTING_HAND_SIZE = 5

var player_deck = ["FileInfector","VirusAttack","DdosAttack","AntiVirus","VirusAttack","VirusAttack","VirusAttack"]
var card_database_reference
var draw_card_this_turn = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player_deck.shuffle()
	$RichTextLabel.text = str(player_deck.size())
	card_database_reference = preload("res://Script/CardDatabase.gd")
	await $"../Playerhand".ready 
	for i in range(STARTING_HAND_SIZE):
		draw_card()
		draw_card_this_turn = false


func draw_card():
	if draw_card_this_turn:
		return

	draw_card_this_turn = true
	var card_drawn_name = player_deck[0]
	player_deck.erase(card_drawn_name)
	
	if player_deck.size() == 0:
		$Area2D/CollisionShape2D.disabled = true
		$Sprite2D.visible = false
		$RichTextLabel.visible = false
	
	$RichTextLabel.text = str(player_deck.size())
	var card_scene = preload(CARD_SCENE_PATH)
	var new_card = card_scene.instantiate()
	var card_image_path = str("res://Asset/IMG/" + card_drawn_name + "Card.png")
	new_card.get_node("CardImg").texture = load(card_image_path)
	new_card.get_node("CPU").text = str(card_database_reference.CARDS[card_drawn_name][0])
	new_card.get_node("Ingre").text = str(card_database_reference.CARDS[card_drawn_name][1])
	new_card.card_type = card_database_reference.CARDS[card_drawn_name][2]
	$"../CardManager".add_child(new_card)
	new_card.name = "card"
	$"../Playerhand".add_card_to_hand(new_card, CARD_DRAW_SPEED)
	new_card.get_node("AnimationPlayer").play("card_filp")
