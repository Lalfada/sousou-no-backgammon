extends Node2D
class_name Board

signal can_checker_leave(is_black: bool, can_leave: bool)

@export var black_bear_off: BearOff
@export var white_bear_off: BearOff
# we'll assume the ai plays black
@export var is_vs_ai: bool
@export var checker_move_duration: float = 1.0

#@onready var tile_positions: Array[Vector2] = get_tile_positions()
@onready var ai: BackgammonAi = $Ai
@onready var checker_manager: CheckerManager = $CheckerManager
@onready var game_logic: GameLogic = $GameLogic

var board_state: Array[int] = []
var undo_board_state: Array[int] = []
var roll_values: Array[int] = [1, 1]
var original_roll_values: Array[int]
# store move from a tile to another tile
# value at index i in all moves from tile i
var all_moves: Array[Dictionary]
# this is one of the value of all_moves
# it represents the moves presented to the player
var moves: Dictionary = {}
var is_blacks_turn: bool = false
var is_interactable: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	board_state = Utils.default_board.duplicate()
	
	undo_board_state = board_state.duplicate()
	original_roll_values = roll_values.duplicate()
	
	SignalBus.dice_result.connect(_on_dice_result)
	SignalBus.new_turn.connect(_on_new_turn)
	SignalBus.start_game.connect(_on_start_game)
	SignalBus.set_play_mode.connect(_on_set_play_mode)
	SignalBus.set_starting_player.connect(_on_set_starting_player)

	
	update_all()


func update_selection(tile_id: int) -> void:
	checker_manager.clear_selection()
	
	if not can_select_tile(tile_id):
		moves = {}
		checker_manager.update_possible_moves(moves)
		return
	
	checker_manager.select_checkers(tile_id)
	moves = all_moves[tile_id].duplicate(true)
	checker_manager.update_possible_moves(moves)

func can_select_tile(tile_id: int) -> bool:		
	if tile_id == Utils.BLACK_BEAR_OFF or tile_id == Utils.WHITE_BEAR_OFF:
		return false
	
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
	
func play_move(move: Move) -> void:
	
	SignalBus.played_move.emit(move)
	
	if move.win_state != 0:
		SignalBus.player_won.emit(is_blacks_turn)
		is_interactable = false
	board_state = move.board
	roll_values = move.remaining_rolls
	
	if is_vs_ai and is_blacks_turn:
		await checker_manager.animate_checker(move)
	
	update_all()
	
	if is_vs_ai and is_blacks_turn:
		play_ai_move()
			

func update_move_list() -> void:
	var all_possible_moves: Array[Dictionary] = []
	var move_counter: int = 0
	
	for i in range(Utils.BOARD_MANAGED_TILES):
		if can_select_tile(i):
			all_possible_moves.push_back(find_possible_moves(i, roll_values))
			move_counter += all_possible_moves[i].size()
		else:
			all_possible_moves.push_back({})
		
	SignalBus.can_pass.emit(move_counter == 0)
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
		if is_move_valid(origin, roll + current, used_rolls):
			var new_used_rolls = used_rolls.duplicate()
			new_used_rolls.push_back(roll)
			recursive_move_search(origin, current + roll, possible_moves, 
			new_rolls, remaining_rolls, new_used_rolls)

# TODO fix bug where checker from the bar can move twice
# even if other checker is on the bar
func is_move_valid(from: int, step: int,  used_rolls: Array[int]) -> bool:
	var checker_count = board_state[from]
	var move_direction = 1 if checker_count > 0 else -1  # White moves forward (+1), black moves backward (-1)
	var target_tile = get_actual_position(from) + step * move_direction
	
	# If the the checker is trying to reach the bear off
	# the check its allowed to do so 
	if target_tile < 0 or target_tile > 23:
		if target_tile > 23 and checker_count > 0 \
		and white_can_leave() and white_correct_leave(from, step):
			return true
		elif target_tile < 0 and checker_count < 0 \
		and black_can_leave() and black_correct_leave(from, step):
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
	
# the idea of correct leave is that you may only use a die
# with a score bigger than you need if there are no checker
# on which it would be better spent
func white_correct_leave(from: int, step: int) -> bool:
	var distance: int = 24 - from
	var max_dist: int = 0
	for i in range(18, 24):
		if board_state[i] > 0:
			max_dist = 24 - i
			break
	return max_dist == distance or step == distance
	
func black_correct_leave(from: int, step: int) -> bool:
	var distance: int = from + 1
	var max_dist: int = 6
	for i in range(0, 6):
		# j is to go from left to right, so we ideed find the max
		# and not the min
		var j: int = 5 - i
		if board_state[j] < 0:
			max_dist = j + 1
			break
	return max_dist == distance or step == distance


func _on_dice_result(rolls: Array[int]) -> void:
	undo_board_state = board_state.duplicate()
	roll_values = rolls.duplicate()
	original_roll_values = roll_values.duplicate()
	
	update_move_list()
	checker_manager.clear_selection()
	
	if is_vs_ai and is_blacks_turn:
		play_ai_move()
	
	
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
	var win_state: int = compute_win_state(new_board)
	
	assert(leaving_checkers)
	assert(new_board)
	
	possible_moves[target_tile] = Move.new(new_board, steps, from, target_tile, win_state,
		remaining_rolls, leaving_checkers)
		
func compute_win_state(board: Array[int]) -> int:
	var white_wins: bool = true
	for i in range(24):
		if board[i] > 0:
			white_wins = false
			break
	if board[Utils.WHITE_BAR] > 0:
		white_wins = false
	if white_wins:
		return 1
		
	var black_wins: bool = true
	for i in range(24):
		if board[i] < 0:
			black_wins = false
			break	
	if board[Utils.BLACK_BAR] > 0:
		black_wins = false
	if black_wins:
		return -1
		
	return 0
	

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
#
#func get_stack_direction(tile_id: int) -> int:
	#return -1 if tile_id < 12 or tile_id == 24 else 1
	
func get_actual_position(tile_id: int) -> int:
	if tile_id < 24:
		return tile_id
	return -1 if tile_id == 24 else 24


func _clicked_on_bear_off(tile_id: int) -> void:
	checker_manager.clicked_on_tile(tile_id)

func _on_new_turn() -> void:
	is_blacks_turn = not is_blacks_turn

func update_all() -> void:
	update_move_list()
	checker_manager.clear_selection()
	checker_manager.update_graphics()

func array_sum(arr: Array) -> int:
	return arr.reduce(func(accum, number): return accum + number, 0)
	
func is_receptive_to_input() -> bool:
	return is_interactable and (not is_vs_ai or not is_blacks_turn)



func play_ai_move() -> void:
	var move_to_play: Move = ai.choose_move()
	# if there are no legal move the ai returns null
	if move_to_play:
		play_move(move_to_play)
	else:
		SignalBus.new_turn.emit()

func _on_start_game() -> void:
	#board_state = Utils.default_board.duplicate()
	#board_state = Utils.endgame_board.duplicate()
	board_state = Utils.done_board.duplicate()
	# we want white to go first
	is_blacks_turn = false
	is_interactable = true
	# we're waiting to receive the rolls
	# in the meantime we don't wanna be able to play anithing
	roll_values = []
	original_roll_values = []
	
	update_all()

func _on_set_play_mode(is_vs_ai: bool):
	self.is_vs_ai = is_vs_ai

func _on_set_starting_player(is_starting_player_black: bool) -> void:
	is_blacks_turn = is_starting_player_black
