extends Node
class_name LeavingCheckers

var whites: int
var blacks: int

func _init(whites: int, blacks: int):
	self.whites = whites
	self.blacks = blacks
	
func add(other: LeavingCheckers):
	whites += other.whites
	blacks += other.blacks
