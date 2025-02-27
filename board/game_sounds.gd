extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.new_turn.connect(_on_new_turn)
	SignalBus.played_move.connect(_on_played_move)
	SignalBus.player_won.connect(_on_player_won)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
	

	
func _on_new_turn() -> void:
	$NewTurnSound.play()

func  _on_played_move(move: Move):
	# for sound fatigue, some variation of pitch
	$PieceSound.pitch_scale = randf_range(0.8, 1.2)
	$PieceSound.play()
	
func _on_player_won(_b: bool):
	$CelebrationSound.play()
	$CelebrationFadeOut.play("celebration")
