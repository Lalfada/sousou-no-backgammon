extends Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.player_won.connect(_on_player_won)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_player_won() -> void:
	visible = true
	$AnimationPlayer.play("appear")
