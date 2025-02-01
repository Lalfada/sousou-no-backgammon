extends Node
class_name Move

var board: Array[int]
var steps: Array[int]
var remaining_rolls: Array[int]
var leaving_checkers: LeavingCheckers

func _init(board: Array[int], steps: Array[int], remaining_rolls: Array[int],
	leaving_checkers: LeavingCheckers):
	self.board = board
	self.steps = steps
	self.remaining_rolls = remaining_rolls
	self.leaving_checkers = leaving_checkers

func get_white_bear_off() -> int:
	return board[Utils.WHITE_BEAR_OFF]
	
func get_black_bear_off() -> int:
	return board[Utils.BLACK_BEAR_OFF]
