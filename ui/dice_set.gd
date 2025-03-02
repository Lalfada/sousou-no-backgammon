extends Node2D
class_name DiceSet

const animation_names: Array[String] = ["purple", "red"]

@export var used_color: Color
@export var unused_color: Color
@export var four_dice_offset: Vector2
@export var fireworks_effect: PackedScene
@export var roll_sound1: AudioStreamPlayer
@export var roll_sound2: AudioStreamPlayer
@export var sound_max_pitch: float
@export var sound_min_pitch: float

@onready var roll_sounds: Array[AudioStreamPlayer] = [roll_sound1, roll_sound2]
var default_postion: Vector2
var roll_values: Array[int] = [1, 1, 1, 1]
var original_roll_values: Array[int]
var is_rolling: bool = false
var dice: Array[AnimatedSprite2D]
var white_starting_roll: int = 0
var black_starting_roll: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	default_postion = position
	original_roll_values = roll_values.duplicate()
	dice = [$Die1, $Die2, $Die3, $Die4]
	# Example: Listening for move_made in another script (e.g., Board.gd)
	SignalBus.played_move.connect(_on_played_move)
	SignalBus.new_turn.connect(_on_new_turn)
	SignalBus.start_game.connect(_on_start_game)

func roll() -> void:
	if is_rolling:
		return
	is_rolling = true
	play_random_roll_sound()
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
			
func set_color(is_black: bool) -> void:
	var color_id = 1 if is_black else 0
	for die in dice:
		die.animation = animation_names[color_id]
		
func _on_start_game() -> void:
	# set white
	set_color(false)
	roll_for_first()
	#roll()
	
func roll_for_first() -> void:
	$Die1.animation = animation_names[0]
	$Die2.animation = animation_names[1]
	$Die3.hide()
	$Die4.hide()
	$AnimationPlayer.play("initial_rolls")
	
func roll_duel_values() -> void:
	# to ensure we get different values, we choose value1 first
	# and only then procede to choose value2, by selecting random value
	# among 5 instead of 6, and shifting if neccessary
	white_starting_roll = randi() % 6 + 1
	black_starting_roll = randi() % 5 + 1
	black_starting_roll = black_starting_roll if black_starting_roll < white_starting_roll else black_starting_roll + 1
	

func display_duel_results() -> void:
	$Die1.frame = white_starting_roll - 1
	$Die2.frame = black_starting_roll - 1
	
	var vfx: GPUParticles2D = fireworks_effect.instantiate()
	add_child(vfx)
	vfx.finished.connect(vfx.queue_free)
	if white_starting_roll > black_starting_roll:
		vfx.position = $Die1.position
		vfx.set_purple()
		SignalBus.set_starting_player.emit(false)
	else:
		vfx.position = $Die2.position
		vfx.set_red()
		SignalBus.set_starting_player.emit(true)
	vfx.emitting = true
	

func convert_dice_colors() -> void:
	if white_starting_roll > black_starting_roll:
		set_color(false)
	else:
		set_color(true)
	
func play_random_roll_sound():
	var selected_sound: AudioStreamPlayer = roll_sounds[randi() % 2]
	selected_sound.play()
