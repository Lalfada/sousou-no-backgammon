extends RichTextLabel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.player_won.connect(_on_player_won)
	SignalBus.open_menu.connect(_on_open_menu)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_player_won(winner_is_black: bool) -> void:
	visible = true
	text = "[wave amp=50.0 freq=5.0 connected=1]%s WINS[/wave]" \
		% ("STARK" if winner_is_black else "FERN")
	$AppearAnimation.play("appear")
	$ColorAnimation.play("ColorAnimation/color_variation")
	
func _on_open_menu() -> void:
	visible = false
