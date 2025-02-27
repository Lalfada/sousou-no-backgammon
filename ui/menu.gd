extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.open_menu.connect(_on_open_menu)



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_pv_p_pressed() -> void:
	SignalBus.set_play_mode.emit(false)
	start_game()


func _on_computer_pressed() -> void:
	SignalBus.set_play_mode.emit(true)
	start_game()

func start_game() -> void:
	visible = false
	SignalBus.start_game.emit()
	
func _on_open_menu() -> void:
	visible = true
	
