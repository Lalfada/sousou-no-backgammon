extends MarginContainer

var original_mouse_filters: Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.player_won.connect(_on_player_won)
	SignalBus.start_game.connect(_on_start_game)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _on_player_won(winner_is_black: bool) -> void:
	disable_mouse_input(self)
	#disable_mouse_inputv1(self)
	
func _on_start_game() -> void:
	enable_mouse_input(self)
	#enable_mouse_inputv1()
	
func disable_mouse_input(node: Node):
	if is_instance_of(node, BaseButton) and node.is_in_group("in_game_button"):
		node.disabled = true
	for child in node.get_children():
		disable_mouse_input(child)

func enable_mouse_input(node: Node):
	if is_instance_of(node, BaseButton) and node.is_in_group("in_game_button"):
		node.disabled = false
	for child in node.get_children():
		enable_mouse_input(child)
