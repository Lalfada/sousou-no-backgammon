extends Node2D
class_name Board

signal can_checker_leave(is_black: bool, can_leave: bool)

# The values here are only educated guesses
# They're remplaced by distance defined by markers in
# the _ready() function
var SQUARE_NUMBER: int = 24
var COLUMN_WIDTH: int = 125
var LEFT_START: int = 70
var RIGHT_START: int = 850
var CHECKER_SIZE: int = 90
var COMPACT_CHECKER_SIZE: int = 30
var VERTICAL_START: int = 60
var BOTTOM_START: int = 1020
var TOP_START: int = 60
var COLUMN_HEIGHT: int = 400
var BAR_HEIGHT: int = 200

@export var checker_scene: PackedScene
@export var light_scene: PackedScene

var board_state: Array[int] = []
var undo_board_state: Array[int] = []
var checkers: Array[Checker] = []
var selected_checkers: Array[Checker] = []
var light_effects: Array[Sprite2D] = []
var roll_values: Array[int] = [1, 1]
var original_roll_values: Array[int]
# store move from a tile to another tile
# value at index i in all moves from tile i
var all_moves: Array[Dictionary]
# this is one of the value of all_moves
# it represents the moves presented to the player
var moves: Dictionary = {}
var is_blacks_turn: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#board_state = Utils.default_board.duplicate()
	#board_state = Utils.endgame_board.duplicate()
	board_state = Utils.tough_board.duplicate()
	
	undo_board_state = board_state.duplicate()
	original_roll_values = roll_values.duplicate()
	
	VERTICAL_START = $TopMarker.position.y
	COLUMN_WIDTH = ($Column6Marker.position.x - $BotLeftMarker.position.x) / 5
	RIGHT_START = $Column7Marker.position.x
	LEFT_START = $BotLeftMarker.position.x
	BOTTOM_START = $BotLeftMarker.position.y
	TOP_START = $TopMarker.position.y
	COLUMN_HEIGHT = $BotLeftMarker.position.y - $HeightMarker.position.y
	BAR_HEIGHT = ($WhiteCaptured.position.y - $BlackCaptured.position.y) / 2
	
	SignalBus.dice_result.connect(_on_dice_result)
	SignalBus.new_turn.connect(_on_new_turn)
	
	update_all()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
	
func update_graphics() -> void:
	# Clear existing checker nodes to reset the board
	for checker in checkers:
		checker.queue_free()
	checkers.clear()
	
	# Define tile positions based on the board array
	var tile_positions = get_tile_positions()  # A helper function to define tile positions
	
	for i in range(Utils.BOARD_MANAGED_TILES):
		var count: int = board_state[i]
		
		if count == 0:
			continue  # Skip empty tiles
		
		var is_white = count > 0
		count = abs(count)  # Get the absolute number of checkers on this tile
		
		for j in range(count):
			# Load the Checker scene
			var checker_instance = checker_scene.instantiate()
			checkers.push_back(checker_instance)
			
			# set checker id
			checker_instance.set_id(i)
			# Set the position of the checker
			var stack_direction: int = get_stack_direction(i)
			var stack_distance: int = CHECKER_SIZE if i < 24 else COMPACT_CHECKER_SIZE
			checker_instance.position = tile_positions[i] + Vector2(0, j * stack_distance * stack_direction)  # Stack vertically

			# Set the color or property of the checker (white/black)
			if is_white:
				checker_instance.set_white()  # White color
			else:
				checker_instance.set_black() # Black color

			# Add the checker instance as a child of the board
			add_child(checker_instance)

func get_tile_positions() -> Array:
	# Define the positions of each tile on the board
	# This is an example, customize it based on your board's layout
	var positions = []
	for x in range(6):  # Bottom right
		positions.push_back(Vector2(RIGHT_START + COLUMN_WIDTH * (5 - x), BOTTOM_START))
	for x in range(6):  # Bottom left
		positions.push_back(Vector2(LEFT_START + COLUMN_WIDTH * (5 - x), BOTTOM_START))
	for x in range(6):  # Top left
		positions.push_back(Vector2(LEFT_START + COLUMN_WIDTH * x, TOP_START))
	for x in range(6):  # Top right
		positions.push_back(Vector2(RIGHT_START + COLUMN_WIDTH * x, TOP_START))
		
	positions.push_back($WhiteCaptured.position)
	positions.push_back($BlackCaptured.position)

	return positions
	
func get_tile_id_from_mouse(mouse_pos: Vector2) -> int:
	# Define a radius for detecting clicks around tile positions
	var tile_positions: Array = get_tile_positions()
	var tile_width: int = COLUMN_WIDTH / 2 
	var tile_height: int = COLUMN_HEIGHT

	for i in range(tile_positions.size()):
		var actual_height: int = tile_height if i < 24 else BAR_HEIGHT
		var stack_direction: int = get_stack_direction(i)
		var tile_pos: Vector2 = tile_positions[i]
		# Check if the mouse is within the tile's radius
		var x_cond: bool = abs(tile_pos.x - mouse_pos.x) <= tile_width / 2
		var y_cond: bool = abs(tile_pos.y + actual_height / 2 * stack_direction - mouse_pos.y) <= actual_height / 2
		if  x_cond and y_cond :
			return i  # Return the ID of the tile (index in the array)

	return -1  # Return -1 if no tile is found

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		var tile_id: int = get_tile_id_from_mouse(event.position)
		if tile_id == -1:
			return
		clicked_on_tile(tile_id)

func clicked_on_tile(tile_id: int) -> void:
	if tile_id in moves:
		play_move(tile_id)
	else:
		update_selection(tile_id)

func update_selection(tile_id: int) -> void:
	clear_selection()
	
	if not can_select_tile(tile_id):
		moves = {}
		update_possible_moves(moves)
		return
	
	select_checkers(tile_id)
	moves = all_moves[tile_id].duplicate(true)
	update_possible_moves(moves)

func can_select_tile(tile_id: int) -> bool:
	var checker_count = board_state[tile_id]
	
	if checker_count == 0:
		return false
	
	var is_checker_black: bool = checker_count < 0
	if is_checker_black != is_blacks_turn:
		return false
		
	var color_bar: int = Utils.BLACK_BAR \
		if is_checker_black \
		else Utils.WHITE_BAR
		
	if board_state[color_bar] != 0 and tile_id != color_bar:
		return false
	
	return true
	
func play_move(to: int) -> void:
	var move: Move = moves[to]
	SignalBus.played_move.emit(move)
	board_state = move.board
	roll_values = move.remaining_rolls
	
	update_all()
	

func clear_selection() -> void:
	for checker in selected_checkers:
		checker.stop_glow()
	selected_checkers.clear()
	
	for light in light_effects:
		light.queue_free()
	light_effects.clear()
	
	can_checker_leave.emit(false, false)
	can_checker_leave.emit(true, false)
	
	moves.clear()
	
func select_checkers(tile_id: int) -> void:
	for checker in checkers:
		if checker.get_id() == tile_id:
			checker.start_glow()
			selected_checkers.push_back(checker)
			

func update_move_list() -> void:
	var all_possible_moves: Array[Dictionary] = []
	var move_counter: int = 0
	
	for i in range(Utils.BOARD_MANAGED_TILES):
		all_possible_moves.push_back(find_possible_moves(i, roll_values))
		move_counter += all_possible_moves[i].size()
		
	SignalBus.can_pass_update.emit(move_counter > 0)
	all_moves = all_possible_moves
	

func find_possible_moves(tile_id: int, rolls: Array[int]) -> Dictionary:
	assert (not roll_values.has(0))
	
	var possible_moves: Dictionary = {}
	var rolls_copy: Array = rolls.duplicate()
	
	recursive_move_search(tile_id, 0, possible_moves, rolls_copy, [], [])
	return possible_moves
	
func recursive_move_search(origin: int, current: int, possible_moves: Dictionary, 
	rolls: Array[int], remaining_rolls: Array[int], used_rolls: Array[int]) -> void:
	
	if rolls.is_empty():
		if not used_rolls.is_empty():
			add_move_sequence(possible_moves, board_state, origin, 
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
	var target_tile = get_actual_position(from) + step * move_direction
	
	# If the the checker is trying to reach the bear off
	# the check its allowed to do so 
	if target_tile < 0 or target_tile > 23:
		if target_tile > 23 and checker_count > 0 and white_can_leave():
			return true
		elif target_tile < 0 and checker_count < 0 and black_can_leave():
			return true
		else:
			return false
	var target_checker_count = board_state[target_tile]
	
	# Check if the target tile is a valid move
	# White can move to empty spaces or to a single black checker, 
	# Black can move to empty spaces or to a single white checker
	return (checker_count > 0 and target_checker_count >= -1) or (checker_count < 0 and target_checker_count <= 1)
	
	
func white_can_leave() -> bool:
	# check tiles before leaving area
	for i in range(0, 18):
		if board_state[i] > 0:
			return false
	
	# check the bar
	if board_state[24] > 0:
		return false
	return true
	
func black_can_leave() -> bool:
	# check tiles before leaving area
	for i in range(6, 24):
		if board_state[i] < 0:
			return false
	
	# check the bar
	if board_state[25] < 0:
		return false
	return true
	
func update_possible_moves(moves: Dictionary) -> void:
	var tile_positions: Array = get_tile_positions()
	for i: int in moves.keys():
		if i < 24:
			var light: Sprite2D = light_scene.instantiate()
			light.position = tile_positions[i]
			if i >= 12:
				light.rotation = PI
			add_child(light)
			light_effects.push_back(light)
		else:
			can_checker_leave.emit(i == Utils.BLACK_BEAR_OFF, true)


func _on_dice_result(rolls: Array[int]) -> void:
	undo_board_state = board_state.duplicate()
	roll_values = rolls.duplicate()
	original_roll_values = roll_values.duplicate()
	
	update_move_list()
	clear_selection()
	
	
func add_move_sequence(possible_moves: Dictionary, board: Array[int], from: int, 
	steps: Array[int], remaining_rolls: Array[int]) -> void:
	var step: int = steps.reduce(func(accum, number): return accum + number, 0)
	var checker_count = board_state[from]
	var move_direction = 1 if checker_count > 0 else -1  # White moves forward (+1), black moves backward (-1)
	var target_tile = get_actual_position(from) + step * move_direction
	
	if target_tile > 23:
		target_tile = Utils.WHITE_BEAR_OFF
	elif target_tile < 0:
		target_tile = Utils.BLACK_BEAR_OFF
		
	# we do this check to ensure that when reaching the bear off
	# we do not use more dice than neccesary
	# additionnaly, considering such cases means taking into account
	# case where checkers move in the bear off, which is not valid
	# and hence lead to bugs
	# additionnaly when reaching the bear off ensure that we use the
	# samllest die at our disposal
	if target_tile in possible_moves \
		and (possible_moves[target_tile].steps.size() < steps.size() \
		or (possible_moves[target_tile].steps.size() == steps.size() \
		and array_sum(possible_moves[target_tile].steps) < array_sum(steps))):
			return
	
	var restulting_state: Array = compute_move_sequence(board, from, steps) 
	var new_board: Array[int] = restulting_state[0]
	var leaving_checkers: LeavingCheckers = restulting_state[1]
	
	possible_moves[target_tile] = Move.new(new_board, steps, remaining_rolls, leaving_checkers)

# note that it assumes valid moves
func compute_move_sequence(board: Array[int], from: int, moves: Array[int]) -> Array:
	var current_board: Array[int] = board.duplicate()
	var leaving_checkers: LeavingCheckers = LeavingCheckers.new(0, 0)
	
	for move in moves:
		var checker_count: int = current_board[from]
		var move_direction: int = 1 if checker_count > 0 else -1
		var target_tile: int = get_actual_position(from) + move * move_direction
		
		var result: Array = compute_move(current_board, from, target_tile) 
		
		current_board = result[0]
		leaving_checkers.add(result[1])
		from = target_tile
		
	return [current_board, leaving_checkers]
	

# this functions assumes the move is valid
func compute_move(board: Array[int],
	from: int, to: int) -> Array:
	var checker_count: int = board[from]
	var new_board: Array[int] = board.duplicate()
	var color_direction: int = 1 if checker_count > 0 else -1
	
	# leave square
	new_board[from] -= color_direction
	
	# Check if the the checker is trying to reach the bear off
	# This is done assuming the checker is allowed to do so
	if to > 23:
		new_board[Utils.WHITE_BEAR_OFF] += 1
		return [new_board, LeavingCheckers.new(1, 0)]
	elif to < 0:
		new_board[Utils.BLACK_BEAR_OFF] += 1
		return [new_board, LeavingCheckers.new(0, 1)]
	
	# if there is an enemy checker, hit it
	# and send it to the bar
	if sign(checker_count) == -sign(board[to]):
		new_board[to] = color_direction
		var bar_id = 24 if board[to] == 1 else 25
		new_board[bar_id] += board[to]
	else:
		new_board[to] += color_direction

	return [new_board, LeavingCheckers.new(0, 0)]


func _on_undo_pressed() -> void:
	board_state = undo_board_state.duplicate()
	roll_values = original_roll_values.duplicate()
	
	update_all()

func get_stack_direction(tile_id: int) -> int:
	return -1 if tile_id < 12 or tile_id == 24 else 1
	
func get_actual_position(tile_id: int) -> int:
	if tile_id < 24:
		return tile_id
	return -1 if tile_id == 24 else 24


func _clicked_on_bear_off(tile_id: int) -> void:
	clicked_on_tile(tile_id)

func _on_new_turn() -> void:
	is_blacks_turn = not is_blacks_turn

func update_all() -> void:
	update_move_list()
	clear_selection()
	update_graphics()

func array_sum(arr: Array) -> int:
	return arr.reduce(func(accum, number): return accum + number, 0)
