extends Node2D
class_name Board

signal used_dice(dice: Array)

const SQUARE_NUMBER: int = 24
const COLUMN_WIDTH: int = 125
const LEFT_START: int = 70
const RIGHT_START: int = 850
const CHECKER_SIZE: int = 90
const VERTICAL_START: int = 60
const COLUMN_HEIGHT: int = 400

# negative values are black checkers, and zero means no checkers.
const default_board: Array = [
	2, 0, 0, 0, 0, -5,
	0, -3, 0, 0, 0, 5,
	-5, 0, 0, 0, 3, 0,
	5, 0, 0, 0, 0, -2
	]


@onready var checker_scene := preload("res://Checker.tscn")
@onready var light_scene := preload("res://light.tscn")
var board_state : Array = []
var checkers : Array = []
var selected_checkers : Array = []
var light_effects: Array = []
var roll_values: Array = [1, 1]
var moves: Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	board_state = default_board
	update_graphics()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func update_graphics() -> void:
	# Clear existing checker nodes to reset the board
	for checker in checkers:
		checker.queue_free()
	checkers.clear()
	
	# Define tile positions based on the board array
	var tile_positions = get_tile_positions()  # A helper function to define tile positions
	
	for i in range(board_state.size()):
		var count: int = board_state[i]
		
		if count == 0:
			continue  # Skip empty tiles
		
		var is_white = count > 0
		count = abs(count)  # Get the absolute number of checkers on this tile
		
		for j in range(count):
			# Load the Checker scene
			var checker_scene = preload("res://checker.tscn")
			var checker_instance = checker_scene.instantiate()
			checkers.push_back(checker_instance)
			
			# set checker id
			checker_instance.set_id(i)
			
			# Set the position of the checker
			var stack_direction = -1 if i < 12 else 1
			checker_instance.position = tile_positions[i] + Vector2(0, j * CHECKER_SIZE * stack_direction)  # Stack vertically

			# Set the color or property of the checker (white/black)
			if is_white:
				checker_instance.set_white()  # White color
			else:
				checker_instance.set_black() # Black color

			# Add the checker instance as a child of the board
			add_child(checker_instance)

func get_tile_positions() -> Array:
	var screen_size : Vector2i = DisplayServer.window_get_size()
	
	# Define the positions of each tile on the board
	# This is an example, customize it based on your board's layout
	var positions = []
	for x in range(6):  # Bottom right
		positions.append(Vector2(RIGHT_START + COLUMN_WIDTH * (5 - x), screen_size.y - VERTICAL_START))
	for x in range(6):  # Bottom left
		positions.append(Vector2(LEFT_START + COLUMN_WIDTH * (5 - x), screen_size.y - VERTICAL_START))
	for x in range(6):  # Top left
		positions.append(Vector2(LEFT_START + COLUMN_WIDTH * x, VERTICAL_START))
	for x in range(6):  # Top right
		positions.append(Vector2(RIGHT_START + COLUMN_WIDTH * x, VERTICAL_START))

	return positions
	
func get_tile_id_from_mouse(mouse_pos: Vector2) -> int:
	# Define a radius for detecting clicks around tile positions
	var tile_positions: Array = get_tile_positions()
	var tile_width: int= COLUMN_WIDTH / 2 
	var tile_height: int = COLUMN_HEIGHT

	for i in range(tile_positions.size()):
		var stack_direction = -1 if i < 12 else 1
		var tile_pos = tile_positions[i]
		# Check if the mouse is within the tile's radius
		var x_cond: bool = abs(tile_pos.x - mouse_pos.x) <= tile_width / 2
		var y_cond: bool = abs(tile_pos.y + tile_height / 2 * stack_direction - mouse_pos.y) <= tile_height / 2
		if  x_cond and y_cond :
			return i  # Return the ID of the tile (index in the array)

	return -1  # Return -1 if no tile is found

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		var tile_id: int = get_tile_id_from_mouse(event.position)
		if tile_id == -1:
			return
		if tile_id in moves:
			play_move(tile_id)
		else:
			update_selection(tile_id)


func update_selection(tile_id: int) -> void:
	clear_selection()
	select_checkers(tile_id)
	moves = find_possible_moves_v2(tile_id, roll_values)
	update_possible_moves(moves)

	
func play_move(to: int) -> void:
	used_dice.emit(moves[to][1])
	board_state = moves[to][0]
	roll_values = moves[to][2]
	clear_selection()
	update_graphics()

func clear_selection() -> void:
	for checker in selected_checkers:
		checker.stop_glow()
	selected_checkers.clear()
	
	for light in light_effects:
		light.queue_free()
	light_effects.clear()
	
	moves.clear()
	
func select_checkers(tile_id: int) -> void:
	for checker in checkers:
		if checker.get_id() == tile_id:
			checker.start_glow()
			selected_checkers.push_back(checker)
			

# Function to find possible moves from a given tile_id based on two dice rolls
#func find_possible_moves(tile_id: int, die1: int, die2: int) -> Dictionary:
	#var possible_moves: Dictionary = {}
#
	## Get the color of the checker on the current tile
	#var checker_count: int = board_state[tile_id]
#
	#if checker_count == 0:
		## No checker on the tile, so no moves possible.
		#return possible_moves
#
	#var dice_sum = die1 + die2
	## If doubles, repeat the roll 4 times
	#var is_double: bool = die1 == die2
#
	#if not is_double:
		#var d1_valid: bool = is_move_valid(tile_id, die1)
		#var d2_valid: bool = is_move_valid(tile_id, die2)
		#if d1_valid:
			#add_move(possible_moves,board_state, tile_id, [die1])
		#if d2_valid:
			#add_move(possible_moves,board_state, tile_id, [die2])
		### we need to check for the existence of a path
		#if (d1_valid or d2_valid) and is_move_valid(tile_id, dice_sum):
			#add_move(possible_moves,board_state, tile_id, [die1, die2])
	#
	## Handle the case where dice are doubles
	#else:
		#var dice_used: Array = []
		#for i in range(1, 5):
			## if any move is not valid, then the next one
			## wont be since the previous is required
			#if not is_move_valid(tile_id, die1 * i):
				#break
			#dice_used.push_back(die1)
			#add_move(possible_moves, board_state, tile_id, dice_used.duplicate())
			#
	#return possible_moves

func find_possible_moves_v2(tile_id: int, rolls: Array) -> Dictionary:
	assert (not roll_values.has(0))
	var possible_moves: Dictionary = {}
	var rolls_copy: Array = rolls.duplicate()
	recursive_move_search(tile_id, 0, possible_moves, rolls_copy, [], [])
	return possible_moves
	
func recursive_move_search(origin: int, current: int, possible_moves: Dictionary, 
	rolls: Array, remaining_rolls: Array, used_rolls: Array) -> void:
	if rolls.is_empty():
		if not used_rolls.is_empty():
			add_move(possible_moves, board_state, origin, 
			used_rolls.duplicate(), remaining_rolls.duplicate())
		return
		
	for i in range(rolls.size()):
		var roll: int = rolls[i]
		var new_rolls: Array = rolls.duplicate()
		new_rolls.pop_at(i)
		var new_remaining_rolls = remaining_rolls.duplicate()
		new_remaining_rolls.push_back(roll)
		
		# Skip the move
		recursive_move_search(origin, current, possible_moves, new_rolls, 
		new_remaining_rolls, used_rolls)
		
		# Or add it
		if is_move_valid(origin, roll + current):
			var new_used_rolls = used_rolls.duplicate()
			new_used_rolls.push_back(roll)
			recursive_move_search(origin, current + roll, possible_moves, 
			new_rolls, remaining_rolls, new_used_rolls)
	
func is_move_valid(from: int, step: int) -> bool:
	var checker_count = board_state[from]
	var move_direction = 1 if checker_count > 0 else -1  # White moves forward (+1), black moves backward (-1)
	var target_tile = from + step * move_direction
	
	# Ensure the target tile is within the board boundaries (0 to 23)
	if target_tile < 0 or target_tile > 23:
		return false
		
	var target_checker_count = board_state[target_tile]
	
	# Check if the target tile is a valid move
	# White can move to empty spaces or to a single black checker, 
	# Black can move to empty spaces or to a single white checker
	return (checker_count > 0 and target_checker_count >= -1) or (checker_count < 0 and target_checker_count <= 1)
	
func update_possible_moves(moves: Dictionary) -> void:
	var tile_positions: Array = get_tile_positions()
	for i: int in moves.keys():
		var light: Sprite2D = light_scene.instantiate()
		light.position = tile_positions[i]
		if i >= 12:
			light.rotation = PI
		add_child(light)
		light_effects.push_back(light)


func _on_dice_set_dice_result(rolls: Array) -> void:
	clear_selection()
	roll_values = rolls.duplicate()

func add_move(possible_moves: Dictionary, board: Array, from: int, 
	steps: Array, remaining_rolls: Array) -> void:
	var step: int = steps.reduce(func(accum, number): return accum + number, 0)
	var checker_count = board_state[from]
	var move_direction = 1 if checker_count > 0 else -1  # White moves forward (+1), black moves backward (-1)
	var target_tile = from + step * move_direction
	var new_board: Array = compute_move(board, from, target_tile) 
	possible_moves[target_tile] = [new_board, steps, remaining_rolls]

# this functions assumes the move is valid
func compute_move(board: Array, from: int, to: int) -> Array:
	var checker_count = board_state[from]
	var new_board: Array = board.duplicate()
	var color_direction = 1 if checker_count > 0 else -1
	
	# leave square
	new_board[from] -= color_direction
	# if there is an enemy checker, eat it
	if sign(checker_count) == -sign(board_state[to]):
		new_board[to] = color_direction
	else:
		new_board[to] += color_direction
		
	return new_board
