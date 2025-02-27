class_name Move

var board: Array[int]
var steps: Array[int]
var from: int
var to: int
var win_state: int  # 0 if not won, -1 if black won, 1 if white won
var remaining_rolls: Array[int]
var leaving_checkers: LeavingCheckers

func _init(board: Array[int], steps: Array[int], from: int, to: int, win_state: int, 
	remaining_rolls: Array[int],
	leaving_checkers: LeavingCheckers):
	self.board = board
	self.steps = steps
	self.from = from
	self.to = to
	self.win_state = win_state
	self.remaining_rolls = remaining_rolls
	self.leaving_checkers = leaving_checkers

func get_white_bear_off() -> int:
	return board[Utils.WHITE_BEAR_OFF]
	
func get_black_bear_off() -> int:
	return board[Utils.BLACK_BEAR_OFF]
