extends Node

signal undo()
signal played_move(move: Move)
signal dice_result(results: Array[int])
signal new_turn()
signal can_pass(can_pass: bool)
signal start_game()
signal player_won(winner_is_black: bool)
signal set_play_mode(is_vs_ai: bool)
signal open_menu()
signal menu_pressed()
signal set_starting_player(is_starting_player_black: bool)
