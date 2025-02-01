extends PanelContainer

signal clicked_on_bear_off(tile_id: int)

@export var bear_off_container: HBoxContainer
@export var checker_controle_scene: PackedScene
@export var is_black: bool
@export var shader_material: ShaderMaterial
@export var shader_support: ColorRect
@export var label: Label
# yeah tile_id should be in some file defining constants
# but idk how to do that (and I got things to do)
# yeah it's not my proudeset moment
@export var tile_id: int

var glow_value: float = 0.7
var counter: int = 0
var validated_counter: int = 0

func add_checker(number: int):
	for i in range(number):
		var checker: ContainedChecker = checker_controle_scene.instantiate()
		if not is_black:
			checker.set_white()
		else:
			checker.set_black()
		bear_off_container.add_child(checker)
	
func remove_checker(number: int):
	for child in bear_off_container.get_children():
		if number == 0:
			return
			
		if child.is_in_group("checker"):
			child.queue_free()
			number -= 1
			
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# this is done to make each shader unique
	# usual methodes don't seem to work to ensure shader uniqueness
	shader_support.material = shader_material.duplicate()
	SignalBus.played_move.connect(_on_played_move)
	SignalBus.new_turn.connect(_on_new_turn)
	validated_counter = counter


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
		
func increment(number: int) -> void:
	counter += number
	add_checker(number)
	label.text = "%d" % counter
	
func decrement(number: int) -> void:
	counter -= number
	remove_checker(number)
	label.text = "%d" % counter
	
func set_glow(t: float) -> void:
	shader_support.material.set_shader_parameter("glow", t)
	
func highlight() -> void:
	set_glow(glow_value)
	
func stop_highlight() -> void:
	set_glow(0)
	


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var mouse_pos = get_global_mouse_position()
		if get_global_rect().has_point(mouse_pos):
			clicked_on_bear_off.emit(tile_id)


func _on_board_can_checker_leave(is_black: bool, can_leave: bool) -> void:
	if is_black != self.is_black:
		return
	if can_leave:
		highlight()
	else:
		stop_highlight()


func _on_undo_pressed() -> void:
	decrement(counter - validated_counter)


func _on_new_turn() -> void:
	validated_counter = counter
	
func _on_played_move(move: Move) -> void:
	var left_number: int = move.leaving_checkers.blacks \
		if is_black \
		else move.leaving_checkers.whites
		
	increment(left_number)
