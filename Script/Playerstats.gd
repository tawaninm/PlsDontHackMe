extends Control

@export var integrity_path: NodePath = "Control/Health1"
@export var bandwidth_path: NodePath = "Control/Mana1"
@export var packetloss_path: NodePath = "Control/Error1"

var gm: Node = null
@onready var integrity: RichTextLabel = $"../../../Control/Health1"
@onready var bandwidth: RichTextLabel = $"../../../Control/Mana1"
@onready var packetloss: RichTextLabel = $"../../../Control/Error1"

func set_gm(game_manager: Node) -> void:
	gm = game_manager

func _ready() -> void:
	for lbl in [integrity, bandwidth, packetloss]:
		if lbl:
			lbl.bbcode_enabled = true

func update_ui_for_player(p) -> void:
	if integrity:
		integrity.bbcode_text = "[color=#e5b931]%d[/color]" % p.integrity
	if bandwidth:
		bandwidth.bbcode_text = "[color=#e5b931]%d[/color]" % p.bandwidth
	if packetloss:
		packetloss.bbcode_text = "[color=#e5b931]%d[/color]" % p.packetloss
