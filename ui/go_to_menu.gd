extends Button


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.player_won.connect(_on_player_won)
	SignalBus.open_menu.connect(_on_open_menu)



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_pressed() -> void:
	SignalBus.open_menu.emit()
	SignalBus.menu_pressed.emit()

func _on_player_won(_winner_is_black: bool) -> void:
	visible = true
	
func _on_open_menu() -> void:
	visible = false
