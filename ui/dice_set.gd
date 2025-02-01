extends Node2D
class_name DiceSet

const animation_names: Array[String] = ["purple", "red"]

@export var used_color: Color
@export var unused_color: Color
@export var four_dice_offset: Vector2

var default_postion: Vector2
var roll_values: Array[int] = [1, 1, 1, 1]
var original_roll_values: Array[int]
var is_rolling: bool = false
var dice: Array[AnimatedSprite2D]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	default_postion = position
	original_roll_values = roll_values.duplicate()
	dice = [$Die1, $Die2, $Die3, $Die4]
	# Example: Listening for move_made in another script (e.g., Board.gd)
	SignalBus.played_move.connect(_on_played_move)
	SignalBus.new_turn.connect(_on_new_turn)



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func roll() -> void:
	if is_rolling:
		return
	is_rolling = true
	position = default_postion
	$Die1.modulate = unused_color
	$Die1.play()
	$Die2.modulate = unused_color
	$Die2.play()
	$Die3.hide()
	$Die3.modulate = unused_color
	$Die4.hide()
	$Die4.modulate = unused_color
	$Timer.start()

func _on_timer_timeout() -> void:
	is_rolling = false
	var result1: int = randi() % 6 + 1
	var result2: int = randi() % 6 + 1
	$Die1.stop()
	$Die1.frame = result1 - 1
	$Die2.stop()
	$Die2.frame = result2 - 1
	
	if result1 != result2:
		roll_values = [result1, result2]
	else:
		roll_values = [result1, result1, result1, result1]
		$Die3.show()
		$Die3.frame = result1 - 1
		$Die4.show()
		$Die4.frame = result1 - 1
		position += four_dice_offset
	
	original_roll_values = roll_values.duplicate()
	SignalBus.dice_result.emit(roll_values)
	


func _on_new_turn() -> void:
	switch_color()
	roll()

func switch_color() -> void:
	for die in dice:
		if die.animation == animation_names[0]:
			die.animation = animation_names[1]
		else:
			die.animation = animation_names[0]
			

func _on_undo_pressed() -> void:
	roll_values = original_roll_values.duplicate()
	for die in dice:
		die.modulate = unused_color
		
func _on_played_move(move: Move) -> void:
	var used_dice: Array[int] = move.steps.duplicate()
	for used_die in used_dice:
		for i in range(roll_values.size()):
			if roll_values[i] != used_die:
				continue
			roll_values[i] = 0
			dice[i].modulate = used_color
			break
