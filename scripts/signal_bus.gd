extends Node

signal undo()
signal played_move(move: Move)
signal dice_result(results: Array[int])
signal new_turn()
signal can_pass_update(can_pass: bool)
