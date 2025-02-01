extends CenterContainer
class_name ContainedChecker

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func set_white() -> void:
	$Checker.set_white()
	
func set_black() -> void:
	$Checker.set_black()
