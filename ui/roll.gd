extends TextureButton

@export var cannot_pass_color: Color
@export var can_pass_color: Color

var can_pass: bool = false

# it seems that since it can be called very early the
# can_pass signal must be registered in _enter_tree and _ready
func _enter_tree():
	SignalBus.can_pass.connect(_on_can_pass)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_pressed() -> void:
	if can_pass:
		SignalBus.new_turn.emit()

func _on_can_pass(can_pass: bool) -> void:
	self.can_pass = can_pass
	if can_pass:
		modulate = can_pass_color
	else:
		modulate = cannot_pass_color
