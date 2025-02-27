extends Node

const WHITE_BAR: int = 24
const BLACK_BAR: int = 25
const WHITE_BEAR_OFF: int = 26
const BLACK_BEAR_OFF: int = 27
# these are all the indexes handles by the board
const BOARD_MANAGED_TILES = BLACK_BAR + 1

# positive values are white checkers
# negative values are black checkers
# and zero means no checkers.
# index 24 is white's eaten pieces and 25 is black's
# index 26 is white's bear off and 27 is black's
const default_board: Array[int] = [
	2, 0, 0, 0, 0, -5,
	0, -3, 0, 0, 0, 5,
	-5, 0, 0, 0, 3, 0,
	5, 0, 0, 0, 0, -2,
	0, 0,
	0, 0
	]

# for debugging purposes
const endgame_board: Array[int] = [
	-2, -2, -1, -2, -3, -5,
	0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0,
	1, 4, 2, 1, 1, 2,
	0, 0,
	0, 0
	]
	
# for debugging purposes
const tough_board: Array[int] = [
	-2, -1, -1, -2, -3, -3,
	0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0,
	1, 4, 2, 1, 1, 2,
	4, 0,
	0, 0
	]
	
# for debugging purposes
const done_board: Array[int] = [
	0, 0, 0, 0, 0, -1,
	0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 1,
	0, 0,
	0, 0
	]
