extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.new_turn.connect(_on_new_turn)
	SignalBus.played_move.connect(_on_played_move)
	SignalBus.player_won.connect(_on_player_won)
	SignalBus.menu_pressed.connect(_on_menu_pressed)
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
	

	
func _on_new_turn() -> void:
	$NewTurnSound.play()

func  _on_played_move(move: Move) -> void:
	# for sound fatigue, some variation of pitch
	$PieceSound.pitch_scale = randf_range(0.8, 1.2)
	$PieceSound.play()
	
func _on_player_won(_b: bool) -> void:
	$CelebrationSound.play()
	$CelebrationFadeOut.play("celebration")
	
func _on_menu_pressed() -> void:
	$MenuEnter.play()

func _on_undo() -> void:
	# same sound ;D
	_on_new_turn()
