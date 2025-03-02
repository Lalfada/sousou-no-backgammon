extends Node2D
class_name CheckerManager

# The values are for the most oart educated guesses
# They're remplaced by distance defined by markers in
# the _ready() function
# well, except for values that remain...
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

@onready var board: Board = get_parent()
@onready var tile_positions: Array[Vector2] = get_tile_positions()
var checkers: Array[Checker] = []
var light_effects: Array[Sprite2D] = []
var selected_checkers: Array[Checker] = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	VERTICAL_START = $Markers/TopMarker.position.y
	COLUMN_WIDTH = ($Markers/Column6Marker.position.x - $Markers/BotLeftMarker.position.x) / 5
	RIGHT_START = $Markers/Column7Marker.position.x
	LEFT_START = $Markers/BotLeftMarker.position.x
	BOTTOM_START = $Markers/BotLeftMarker.position.y
	TOP_START = $Markers/TopMarker.position.y
	COLUMN_HEIGHT = $Markers/BotLeftMarker.position.y - $Markers/HeightMarker.position.y
	BAR_HEIGHT = ($Markers/WhiteCaptured.position.y - $Markers/BlackCaptured.position.y) / 2


func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		var tile_id: int = get_tile_id_from_mouse(event.position)
		if tile_id == -1:
			return
		clicked_on_tile(tile_id)
		
func clicked_on_tile(tile_id: int) -> void:
	if not board.is_receptive_to_input():
		return
	
	if tile_id in board.moves:
		board.play_move(board.moves[tile_id])
	else:
		board.update_selection(tile_id)
		
func update_graphics() -> void:
	# Clear existing checker nodes to reset the board
	for checker in checkers:
		checker.queue_free()
	checkers.clear()
	
	for i in range(Utils.BOARD_MANAGED_TILES):
		var count: int = board.board_state[i]
		
		if count == 0:
			continue  # Skip empty tiles
		
		var is_white = count > 0
		count = abs(count)  # Get the absolute number of checkers on this tile
		
		for j in range(count):
			# Load the Checker scene
			var checker_instance = checker_scene.instantiate()
			checkers.push_back(checker_instance)
			
			# set checker id
			checker_instance.set_id(i, j)
			# Set the position of the checker
			checker_instance.position = compute_checker_position(i, j)

			# Set the color or property of the checker (white/black)
			if is_white:
				checker_instance.set_white()  # White color
			else:
				checker_instance.set_black() # Black color

			# Add the checker instance as a child of the board
			add_child(checker_instance)
			
func update_possible_moves(moves: Dictionary) -> void:
	for i: int in moves.keys():
		if i < 24:
			var light: Sprite2D = light_scene.instantiate()
			light.position = tile_positions[i]
			if i >= 12:
				light.rotation = PI
			add_child(light)
			light_effects.push_back(light)
		else:
			board.can_checker_leave.emit(i == Utils.BLACK_BEAR_OFF, true)
			
func clear_selection() -> void:
	for checker in selected_checkers:
		checker.stop_glow()
	selected_checkers.clear()
	
	for light in light_effects:
		light.queue_free()
	light_effects.clear()
	
	board.can_checker_leave.emit(false, false)
	board.can_checker_leave.emit(true, false)
	
	board.moves.clear()

func animate_checker(move: Move) -> void:
	var final_pos: Vector2 = compute_checker_position(move.to, 0)
	var checker_to_move: Checker
	
	for checker in checkers:
		if checker.tile_id == move.from:
			if checker_to_move == null \
				or checker_to_move.stack_id < checker.stack_id:
				checker_to_move = checker
	
	if checker_to_move:
		var tween: Tween = get_tree().create_tween()
		tween.tween_property(checker_to_move, "position", final_pos, 0.5)
		await tween.finished  # Wait for each move to finish before next
		
func compute_checker_position(tile_id: int, checker_number: int) -> Vector2:
	if tile_id == Utils.BLACK_BEAR_OFF:
		return board.black_bear_off.global_position
	if tile_id == Utils.WHITE_BEAR_OFF:
		return board.white_bear_off.global_position
	
	var stack_direction: int = get_stack_direction(tile_id)
	var stack_distance: int = CHECKER_SIZE if tile_id < 24 else COMPACT_CHECKER_SIZE

	var pos: Vector2 = tile_positions[tile_id] \
		+ Vector2(0, checker_number * stack_distance * stack_direction)  # Stack vertically
	return pos


func get_tile_id_from_mouse(mouse_pos: Vector2) -> int:
	# ensures that no matter the board size the input detection works fine
	mouse_pos = Vector2(mouse_pos.x / scale.x, mouse_pos.y / scale.y)
	# Define a radius for detecting clicks around tile positions
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

func get_stack_direction(tile_id: int) -> int:
	return -1 if tile_id < 12 or tile_id == 24 else 1
	
func get_tile_positions() -> Array[Vector2]:
	# Define the positions of each tile on the board
	# This is an example, customize it based on your board's layout
	var positions: Array[Vector2] = []
	for x in range(6):  # Bottom right
		positions.push_back(Vector2(RIGHT_START + COLUMN_WIDTH * (5 - x), BOTTOM_START))
	for x in range(6):  # Bottom left
		positions.push_back(Vector2(LEFT_START + COLUMN_WIDTH * (5 - x), BOTTOM_START))
	for x in range(6):  # Top left
		positions.push_back(Vector2(LEFT_START + COLUMN_WIDTH * x, TOP_START))
	for x in range(6):  # Top right
		positions.push_back(Vector2(RIGHT_START + COLUMN_WIDTH * x, TOP_START))
		
	positions.push_back($Markers/WhiteCaptured.position)
	positions.push_back($Markers/BlackCaptured.position)

	return positions
	
func select_checkers(tile_id: int) -> void:
	for checker in checkers:
		if checker.get_id() == tile_id:
			checker.start_glow()
			selected_checkers.push_back(checker)
