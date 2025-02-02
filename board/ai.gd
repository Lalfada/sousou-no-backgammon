extends Node
class_name BackgammonAi

@onready var board: Board = get_parent()

func choose_move() -> Move:
	# the key difference from the update move list
	# function is the shape of all_possible_moves
	# which is now just a list instead of holding data about the
	# tile of origin
	# we use this structure to allow for easy random selection
	
	var all_possible_moves: Array[Move] = []
	for tile_id: int in range(Utils.BOARD_MANAGED_TILES):
		if board.can_select_tile(tile_id):
			var tile_moves: Dictionary = board.find_possible_moves(tile_id, board.roll_values)
			for move: Move in tile_moves.values():
				all_possible_moves.push_back(move)
	
	return all_possible_moves.pick_random()
	
