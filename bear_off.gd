extends HBoxContainer

@onready var bear_off_container: HBoxContainer = $HBoxContainer
@export var checker_controle_scene: PackedScene = preload("res://contained_checker.tscn")
@export var is_black: bool

var counter: int = 0

func add_checker():
	var checker: ContainedChecker = checker_controle_scene.instantiate()
	if not is_black:
		checker.set_white()
	else:
		checker.set_black()
	bear_off_container.add_child(checker)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_board_black_checker_left() -> void:
	if not is_black:
		return
	increment()


func _on_board_white_checker_left() -> void:
	if is_black:
		return
	increment()
		
func increment() -> void:
	counter += 1
	add_checker()
	$Label.text = "%d" % counter
